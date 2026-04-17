#!/usr/bin/env bash
set -euo pipefail

MARKETPLACE_NAME="dev-tools-skills"
REPO_URL="git@github.com:adzcsx2/dev-tools-skills.git"
VSCODE_PROMPTS_DIR="${VSCODE_USER_PROMPTS_FOLDER:-$HOME/Library/Application Support/Code/User/prompts}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_JSON="$SCRIPT_DIR/.claude-plugin/plugin.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
KNOWN_MKTS_FILE="$PLUGINS_DIR/known_marketplaces.json"
INSTALLED_FILE="$PLUGINS_DIR/installed_plugins.json"

PLUGIN_NAME=""
VERSION=""
PLUGIN_KEY=""

COMMON_SKILLS="init study push update-remote-plugins code-note"
ANDROID_SKILLS="gradle-build-performance update-docs-android android-i18n android-fold-adapter auto-ui-test"
FLUTTER_SKILLS="update-docs-flutter"

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

category_desc() {
  case "$1" in
    common)  echo "Common tools (dt:init, dt:study, dt:push, dt:update-remote-plugins, dt:code-note)" ;;
    android) echo "Android tools (adt:update-docs, adt:gradle-build-performance, etc.)" ;;
    flutter) echo "Flutter tools (fdt:update-docs)" ;;
    *)       echo "" ;;
  esac
}

skills_for_category() {
  case "$1" in
    common)  echo "$COMMON_SKILLS" ;;
    android) echo "$ANDROID_SKILLS" ;;
    flutter) echo "$FLUTTER_SKILLS" ;;
  esac
}

ensure_dir() {
  mkdir -p "$1"
}

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    error "Required file not found: $path"
    exit 1
  fi
}

assert_path_in_claude_dir() {
  local path="$1"
  local base="${CLAUDE_DIR%/}"
  case "$path" in
    "$base"|"$base"/*) ;;
    *)
      error "Refusing to operate outside CLAUDE_DIR: $path"
      exit 1
      ;;
  esac
}

remove_path_if_exists() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    assert_path_in_claude_dir "$path"
    rm -rf "$path"
    info "Removed: $path"
  fi
}

require_jq() {
  if ! has_cmd jq; then
    error "jq is required but not installed."
    echo "Install with:"
    echo "  macOS:   brew install jq"
    echo "  Ubuntu:  sudo apt install jq"
    echo "  Fedora:  sudo dnf install jq"
    exit 1
  fi
}

load_plugin_metadata() {
  require_file "$PLUGIN_JSON"
  PLUGIN_NAME="$(jq -r '.name // empty' "$PLUGIN_JSON")"
  VERSION="$(jq -r '.version // empty' "$PLUGIN_JSON")"

  if [ -z "$PLUGIN_NAME" ] || [ -z "$VERSION" ] || [ "$PLUGIN_NAME" = "null" ] || [ "$VERSION" = "null" ]; then
    error "Failed to read plugin metadata from $PLUGIN_JSON"
    exit 1
  fi

  PLUGIN_KEY="${MARKETPLACE_NAME}@${PLUGIN_NAME}"
}

ensure_claude_layout() {
  ensure_dir "$CLAUDE_DIR"
  ensure_dir "$PLUGINS_DIR"
  ensure_dir "$CACHE_DIR"
  ensure_dir "$MARKETPLACE_DIR"
}

install_vscode_prompt() {
  local prompts_dir="$SCRIPT_DIR/.github/prompts"

  if [ ! -d "$prompts_dir" ]; then
    warn "VS Code Copilot prompts directory not found: $prompts_dir"
    return
  fi

  ensure_dir "$VSCODE_PROMPTS_DIR"
  local installed_any=false

  for prompt_src in "$prompts_dir"/*.prompt.md; do
    [ -e "$prompt_src" ] || continue
    cp "$prompt_src" "$VSCODE_PROMPTS_DIR/$(basename "$prompt_src")"
    ok "Installed VS Code Copilot prompt: $VSCODE_PROMPTS_DIR/$(basename "$prompt_src")"
    installed_any=true
  done

  if [ "$installed_any" = false ]; then
    warn "No VS Code Copilot prompt files found in: $prompts_dir"
  fi
}

remove_vscode_prompt() {
  local prompts_dir="$SCRIPT_DIR/.github/prompts"
  [ -d "$prompts_dir" ] || return

  for prompt_src in "$prompts_dir"/*.prompt.md; do
    [ -e "$prompt_src" ] || continue
    local prompt_path="$VSCODE_PROMPTS_DIR/$(basename "$prompt_src")"
    if [ -f "$prompt_path" ]; then
      rm -f "$prompt_path"
      info "Removed: $prompt_path"
    fi
  done
}

ensure_settings_plugin() {
  ensure_dir "$CLAUDE_DIR"
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
  fi
  local tmp
  tmp="$(jq --arg key "$PLUGIN_KEY" '.enabledPlugins = (.enabledPlugins // {}) | .enabledPlugins[$key] = true' "$SETTINGS_FILE")"
  echo "$tmp" > "$SETTINGS_FILE"
}

remove_settings_plugin() {
  if [ -f "$SETTINGS_FILE" ]; then
    local tmp
    tmp="$(jq --arg key "$PLUGIN_KEY" '.enabledPlugins = (.enabledPlugins // {}) | del(.enabledPlugins[$key])' "$SETTINGS_FILE")"
    echo "$tmp" > "$SETTINGS_FILE"
  fi
}

ensure_marketplace_registration() {
  ensure_dir "$PLUGINS_DIR"
  if [ ! -f "$KNOWN_MKTS_FILE" ]; then
    echo '{}' > "$KNOWN_MKTS_FILE"
  fi

  local install_location="$MARKETPLACE_DIR/$MARKETPLACE_NAME"
  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"

  local tmp
  tmp="$(jq \
    --arg name "$MARKETPLACE_NAME" \
    --arg url "$REPO_URL" \
    --arg location "$install_location" \
    --arg ts "$timestamp" \
    '.[$name] = {
      "source": {"source": "git", "url": $url},
      "installLocation": $location,
      "lastUpdated": $ts
    }' "$KNOWN_MKTS_FILE")"
  echo "$tmp" > "$KNOWN_MKTS_FILE"
}

remove_marketplace_registration() {
  if [ -f "$KNOWN_MKTS_FILE" ]; then
    local tmp
    tmp="$(jq --arg name "$MARKETPLACE_NAME" 'del(.[$name])' "$KNOWN_MKTS_FILE")"
    echo "$tmp" > "$KNOWN_MKTS_FILE"
  fi
}

ensure_installed_plugin() {
  local install_path="$CACHE_DIR/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION"
  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"

  ensure_dir "$PLUGINS_DIR"
  if [ ! -f "$INSTALLED_FILE" ]; then
    echo '{"version":2,"plugins":{}}' > "$INSTALLED_FILE"
  fi

  local tmp
  tmp="$(jq \
    --arg key "$PLUGIN_KEY" \
    --arg path "$install_path" \
    --arg ver "$VERSION" \
    --arg ts "$timestamp" \
    '.version = (.version // 2) |
     .plugins = (.plugins // {}) |
     .plugins[$key] = [{
       "scope": "user",
       "installPath": $path,
       "version": $ver,
       "installedAt": $ts,
       "lastUpdated": $ts
     }]' "$INSTALLED_FILE")"
  echo "$tmp" > "$INSTALLED_FILE"
}

remove_installed_plugin() {
  if [ -f "$INSTALLED_FILE" ]; then
    local tmp
    tmp="$(jq --arg key "$PLUGIN_KEY" '.plugins = (.plugins // {}) | del(.plugins[$key])' "$INSTALLED_FILE")"
    echo "$tmp" > "$INSTALLED_FILE"
  fi
}

reset_existing_installation() {
  info "Resetting existing plugin state under $CLAUDE_DIR..."
  remove_settings_plugin
  remove_installed_plugin
  remove_marketplace_registration
  remove_vscode_prompt
  remove_path_if_exists "$CACHE_DIR/$MARKETPLACE_NAME/$PLUGIN_NAME"
  remove_path_if_exists "$MARKETPLACE_DIR/$MARKETPLACE_NAME"
}

copy_workspace_snapshot() {
  local target="$1"

  ensure_dir "$target"
  cp -R "$SCRIPT_DIR/skills" "$target/"
  cp -R "$SCRIPT_DIR/.claude-plugin" "$target/"
  if [ -d "$SCRIPT_DIR/.github" ]; then
    cp -R "$SCRIPT_DIR/.github" "$target/"
  fi

  for file in README.md README_EN.md CLAUDE.md LICENSE install.sh install.ps1 uninstall.sh uninstall.ps1; do
    if [ -e "$SCRIPT_DIR/$file" ]; then
      cp "$SCRIPT_DIR/$file" "$target/"
    fi
  done
}

install_marketplace() {
  local target="$MARKETPLACE_DIR/$MARKETPLACE_NAME"

  info "Setting up marketplace: $MARKETPLACE_NAME..."
  ensure_dir "$MARKETPLACE_DIR"
  remove_path_if_exists "$target"

  if git clone "$REPO_URL" "$target" 2>/dev/null; then
    ok "Cloned marketplace from remote"
  else
    warn "Git clone failed, using local workspace snapshot..."
    copy_workspace_snapshot "$target"
  fi

  ensure_marketplace_registration
  ok "Marketplace ready at $target"
}

install_skills() {
  local selected_skills="$1"
  local cache_dest="$CACHE_DIR/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION"

  info "Installing skills to cache..."
  ensure_dir "$cache_dest/skills"
  ensure_dir "$cache_dest/.claude-plugin"

  cp "$PLUGIN_JSON" "$cache_dest/.claude-plugin/plugin.json"

  for skill in $selected_skills; do
    if [ -d "$SCRIPT_DIR/skills/$skill" ]; then
      cp -R "$SCRIPT_DIR/skills/$skill" "$cache_dest/skills/"
      ok "Copied skill: $skill"
    else
      warn "Skill not found: $skill (skipping)"
    fi
  done

  ensure_settings_plugin
  ensure_installed_plugin
  ok "Plugin registered with latest version: $VERSION"
}

uninstall_all() {
  info "Uninstalling $MARKETPLACE_NAME..."
  reset_existing_installation
  ok "Uninstall complete!"
}

interactive_select() {
  echo -e "${CYAN}========================================${NC}"
  echo -e "${CYAN}  dev-tools-skills Installer${NC}"
  echo -e "${CYAN}========================================${NC}"
  echo ""
  echo "Select skill categories to install:"
  echo ""
  echo -e "  ${GREEN}[1]${NC} common  - $(category_desc common)"
  echo -e "  ${GREEN}[2]${NC} android - $(category_desc android)"
  echo -e "  ${GREEN}[3]${NC} flutter - $(category_desc flutter)"
  echo ""
  echo -e "  ${GREEN}[a]${NC} Install ALL"
  echo -e "  ${GREEN}[q]${NC} Quit"
  echo ""

  read -r -p "Select (e.g. 1 2 or a): " choice

  case "$choice" in
    q|Q)
      info "Cancelled."
      exit 0
      ;;
    a|A)
      SELECTED_CATEGORIES="common android flutter"
      ;;
    *)
      SELECTED_CATEGORIES="common"
      for num in $choice; do
        case "$num" in
          1) SELECTED_CATEGORIES="common" ;;
          2) SELECTED_CATEGORIES="$SELECTED_CATEGORIES android" ;;
          3) SELECTED_CATEGORIES="$SELECTED_CATEGORIES flutter" ;;
        esac
      done
      ;;
  esac
}

main() {
  echo ""
  echo -e "${CYAN}dev-tools-skills Installer${NC}"
  echo ""

  if ! has_cmd git; then
    error "git is required but not installed."
    exit 1
  fi

  require_jq
  load_plugin_metadata
  ensure_claude_layout

  local uninstall=false
  local selected_categories=""

  if [ $# -eq 0 ]; then
    interactive_select
    selected_categories="$SELECTED_CATEGORIES"
  else
    case "$1" in
      --uninstall|-u)
        uninstall=true
        ;;
      --all|-a)
        selected_categories="common android flutter"
        ;;
      --help|-h)
        echo "Usage: $0 [OPTIONS] [CATEGORY...]"
        echo ""
        echo "Options:"
        echo "  --all, -a          Install all skill categories"
        echo "  --uninstall, -u    Remove installed plugin"
        echo "  --help, -h         Show this help"
        echo ""
        echo "Categories:"
        echo "  common   - $(category_desc common)"
        echo "  android  - $(category_desc android)"
        echo "  flutter  - $(category_desc flutter)"
        exit 0
        ;;
      *)
        for arg in "$@"; do
          case "$arg" in
            common|android|flutter) selected_categories="$selected_categories $arg" ;;
            *) warn "Unknown category: $arg (skipping)" ;;
          esac
        done
        if ! echo "$selected_categories" | grep -q "common"; then
          selected_categories="common $selected_categories"
        fi
        ;;
    esac
  fi

  if [ "$uninstall" = true ]; then
    uninstall_all
    exit 0
  fi

  local all_selected=""
  for category in $selected_categories; do
    all_selected="$all_selected $(skills_for_category "$category")"
  done

  echo -e "${BLUE}Will install:${NC}"
  for category in $selected_categories; do
    echo -e "  ${GREEN}- $category${NC}: $(category_desc "$category")"
  done
  echo ""

  reset_existing_installation
  ensure_claude_layout
  install_marketplace
  install_skills "$all_selected"
  install_vscode_prompt

  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Installation Complete!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Installed skills:"
  for skill in $all_selected; do
    echo -e "  ${GREEN}- $skill${NC}"
  done
  echo ""
  echo "Please restart Claude Code and reload VS Code Copilot chat to load the new commands."
  echo ""
}

main "$@"