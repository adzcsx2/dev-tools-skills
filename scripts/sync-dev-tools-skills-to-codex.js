#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const homeDir = process.env.HOME || process.env.USERPROFILE;
if (!homeDir) {
  console.error("Cannot determine HOME or USERPROFILE.");
  process.exit(1);
}

const sourceRoot = process.argv[2] || process.cwd();
const outputRoot = process.argv[3] || path.join(homeDir, ".agents", "skills");
const promptRoot = process.argv[4] || path.join(homeDir, ".codex", "prompts");
const marker = ".codex-dev-tools-skills-wrapper";
const promptMarker = "<!-- codex-dev-tools-skills-generated -->";
const modelRouteManifestFile = path.join("manifests", "codex-model-routes.json");

function parseBooleanFlag(value, defaultValue) {
  if (value === undefined || value === null || value === "") {
    return defaultValue;
  }

  return !["0", "false", "no", "off"].includes(String(value).trim().toLowerCase());
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

function stripQuotes(value) {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function escapeYamlString(value) {
  return JSON.stringify(String(value));
}

function sanitizeDescription(value) {
  return String(value).replace(/[<>]/g, "").replace(/\s+/g, " ").trim();
}

function sanitizeRouteText(value) {
  return String(value || "").replace(/[<>]/g, "").replace(/\s+/g, " ").trim();
}

function parseFrontmatter(filePath) {
  const text = fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, "");
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/);
  if (!match) {
    fail(`Missing YAML frontmatter: ${filePath}`);
  }

  const yaml = match[1].split(/\r?\n/);
  const frontmatter = {};

  for (const line of yaml) {
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (match) {
      frontmatter[match[1]] = stripQuotes(match[2]);
    }
  }

  if (!frontmatter.name) {
    fail(`Missing name in frontmatter: ${filePath}`);
  }
  if (!frontmatter.description) {
    fail(`Missing description in frontmatter: ${filePath}`);
  }

  return frontmatter;
}

function toCodexSkillName(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
}

function listSourceSkills(root) {
  const skillsDir = path.join(root, "skills");
  if (!fs.existsSync(skillsDir)) {
    fail(`No skills directory found: ${skillsDir}`);
  }

  return fs
    .readdirSync(skillsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => {
      const dir = path.join(skillsDir, entry.name);
      const skillPath = path.join(dir, "SKILL.md");
      return fs.existsSync(skillPath) ? { dir, skillPath } : null;
    })
    .filter(Boolean)
    .sort((a, b) => a.skillPath.localeCompare(b.skillPath));
}

function normalizeModelRoute(rawRoute) {
  if (!rawRoute || typeof rawRoute !== "object" || Array.isArray(rawRoute)) {
    return null;
  }

  const preferredModel = sanitizeRouteText(rawRoute.preferred_model || rawRoute.preferredModel);
  const tier = sanitizeRouteText(rawRoute.tier);
  const reason = sanitizeRouteText(rawRoute.reason);
  const escalation = sanitizeRouteText(rawRoute.escalation);

  if (!preferredModel && !tier && !reason && !escalation) {
    return null;
  }

  return {
    preferredModel,
    tier,
    reason,
    escalation,
  };
}

function loadCodexModelRoutes(root) {
  const routePath = path.join(root, modelRouteManifestFile);
  if (!fs.existsSync(routePath)) {
    return {};
  }

  const parsed = JSON.parse(fs.readFileSync(routePath, "utf8"));
  const rawRoutes = parsed && typeof parsed === "object" && !Array.isArray(parsed)
    ? (parsed.routes || parsed)
    : {};
  const routes = {};

  for (const [skillName, rawRoute] of Object.entries(rawRoutes)) {
    const route = normalizeModelRoute(rawRoute);
    if (route) {
      routes[skillName] = route;
    }
  }

  return routes;
}

function buildModelRouteSection(modelRoute) {
  if (!modelRoute) {
    return "";
  }

  const lines = [
    "## Codex Model Route",
    "",
  ];

  if (modelRoute.preferredModel) {
    lines.push(`- Preferred model: \`${modelRoute.preferredModel}\``);
  }
  if (modelRoute.tier) {
    lines.push(`- Route tier: \`${modelRoute.tier}\``);
  }
  if (modelRoute.reason) {
    lines.push(`- Reason: ${modelRoute.reason}`);
  }
  if (modelRoute.escalation) {
    lines.push(`- Escalate when: ${modelRoute.escalation}`);
  }

  lines.push(
    "",
    "Use this route when the runtime supports model selection. If model",
    "selection is not available, treat it as operator guidance for whether this",
    "workflow needs high-reasoning execution.",
    "",
  );

  return `${lines.join("\n")}\n`;
}

function buildWrapper({ sourceDir, sourceSkillPath, originalName, codexName, description, modelRoute }) {
  const invocation = originalName.includes(":") ? `/${originalName}` : originalName;
  const safeDescription = sanitizeDescription(description);
  const modelRouteSection = buildModelRouteSection(modelRoute);

  return `---
name: ${codexName}
description: ${escapeYamlString(
    `Codex bridge for legacy Claude skill ${invocation}. ${safeDescription}`,
  )}
---

# Legacy Claude Skill Bridge

This is a Codex-compatible wrapper for the legacy Claude skill \`${originalName}\`.

When this skill is invoked, read the source skill completely before acting:

- Source skill: \`${sourceSkillPath}\`
- Source directory: \`${sourceDir}\`
- Original command: \`${invocation}\`
- Codex skill name: \`$${codexName}\`

Apply the source skill's body instructions. Treat unsupported Claude/Copilot
frontmatter fields such as \`argument-hint\`, \`applyTo\`, \`dependencies\`,
and \`origin\` as metadata rather than Codex skill frontmatter.

Resolve all relative paths, references, scripts, and assets from the source
directory above. If the source skill mentions Claude-only tools or slash-command
behavior, map the intent to available Codex capabilities and explain any
material difference to the user.

${modelRouteSection}User invocation mapping:

- Claude-style command text: \`${invocation}\`
- Codex explicit skill mention: \`$${codexName}\`
- Codex skill picker: \`/skills\` then choose \`${codexName}\`
`;
}

function buildPrompt({ originalName, codexName, description }) {
  const invocation = originalName.includes(":") ? `/${originalName}` : originalName;
  const safeDescription = sanitizeDescription(description);

  return `---
description: ${escapeYamlString(`Use ${invocation} through Codex skill $${codexName}. ${safeDescription}`)}
argument-hint: "[args]"
---

${promptMarker}

Use $$${codexName} for this request.

Original legacy command: \`${invocation}\`
Arguments: $ARGUMENTS
`;
}

function writeFileNoBom(filePath, content) {
  fs.writeFileSync(filePath, content, { encoding: "utf8" });
}

function main() {
  const syncPrompts = parseBooleanFlag(process.env.DEV_TOOLS_SYNC_CODEX_PROMPTS, false);
  const sourceSkills = listSourceSkills(sourceRoot);
  fs.mkdirSync(outputRoot, { recursive: true });
  if (syncPrompts) {
    fs.mkdirSync(promptRoot, { recursive: true });
  }

  const expected = new Set();
  const expectedPrompts = new Set();
  const created = [];
  const prompts = [];
  const modelRoutes = loadCodexModelRoutes(sourceRoot);

  for (const source of sourceSkills) {
    const frontmatter = parseFrontmatter(source.skillPath);
    const codexName = toCodexSkillName(frontmatter.name);
    if (!codexName) {
      fail(`Could not derive Codex skill name from ${frontmatter.name}`);
    }

    const outDir = path.join(outputRoot, codexName);
    expected.add(outDir);
    fs.mkdirSync(outDir, { recursive: true });
    writeFileNoBom(path.join(outDir, marker), source.skillPath + "\n");
    writeFileNoBom(
      path.join(outDir, "SKILL.md"),
      buildWrapper({
        sourceDir: source.dir,
        sourceSkillPath: source.skillPath,
        originalName: frontmatter.name,
        codexName,
        description: frontmatter.description,
        modelRoute: modelRoutes[codexName],
      }),
    );

    created.push(`${codexName} -> ${frontmatter.name}`);

    if (syncPrompts) {
      const promptPath = path.join(promptRoot, `${codexName}.md`);
      expectedPrompts.add(promptPath);
      writeFileNoBom(
        promptPath,
        buildPrompt({
          originalName: frontmatter.name,
          codexName,
          description: frontmatter.description,
        }),
      );
      prompts.push(`/prompts:${codexName} -> ${frontmatter.name}`);
    }
  }

  for (const entry of fs.readdirSync(outputRoot, { withFileTypes: true })) {
    if (!entry.isDirectory()) {
      continue;
    }
    const outDir = path.join(outputRoot, entry.name);
    const markerPath = path.join(outDir, marker);
    if (fs.existsSync(markerPath) && !expected.has(outDir)) {
      fs.rmSync(outDir, { recursive: true, force: true });
    }
  }

  if (fs.existsSync(promptRoot)) {
    for (const entry of fs.readdirSync(promptRoot, { withFileTypes: true })) {
      if (!entry.isFile() || !entry.name.endsWith(".md")) {
        continue;
      }
      const promptPath = path.join(promptRoot, entry.name);
      const content = fs.readFileSync(promptPath, "utf8");
      if (content.includes(promptMarker) && !expectedPrompts.has(promptPath)) {
        fs.rmSync(promptPath, { force: true });
      }
    }
  }

  console.log(`Synced ${created.length} Codex skill wrapper(s) to ${outputRoot}`);
  for (const line of created) {
    console.log(`- ${line}`);
  }
  if (syncPrompts) {
    console.log(`Synced ${prompts.length} Codex prompt alias(es) to ${promptRoot}`);
    for (const line of prompts) {
      console.log(`- ${line}`);
    }
  } else {
    console.log(`Codex prompt alias sync disabled; removed generated prompt aliases from ${promptRoot}`);
  }
}

main();
