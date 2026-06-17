#!/usr/bin/env node

const fs = require("fs");
const os = require("os");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const snapshotRoot = path.join(repoRoot, "codex-sync", "snapshot");
const manifestPath = path.join(snapshotRoot, "manifest.json");
const codexSnapshotRoot = path.join(snapshotRoot, "codex");
const platform = process.platform;
const homeDir = os.homedir();
const codexDir = process.env.CODEX_DIR || path.join(homeDir, ".codex");
const agentsDir = process.env.AGENTS_DIR || path.join(homeDir, ".agents");
const homePlaceholder = "__CODEX_SYNC_HOME__";

const mode = process.argv[2];

function fail(message) {
  console.error(`[ERROR] ${message}`);
  process.exit(1);
}

function info(message) {
  console.log(`[INFO] ${message}`);
}

function ok(message) {
  console.log(`[OK] ${message}`);
}

function exists(filePath) {
  return fs.existsSync(filePath);
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function removeIfExists(targetPath) {
  if (exists(targetPath)) {
    fs.rmSync(targetPath, { recursive: true, force: true });
  }
}

function readText(filePath) {
  return fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, "");
}

function writeText(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content, { encoding: "utf8" });
}

function copyFile(source, target) {
  ensureDir(path.dirname(target));
  fs.copyFileSync(source, target);
}

function isTextFile(filePath) {
  const textExtensions = new Set([
    ".conf",
    ".env",
    ".ini",
    ".js",
    ".json",
    ".md",
    ".ps1",
    ".py",
    ".sh",
    ".toml",
    ".ts",
    ".txt",
    ".yaml",
    ".yml",
  ]);
  const basename = path.basename(filePath).toLowerCase();
  return textExtensions.has(path.extname(filePath).toLowerCase()) ||
    basename === "license" ||
    basename === "notice";
}

function toPortableText(content) {
  return content.split(homeDir).join(homePlaceholder);
}

function fromPortableText(content) {
  return content.split(homePlaceholder).join(homeDir);
}

function copySnapshotFile(source, target, manifest, manifestPathLabel) {
  if (isTextFile(source)) {
    const content = readText(source);
    const sensitiveLine = findSensitiveLine(content);
    if (sensitiveLine) {
      manifest.skipped.push(`${manifestPathLabel}:sensitive:${sensitiveLine}`);
      return false;
    }
    writeText(target, toPortableText(content));
    return true;
  }

  copyFile(source, target);
  return true;
}

function applyPortableSnapshotFile(source, target) {
  if (isTextFile(source)) {
    writeText(target, fromPortableText(readText(source)));
    return;
  }

  copyFile(source, target);
}

function listFiles(root) {
  if (!exists(root)) {
    return [];
  }

  const result = [];
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (entry.isFile()) {
        result.push(fullPath);
      }
    }
  };
  walk(root);
  return result.sort();
}

function relativePosix(from, filePath) {
  return path.relative(from, filePath).split(path.sep).join("/");
}

function isInside(child, parent) {
  const relative = path.relative(parent, child);
  return relative === "" || (!relative.startsWith("..") && !path.isAbsolute(relative));
}

function assertInside(child, parent) {
  if (!isInside(child, parent)) {
    fail(`Refusing to operate outside ${parent}: ${child}`);
  }
}

function isGeneratedSkillDir(skillDir) {
  if (exists(path.join(skillDir, ".codex-dev-tools-skills-wrapper"))) {
    return true;
  }

  const skillFile = path.join(skillDir, "SKILL.md");
  if (!exists(skillFile)) {
    return false;
  }

  const content = readText(skillFile).slice(0, 1000);
  return content.includes("Codex bridge for legacy Claude");
}

function isPlaceholderSecretValue(value) {
  const normalized = value.trim().replace(/^["']|["']$/g, "");
  return normalized === "" ||
    normalized === "null" ||
    normalized === "string" ||
    normalized === "undefined" ||
    normalized.includes("<") ||
    normalized.includes("xxx") ||
    normalized.includes("your-") ||
    normalized.includes("example") ||
    normalized.startsWith("$") ||
    normalized.startsWith("${") ||
    normalized.startsWith("%");
}

function isSensitiveKey(key) {
  return /(?:token|secret|password|api[_-]?key|authorization|bearer|client[_-]?secret|access[_-]?key|refresh[_-]?token|private[_-]?key|auth[_-]?token)/i.test(key);
}

function isSensitiveAssignment(line) {
  const keyMatch = line.match(/^\s*(?:export\s+)?["']?([A-Za-z0-9_.-]+)["']?\s*([:=])\s*(.+?)\s*,?\s*$/);
  if (!keyMatch) {
    return false;
  }
  const operator = keyMatch[2];
  const value = keyMatch[3].trim();
  const isQuotedLiteral = /^["'][^"']+["']$/.test(value);
  const isEnvLiteral = operator === "=" && /^[A-Za-z0-9._:/+=@-]+$/.test(value);
  return isSensitiveKey(keyMatch[1]) &&
    (isQuotedLiteral || isEnvLiteral || containsSensitiveLiteral(value)) &&
    !isPlaceholderSecretValue(value);
}

function containsSensitiveLiteral(line) {
  return /(?:Bearer\s+[A-Za-z0-9._-]+|sk-[A-Za-z0-9_-]{10,}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,})/.test(line);
}

function containsSensitiveOption(line) {
  const optionMatch = line.match(/--(?:token|secret|password|api-key|client-secret|access-key|refresh-token|private-key)\s+([^\s\\]+)/i);
  return Boolean(optionMatch && !isPlaceholderSecretValue(optionMatch[1]));
}

function sensitiveLabel(line) {
  const keyMatch = line.match(/^\s*(?:export\s+)?["']?([A-Za-z0-9_.-]+)["']?\s*[:=]/);
  if (keyMatch) {
    return keyMatch[1];
  }
  const optionMatch = line.match(/--((?:token|secret|password|api-key|client-secret|access-key|refresh-token|private-key))/i);
  if (optionMatch) {
    return optionMatch[1];
  }
  return "sensitive_literal";
}

function findSensitiveLine(content) {
  const lines = content.split(/\r?\n/);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    if (isSensitiveAssignment(line) || containsSensitiveLiteral(line) || containsSensitiveOption(line)) {
      return `line_${index + 1}_${sensitiveLabel(line)}`;
    }
  }
  return "";
}

function shouldSkipConfigSection(sectionName) {
  const excludedSectionPrefixes = [
    "hooks.state",
    "marketplaces",
    "projects.",
    "mcp_servers.node_repl",
  ];
  if (excludedSectionPrefixes.some((prefix) => (
    sectionName === prefix ||
    sectionName.startsWith(`${prefix}.`) ||
    sectionName.startsWith(prefix)
  ))) {
    return true;
  }

  return /^mcp_servers\.[^.]+\.(env|headers)$/i.test(sectionName);
}

function sanitizeCodexConfig(content, manifest) {
  const excludedTopLevelKeys = new Set(["notify"]);
  const output = [];
  let currentSection = "";
  let skippingSection = false;

  for (const line of content.split(/\r?\n/)) {
    const sectionMatch = line.match(/^\s*\[([^\]]+)\]\s*$/);
    if (sectionMatch) {
      currentSection = sectionMatch[1].trim();
      skippingSection = shouldSkipConfigSection(currentSection);
      if (skippingSection) {
        manifest.skipped.push(`codex/config.${platform}.toml:[${currentSection}]`);
      }
      if (!skippingSection) {
        output.push(line);
      }
      continue;
    }

    if (skippingSection) {
      continue;
    }

    if (!currentSection) {
      const keyMatch = line.match(/^\s*([A-Za-z0-9_-]+)\s*=/);
      if (keyMatch && excludedTopLevelKeys.has(keyMatch[1])) {
        manifest.skipped.push(`codex/config.${platform}.toml:${keyMatch[1]}`);
        continue;
      }
    }

    if (isSensitiveAssignment(line) || containsSensitiveLiteral(line)) {
      const keyMatch = line.match(/^\s*([A-Za-z0-9_.-]+)\s*=/);
      const label = keyMatch ? keyMatch[1] : "sensitive_literal";
      manifest.skipped.push(`codex/config.${platform}.toml:${currentSection ? `${currentSection}.` : ""}${label}`);
      continue;
    }

    output.push(line);
  }

  return `${toPortableText(output.join("\n").replace(/\n{3,}/g, "\n\n").trim())}\n`;
}

function shouldSkipCodexFile(relativePath) {
  const blocked = [
    "auth.json",
    "installation_id",
    "models_cache.json",
    ".codex-global-state.json",
    ".codex-global-state.json.bak",
  ];
  if (blocked.includes(relativePath)) {
    return true;
  }

  return [
    ".tmp/",
    "cache/",
    "plugins/cache/",
    "sessions/",
    "shell_snapshots/",
    "tmp/",
    "sqlite/",
    "process_manager/",
    "vendor_imports/",
  ].some((prefix) => relativePath.startsWith(prefix)) ||
    /\.(sqlite|sqlite-shm|sqlite-wal|db|db-shm|db-wal)$/i.test(relativePath);
}

function copyCodexEntry(relativePath, manifest) {
  const source = path.join(codexDir, ...relativePath.split("/"));
  if (!exists(source)) {
    return;
  }

  if (fs.statSync(source).isDirectory()) {
    for (const file of listFiles(source)) {
      const fileRelative = `${relativePath}/${relativePosix(source, file)}`;
      if (shouldSkipCodexFile(fileRelative)) {
        manifest.skipped.push(`codex/${fileRelative}`);
        continue;
      }
      const target = path.join(codexSnapshotRoot, ...fileRelative.split("/"));
      const manifestPathLabel = `codex/${fileRelative}`;
      if (copySnapshotFile(file, target, manifest, manifestPathLabel)) {
        manifest.files.push(manifestPathLabel);
      }
    }
    return;
  }

  if (shouldSkipCodexFile(relativePath)) {
    manifest.skipped.push(`codex/${relativePath}`);
    return;
  }

  const target = path.join(codexSnapshotRoot, ...relativePath.split("/"));
  const manifestPathLabel = `codex/${relativePath}`;
  if (copySnapshotFile(source, target, manifest, manifestPathLabel)) {
    manifest.files.push(manifestPathLabel);
  }
}

function copySanitizedConfig(manifest) {
  const source = path.join(codexDir, "config.toml");
  if (!exists(source)) {
    return;
  }

  const sanitized = sanitizeCodexConfig(readText(source), manifest);
  const platformPath = path.join(codexSnapshotRoot, `config.${platform}.toml`);
  writeText(platformPath, sanitized);
  manifest.files.push(`codex/config.${platform}.toml`);
}

function resetCurrentSnapshotContent() {
  ensureDir(snapshotRoot);
  removeIfExists(path.join(snapshotRoot, "agents"));
  removeIfExists(manifestPath);

  if (!exists(codexSnapshotRoot)) {
    return;
  }

  for (const entry of fs.readdirSync(codexSnapshotRoot, { withFileTypes: true })) {
    const fullPath = path.join(codexSnapshotRoot, entry.name);
    if (entry.isFile() && /^config\.(darwin|win32|linux)\.toml$/.test(entry.name)) {
      if (entry.name === `config.${platform}.toml`) {
        removeIfExists(fullPath);
      }
      continue;
    }
    removeIfExists(fullPath);
  }
}

function refreshManifestFiles(manifest) {
  manifest.files = listFiles(snapshotRoot)
    .filter((file) => file !== manifestPath)
    .map((file) => relativePosix(snapshotRoot, file))
    .sort();
}

function pushSnapshot() {
  resetCurrentSnapshotContent();

  const manifest = {
    schema: 1,
    generatedAt: new Date().toISOString(),
    sourcePlatform: platform,
    files: [],
    skipped: [],
    notes: [
      "Codex auth, sessions, logs, sqlite databases, caches, plugin caches, project trust state, and hook trust hashes are intentionally excluded.",
      "config.toml is saved as a sanitized platform-specific file such as config.darwin.toml or config.win32.toml.",
      "A push updates only the current platform config and preserves other platform config files already in the snapshot.",
    ],
  };

  copySanitizedConfig(manifest);

  for (const relativePath of [
    "AGENTS.md",
    "hooks.json",
    "browser/config.toml",
    "computer-use/config.json",
    "hooks",
    "prompts",
  ]) {
    copyCodexEntry(relativePath, manifest);
  }

  const skillsRoot = path.join(agentsDir, "skills");
  if (exists(skillsRoot)) {
    for (const entry of fs.readdirSync(skillsRoot, { withFileTypes: true })) {
      if (!entry.isDirectory()) {
        continue;
      }
      const skillDir = path.join(skillsRoot, entry.name);
      if (isGeneratedSkillDir(skillDir)) {
        manifest.skipped.push(`agents/skills/${entry.name}`);
        continue;
      }
      for (const file of listFiles(skillDir)) {
        const relative = `skills/${entry.name}/${relativePosix(skillDir, file)}`;
        const target = path.join(snapshotRoot, "agents", ...relative.split("/"));
        const manifestPathLabel = `agents/${relative}`;
        if (copySnapshotFile(file, target, manifest, manifestPathLabel)) {
          manifest.files.push(manifestPathLabel);
        }
      }
    }
  }

  manifest.skipped = manifest.skipped.map(toPortableText).sort();
  refreshManifestFiles(manifest);
  writeText(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);

  ok(`Saved ${manifest.files.length} file(s) to ${snapshotRoot}`);
  info(`Skipped ${manifest.skipped.length} generated or unsafe item(s).`);
  info("Next required step: run /dt:update-remote-plugins from this repository.");
}

function currentPlatformConfigFile() {
  const platformSpecific = path.join(codexSnapshotRoot, `config.${platform}.toml`);
  if (exists(platformSpecific)) {
    return platformSpecific;
  }
  return null;
}

function backupFile(target, backupRoot, manifest) {
  if (!exists(target)) {
    return;
  }
  const roots = [codexDir, agentsDir];
  const owner = roots.find((root) => isInside(target, root));
  if (!owner) {
    return;
  }
  const relative = path.relative(owner, target);
  const backupTarget = path.join(backupRoot, path.basename(owner), relative);
  copyFile(target, backupTarget);
  manifest.backups.push(backupTarget);
}

function applySnapshotFile(source, target, backupRoot, applyManifest) {
  assertInside(source, snapshotRoot);
  const targetRoot = isInside(target, codexDir) ? codexDir : agentsDir;
  assertInside(target, targetRoot);
  backupFile(target, backupRoot, applyManifest);
  applyPortableSnapshotFile(source, target);
  applyManifest.applied.push(target);
}

function pullSnapshot() {
  if (!exists(manifestPath)) {
    fail(`No snapshot found: ${manifestPath}`);
  }

  const backupRoot = path.join(homeDir, ".codex-sync-backups", new Date().toISOString().replace(/[:.]/g, "-"));
  const applyManifest = {
    applied: [],
    skipped: [],
    backups: [],
  };

  const configFile = currentPlatformConfigFile();
  if (configFile) {
    applySnapshotFile(configFile, path.join(codexDir, "config.toml"), backupRoot, applyManifest);
  } else {
    applyManifest.skipped.push(`codex/config.toml: no config.${platform}.toml in snapshot`);
  }

  for (const file of listFiles(codexSnapshotRoot)) {
    const relative = relativePosix(codexSnapshotRoot, file);
    if (/^config\.(darwin|win32|linux)\.toml$/.test(relative)) {
      continue;
    }
    const target = path.join(codexDir, ...relative.split("/"));
    applySnapshotFile(file, target, backupRoot, applyManifest);
  }

  const snapshotSkillsRoot = path.join(snapshotRoot, "agents", "skills");
  for (const file of listFiles(snapshotSkillsRoot)) {
    const relative = relativePosix(path.join(snapshotRoot, "agents"), file);
    const target = path.join(agentsDir, ...relative.split("/"));
    applySnapshotFile(file, target, backupRoot, applyManifest);
  }

  ok(`Applied ${applyManifest.applied.length} file(s).`);
  if (applyManifest.backups.length > 0) {
    info(`Backed up overwritten files under ${backupRoot}`);
  }
  for (const skipped of applyManifest.skipped) {
    info(`Skipped: ${skipped}`);
  }
  info("Restart Codex or start a new thread for config and skill changes to load.");
}

function status() {
  if (!exists(manifestPath)) {
    console.log("No Codex sync snapshot exists yet.");
    return;
  }
  const manifest = JSON.parse(readText(manifestPath));
  console.log(`Snapshot: ${manifestPath}`);
  console.log(`Generated: ${manifest.generatedAt}`);
  console.log(`Source platform: ${manifest.sourcePlatform}`);
  console.log(`Files: ${manifest.files.length}`);
  console.log(`Skipped: ${manifest.skipped.length}`);
}

if (mode === "push") {
  pushSnapshot();
} else if (mode === "pull") {
  pullSnapshot();
} else if (mode === "status") {
  status();
} else {
  console.log("Usage: node scripts/codex-sync.js <push|pull|status>");
  process.exit(mode ? 1 : 0);
}
