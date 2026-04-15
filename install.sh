#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# dev-tools-skills Installer for macOS / Linux
# Usage:
#   ./install.sh                    # Interactive mode
#   ./install.sh --all              # Install all plugins
#   ./install.sh dev-tools          # Install specific plugins
#   ./install.sh dev-tools android-dev-tools
#   ./install.sh --uninstall        # Remove installed plugins
# ============================================================

MARKETPLACE_NAME="dev-tools-skills"
REPO_URL="git@github.com:adzcsx2/dev-tools-skills.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Resolve paths
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache"
MARKETPLACE_DIR="$PLUGINS_DIR/marketplaces"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
KNOWN_MKTS_FILE="$PLUGINS_DIR/known_marketplaces.json"
INSTALLED_FILE="$PLUGINS_DIR/installed_plugins.json"

# All available plugins
ALL_PLUGINS=("dev-tools" "android-dev-tools" "flutter-dev-tools")

# Plugin description (bash 3.x compatible - no associative arrays)
plugin_desc() {
  case "$1" in
    dev-tools)           echo "Common tools (dt:push, dt:update-remote-plugins, dt:code-note)" ;;
    android-dev-tools)   echo "Android tools (adt:init-android, adt:update-docs, etc.)" ;;
    flutter-dev-tools)   echo "Flutter tools (fdt:init-flutter, fdt:update-docs)" ;;
    *)                   echo "" ;;
  esac
}

# ============================================================
# Helper Functions
# ============================================================

info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if a command exists
has_cmd() {
  command -v "$1" &>/dev/null
}

# Check if jq exists, install hint if not
require_jq() {
  if ! has_cmd jq; then
    error "jq is required but not installed."
    echo ""
    echo "Install with:"
    echo "  macOS:   brew install jq"
    echo "  Ubuntu:  sudo apt install jq"
    echo "  Fedora:  sudo dnf install jq"
    echo ""
    echo "Or run without jq (limited functionality):"
    echo "  SKIP_JQ=1 ./install.sh --all"
    exit 1
  fi
}

# Ensure directory exists
ensure_dir() {
  mkdir -p "$1"
}

# Read plugin version from plugin.json
plugin_version() {
  local plugin_name="$1"
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local plugin_json="$script_dir/plugins/$plugin_name/.claude-plugin/plugin.json"

  if [ -f "$plugin_json" ]; then
    if has_cmd jq; then
      jq -r '.version' "$plugin_json"
    else
      grep '"version"' "$plugin_json" | head -1 | cut -d'"' -f4
    fi
  else
    echo "0.0.0"
  fi
}

# ============================================================
# JSON manipulation (jq or fallback)
# ============================================================

json_set_field() {
  local file="$1" key="$2" value="$3"

  if has_cmd jq; then
    local tmp=$(jq "$key = $value" "$file")
    echo "$tmp" > "$file"
  else
    warn "jq not available, skipping JSON update: $key in $file"
  fi
}

# ============================================================
# Settings.json operations
# ============================================================

ensure_settings_plugin() {
  local plugin_key="$1"  # e.g. "dev-tools-skills@dev-tools"

  if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
  fi

  if has_cmd jq; then
    local tmp=$(jq --arg key "$plugin_key" '.enabledPlugins[$key] = true' "$SETTINGS_FILE")
    echo "$tmp" > "$SETTINGS_FILE"
  else
    # Fallback: simple grep check
    if ! grep -q "$plugin_key" "$SETTINGS_FILE" 2>/dev/null; then
      warn "jq not available. Please manually add '$plugin_key' to $SETTINGS_FILE"
    fi
  fi
}

remove_settings_plugin() {
  local plugin_key="$1"

  if [ -f "$SETTINGS_FILE" ] && has_cmd jq; then
    local tmp=$(jq --arg key "$plugin_key" 'del(.enabledPlugins[$key])' "$SETTINGS_FILE")
    echo "$tmp" > "$SETTINGS_FILE"
  fi
}

# ============================================================
# known_marketplaces.json operations
# ============================================================

ensure_marketplace_registration() {
  ensure_dir "$PLUGINS_DIR"

  if [ ! -f "$KNOWN_MKTS_FILE" ]; then
    echo '{}' > "$KNOWN_MKTS_FILE"
  fi

  local install_location="$MARKETPLACE_DIR/$MARKETPLACE_NAME"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

  if has_cmd jq; then
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
  else
    warn "jq not available. Please manually update $KNOWN_MKTS_FILE"
  fi
}

remove_marketplace_registration() {
  if [ -f "$KNOWN_MKTS_FILE" ] && has_cmd jq; then
    local tmp=$(jq --arg name "$MARKETPLACE_NAME" 'del(.[$name])' "$KNOWN_MKTS_FILE")
    echo "$tmp" > "$KNOWN_MKTS_FILE"
  fi
}

# ============================================================
# installed_plugins.json operations
# ============================================================

ensure_installed_plugin() {
  local plugin_name="$1"
  local version="$2"
  local plugin_key="${MARKETPLACE_NAME}@${plugin_name}"
  local install_path="${CACHE_DIR}/${MARKETPLACE_NAME}/${plugin_name}/${version}"
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

  if [ ! -f "$INSTALLED_FILE" ]; then
    echo '{"version":2,"plugins":{}}' > "$INSTALLED_FILE"
  fi

  if has_cmd jq; then
    local tmp=$(jq \
      --arg key "$plugin_key" \
      --arg path "$install_path" \
      --arg ver "$version" \
      --arg ts "$timestamp" \
      '.plugins[$key] = [{
        "scope": "user",
        "installPath": $path,
        "version": $ver,
        "installedAt": $ts,
        "lastUpdated": $ts
      }]' "$INSTALLED_FILE")
    echo "$tmp" > "$INSTALLED_FILE"
  else
    warn "jq not available. Please manually update $INSTALLED_FILE"
  fi
}

remove_installed_plugin() {
  local plugin_name="$1"
  local plugin_key="${MARKETPLACE_NAME}@${plugin_name}"

  if [ -f "$INSTALLED_FILE" ] && has_cmd jq; then
    local tmp=$(jq --arg key "$plugin_key" 'del(.plugins[$key])' "$INSTALLED_FILE")
    echo "$tmp" > "$INSTALLED_FILE"
  fi
}

# ============================================================
# Core install/uninstall operations
# ============================================================

install_plugin() {
  local plugin_name="$1"
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local plugin_src="$script_dir/plugins/$plugin_name"
  local version=$(plugin_version "$plugin_name")

  if [ ! -d "$plugin_src" ]; then
    error "Plugin source not found: $plugin_src"
    return 1
  fi

  info "Installing $plugin_name v${version}..."

  # 1. Copy to cache
  local cache_dest="$CACHE_DIR/$MARKETPLACE_NAME/$plugin_name/$version"
  ensure_dir "$cache_dest"
  cp -r "$plugin_src/"* "$cache_dest/"
  ok "Cached to $cache_dest"

  # 2. Register in settings
  local plugin_key="${MARKETPLACE_NAME}@${plugin_name}"
  ensure_settings_plugin "$plugin_key"
  ok "Enabled in settings.json"

  # 3. Register in installed_plugins
  ensure_installed_plugin "$plugin_name" "$version"
  ok "Registered in installed_plugins.json"

  ok "$plugin_name v${version} installed successfully!"
  echo ""
}

install_marketplace() {
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local target="$MARKETPLACE_DIR/$MARKETPLACE_NAME"

  info "Setting up marketplace: $MARKETPLACE_NAME..."

  # Clone or update marketplace
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
    }
  fi
  ok "Marketplace ready at $target"

  # Register marketplace
  ensure_marketplace_registration
  ok "Marketplace registered"

  echo ""
}

uninstall_all() {
  info "Uninstalling $MARKETPLACE_NAME plugins..."

  for plugin_name in "${ALL_PLUGINS[@]}"; do
    local plugin_key="${MARKETPLACE_NAME}@${plugin_name}"

    # Remove from settings
    remove_settings_plugin "$plugin_key"

    # Remove from installed_plugins
    remove_installed_plugin "$plugin_name"

    # Remove from cache
    local cache_path="$CACHE_DIR/$MARKETPLACE_NAME/$plugin_name"
    if [ -d "$cache_path" ]; then
      rm -rf "$cache_path"
      info "Removed cache: $cache_path"
    fi
  done

  # Remove marketplace registration
  remove_marketplace_registration

  # Remove marketplace directory
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
  echo -e "${CYAN}  dev-tools-skills Plugin Installer${NC}"
  echo -e "${CYAN}========================================${NC}"
  echo ""
  echo "Available plugins:"
  echo ""

  local i=1
  for plugin_name in "${ALL_PLUGINS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} $plugin_name"
    echo -e "      $(plugin_desc "$plugin_name")"
    echo ""
    i=$((i + 1))
  done

  echo -e "  ${GREEN}[a]${NC} Install ALL plugins"
  echo -e "  ${GREEN}[q]${NC} Quit without installing"
  echo ""

  read -p "Select plugins to install (e.g. 1 2 or a): " choice

  case "$choice" in
    q|Q)
      info "Cancelled."
      exit 0
      ;;
    a|A|all|--all)
      SELECTED=("${ALL_PLUGINS[@]}")
      ;;
    *)
      SELECTED=()
      for num in $choice; do
        local idx=$((num - 1))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#ALL_PLUGINS[@]}" ]; then
          SELECTED+=("${ALL_PLUGINS[$idx]}")
        fi
      done
      ;;
  esac

  if [ ${#SELECTED[@]} -eq 0 ]; then
    error "No valid selection. Exiting."
    exit 1
  fi
}

# ============================================================
# Main
# ============================================================

main() {
  echo ""
  echo -e "${CYAN}dev-tools-skills Installer${NC}"
  echo ""

  # Check prerequisites
  if ! has_cmd git; then
    error "git is required but not installed."
    exit 1
  fi

  # Parse arguments
  local UNINSTALL=false
  SELECTED=()

  if [ $# -eq 0 ]; then
    # No args: interactive mode
    interactive_select
  else
    case "$1" in
      --uninstall|-u)
        UNINSTALL=true
        ;;
      --all|-a)
        SELECTED=("${ALL_PLUGINS[@]}")
        ;;
      --help|-h)
        echo "Usage: $0 [OPTIONS] [PLUGIN...]"
        echo ""
        echo "Options:"
        echo "  --all, -a          Install all plugins"
        echo "  --uninstall, -u    Remove all installed plugins"
        echo "  --help, -h         Show this help"
        echo ""
        echo "Plugins:"
        for p in "${ALL_PLUGINS[@]}"; do
          echo "  $p  - $(plugin_desc "$p")"
        done
        echo ""
        echo "Examples:"
        echo "  $0                          # Interactive mode"
        echo "  $0 --all                    # Install everything"
        echo "  $0 dev-tools                # Install common tools only"
        echo "  $0 dev-tools android-dev-tools  # Install common + Android tools"
        exit 0
        ;;
      *)
        # Specific plugins
        for arg in "$@"; do
          if [[ " ${ALL_PLUGINS[*]} " == *" $arg "* ]]; then
            SELECTED+=("$arg")
          else
            warn "Unknown plugin: $arg (skipping)"
          fi
        done
        ;;
    esac
  fi

  if [ "$UNINSTALL" = true ]; then
    uninstall_all
    exit 0
  fi

  if [ ${#SELECTED[@]} -eq 0 ]; then
    error "No plugins selected."
    exit 1
  fi

  # Always include dev-tools if not explicitly selected
  if [[ ! " ${SELECTED[*]} " == *" dev-tools "* ]]; then
    warn "Auto-including 'dev-tools' (required for dt:update-remote-plugins)"
    SELECTED=("dev-tools" "${SELECTED[@]}")
  fi

  echo -e "${BLUE}Will install:${NC}"
  for p in "${SELECTED[@]}"; do
    echo -e "  ${GREEN}- $p${NC}"
  done
  echo ""

  # Suggest installing jq if not present
  if ! has_cmd jq; then
    warn "jq not found. Install for best experience: brew install jq (macOS) / sudo apt install jq (Linux)"
    echo ""
    read -p "Continue without jq? [y/N] " yn
    case "$yn" in
      [yY]*) ;;
      *) error "Aborted. Install jq first."; exit 1 ;;
    esac
  fi

  # Install marketplace
  install_marketplace

  # Install each selected plugin
  for plugin_name in "${SELECTED[@]}"; do
    install_plugin "$plugin_name"
  done

  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}  Installation Complete!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "Installed plugins:"
  for p in "${SELECTED[@]}"; do
    echo -e "  ${GREEN}- $p${NC} ($(plugin_desc "$p"))"
  done
  echo ""
  echo "Please restart Claude Code to load the new plugins."
  echo ""
}

main "$@"
