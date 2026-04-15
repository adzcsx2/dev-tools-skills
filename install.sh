#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# dev-tools-skills Installer for macOS / Linux
# Usage:
#   ./install.sh                    # Interactive mode
#   ./install.sh --all              # Install all skills
#   ./install.sh common             # Only common skills (dt:*)
#   ./install.sh common android     # Common + Android skills
#   ./install.sh common android flutter
#   ./install.sh --uninstall        # Remove installed plugin
# ============================================================

MARKETPLACE_NAME="dev-tools-skills"
PLUGIN_NAME="dev-tools-skills"
REPO_URL="git@github.com:adzcsx2/dev-tools-skills.git"
VERSION="1.0.0"
VSCODE_PROMPTS_DIR="${VSCODE_USER_PROMPTS_FOLDER:-$HOME/Library/Application Support/Code/User/prompts}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Paths
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
KNOWN_MKTS_FILE="$PLUGINS_DIR/known_marketplaces.json"
INSTALLED_FILE="$PLUGINS_DIR/installed_plugins.json"
PLUGIN_KEY="${MARKETPLACE_NAME}@${PLUGIN_NAME}"

# Skill categories
COMMON_SKILLS="init push update-remote-plugins code-note"
ANDROID_SKILLS="gradle-build-performance update-docs-android android-i18n android-fold-adapter auto-ui-test"
FLUTTER_SKILLS="update-docs-flutter"

# ============================================================
# Helpers
# ============================================================

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

has_cmd() { command -v "$1" &>/dev/null; }

category_desc() {
  case "$1" in
    common)  echo "Common tools (dt:init, dt:push, dt:update-remote-plugins, dt:code-note)" ;;
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

ensure_dir() { mkdir -p "$1"; }

install_vscode_prompt() {
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local prompt_src="$script_dir/.github/prompts/init.prompt.md"

  if [ ! -f "$prompt_src" ]; then
    warn "VS Code Copilot prompt source not found: $prompt_src"
    return
  fi

  ensure_dir "$VSCODE_PROMPTS_DIR"
  cp "$prompt_src" "$VSCODE_PROMPTS_DIR/init.prompt.md"
  ok "Installed VS Code Copilot prompt: $VSCODE_PROMPTS_DIR/init.prompt.md"
}

remove_vscode_prompt() {
  local prompt_path="$VSCODE_PROMPTS_DIR/init.prompt.md"
  if [ -f "$prompt_path" ]; then
    rm -f "$prompt_path"
    info "Removed VS Code Copilot prompt: $prompt_path"
  fi
}

# ============================================================
# JSON operations (jq required)
# ============================================================

require_jq() {
  if ! has_cmd jq; then
    error "jq is required but not installed."
    echo ""
    echo "Install with:"
    echo "  macOS:   brew install jq"
    echo "  Ubuntu:  sudo apt install jq"
    echo "  Fedora:  sudo dnf install jq"
    exit 1
  fi
}

ensure_settings_plugin() {
  if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
  fi
  local tmp=$(jq --arg key "$PLUGIN_KEY" '.enabledPlugins[$key] = true' "$SETTINGS_FILE")
  echo "$tmp" > "$SETTINGS_FILE"
}

remove_settings_plugin() {
  if [ -f "$SETTINGS_FILE" ]; then
    local tmp=$(jq --arg key "$PLUGIN_KEY" 'del(.enabledPlugins[$key])' "$SETTINGS_FILE")
    echo "$tmp" > "$SETTINGS_FILE"
  fi
}

ensure_marketplace_registration() {
  ensure_dir "$PLUGINS_DIR"
  if [ ! -f "$KNOWN_MKTS_FILE" ]; then
    echo '{}' > "$KNOWN_MKTS_FILE"
  fi
  local install_location="$MARKETPLACE_DIR/$MARKETPLACE_NAME"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  local tmp=$(jq \
    --arg name "$MARKETPLACE_NAME" \
    --arg url "$REPO_URL" \
    --arg location "$install_location" \
    --arg ts "$timestamp" \
    '.[$name] = {
      "source": {"source": "git", "url": $url},
      "installLocation": $location,
      "lastUpdated": $ts
    }' "$KNOWN_MKTS_FILE")
  echo "$tmp" > "$KNOWN_MKTS_FILE"
}

remove_marketplace_registration() {
  if [ -f "$KNOWN_MKTS_FILE" ]; then
    local tmp=$(jq --arg name "$MARKETPLACE_NAME" 'del(.[$name])' "$KNOWN_MKTS_FILE")
    echo "$tmp" > "$KNOWN_MKTS_FILE"
  fi
}

ensure_installed_plugin() {
  local install_path="${CACHE_DIR}/${MARKETPLACE_NAME}/${PLUGIN_NAME}/${VERSION}"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

  if [ ! -f "$INSTALLED_FILE" ]; then
    echo '{"version":2,"plugins":{}}' > "$INSTALLED_FILE"
  fi
  local tmp=$(jq \
    --arg key "$PLUGIN_KEY" \
    --arg path "$install_path" \
    --arg ver "$VERSION" \
    --arg ts "$timestamp" \
    '.plugins[$key] = [{
      "scope": "user",
      "installPath": $path,
      "version": $ver,
      "installedAt": $ts,
      "lastUpdated": $ts
    }]' "$INSTALLED_FILE")
  echo "$tmp" > "$INSTALLED_FILE"
}

remove_installed_plugin() {
  if [ -f "$INSTALLED_FILE" ]; then
    local tmp=$(jq --arg key "$PLUGIN_KEY" 'del(.plugins[$key])' "$INSTALLED_FILE")
    echo "$tmp" > "$INSTALLED_FILE"
  fi
}

# ============================================================
# Core operations
# ============================================================

install_marketplace() {
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local target="$MARKETPLACE_DIR/$MARKETPLACE_NAME"

  info "Setting up marketplace: $MARKETPLACE_NAME..."

  if [ -d "$target/.git" ]; then
    info "Marketplace exists, pulling latest..."
    git -C "$target" pull 2>/dev/null || true
  else
    info "Cloning marketplace..."
    rm -rf "$target"
    ensure_dir "$MARKETPLACE_DIR"
    git clone "$REPO_URL" "$target" 2>/dev/null || {
      warn "Git clone failed, using local copy..."
      ensure_dir "$target"
      cp -r "$script_dir/"* "$target/" 2>/dev/null || true
      cp "$script_dir/.claude-plugin" "$target/" 2>/dev/null || true
      cp "$script_dir/.gitignore" "$target/" 2>/dev/null || true
    }
  fi
  ok "Marketplace ready at $target"

  ensure_marketplace_registration
  ok "Marketplace registered"
  echo ""
}

install_skills() {
  local selected_skills="$1"
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local cache_dest="$CACHE_DIR/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION"

  info "Installing skills to cache..."

  ensure_dir "$cache_dest/skills"
  ensure_dir "$cache_dest/.claude-plugin"

  # Copy plugin.json
  if [ -f "$script_dir/.claude-plugin/plugin.json" ]; then
    cp "$script_dir/.claude-plugin/plugin.json" "$cache_dest/.claude-plugin/"
  fi

  # Copy selected skills
  for skill in $selected_skills; do
    if [ -d "$script_dir/skills/$skill" ]; then
      cp -r "$script_dir/skills/$skill" "$cache_dest/skills/"
      ok "Copied skill: $skill"
    else
      warn "Skill not found: $skill (skipping)"
    fi
  done

  # Register
  ensure_settings_plugin
  ok "Enabled in settings.json"

  ensure_installed_plugin
  ok "Registered in installed_plugins.json"

  echo ""
}

uninstall_all() {
  info "Uninstalling $MARKETPLACE_NAME..."

  remove_settings_plugin
  remove_installed_plugin
  remove_marketplace_registration
  remove_vscode_prompt

  local cache_path="$CACHE_DIR/$MARKETPLACE_NAME"
  if [ -d "$cache_path" ]; then
    rm -rf "$cache_path"
    info "Removed cache: $cache_path"
  fi

  local mkt_path="$MARKETPLACE_DIR/$MARKETPLACE_NAME"
  if [ -d "$mkt_path" ]; then
    rm -rf "$mkt_path"
    info "Removed marketplace: $mkt_path"
  fi

  ok "Uninstall complete!"
}

# ============================================================
# Interactive selection
# ============================================================

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

  read -p "Select (e.g. 1 2 or a): " choice

  case "$choice" in
    q|Q) info "Cancelled."; exit 0 ;;
    a|A) SELECTED_CATEGORIES="common android flutter" ;;
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

# ============================================================
# Main
# ============================================================

main() {
  echo ""
  echo -e "${CYAN}dev-tools-skills Installer${NC}"
  echo ""

  if ! has_cmd git; then
    error "git is required but not installed."
    exit 1
  fi

  require_jq

  local UNINSTALL=false
  SELECTED_CATEGORIES=""

  if [ $# -eq 0 ]; then
    interactive_select
  else
    case "$1" in
      --uninstall|-u) UNINSTALL=true ;;
      --all|-a)       SELECTED_CATEGORIES="common android flutter" ;;
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
        echo ""
        echo "Examples:"
        echo "  $0                          # Interactive mode"
        echo "  $0 --all                    # Install everything"
        echo "  $0 common                   # Common tools only"
        echo "  $0 common android           # Common + Android tools"
        exit 0
        ;;
      *)
        for arg in "$@"; do
          case "$arg" in
            common|android|flutter) SELECTED_CATEGORIES="$SELECTED_CATEGORIES $arg" ;;
            *) warn "Unknown category: $arg (skipping)" ;;
          esac
        done
        # Always include common
        if ! echo "$SELECTED_CATEGORIES" | grep -q "common"; then
          SELECTED_CATEGORIES="common $SELECTED_CATEGORIES"
        fi
        ;;
    esac
  fi

  if [ "$UNINSTALL" = true ]; then
    uninstall_all
    exit 0
  fi

  # Collect selected skills
  local all_selected=""
  for cat in $SELECTED_CATEGORIES; do
    all_selected="$all_selected $(skills_for_category "$cat")"
  done

  echo -e "${BLUE}Will install:${NC}"
  for cat in $SELECTED_CATEGORIES; do
    echo -e "  ${GREEN}- $cat${NC}: $(category_desc "$cat")"
  done
  echo ""

  # Install
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
