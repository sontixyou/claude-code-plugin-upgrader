#!/bin/bash
# Upgrade a single Claude Code plugin
# Usage: upgrade-plugin.sh <plugin-name|plugin-id> [--dry-run]
#
# Examples:
#   upgrade-plugin.sh findy-development-plugin
#   upgrade-plugin.sh findy-development-plugin@Marcus
#   upgrade-plugin.sh findy-development-plugin --dry-run

set -e

PLUGIN_INPUT="$1"
DRY_RUN="${2:-}"
PLUGINS_DIR="${HOME}/.claude/plugins"

if [[ -z "$PLUGIN_INPUT" ]]; then
    echo "Error: Plugin name or ID required"
    echo "Usage: upgrade-plugin.sh <plugin-name|plugin-id> [--dry-run]"
    echo ""
    echo "Examples:"
    echo "  upgrade-plugin.sh findy-development-plugin"
    echo "  upgrade-plugin.sh findy-development-plugin@Marcus"
    exit 1
fi

# Check if input contains marketplace (@)
if [[ "$PLUGIN_INPUT" == *"@"* ]]; then
    PLUGIN_NAME="${PLUGIN_INPUT%@*}"
    PLUGIN_MARKETPLACE="${PLUGIN_INPUT#*@}"
    PLUGIN_ID="$PLUGIN_INPUT"
else
    PLUGIN_NAME="$PLUGIN_INPUT"
    PLUGIN_MARKETPLACE=""
    PLUGIN_ID=""
fi

# Get plugin info from claude CLI
get_plugin_info() {
    local name="$1"
    local marketplace="$2"

    if ! command -v claude &> /dev/null; then
        echo ""
        return
    fi

    local plugin_data=$(claude plugin list --json 2>/dev/null)

    if [[ -z "$plugin_data" ]]; then
        echo ""
        return
    fi

    # If marketplace is specified, look for exact match
    if [[ -n "$marketplace" ]]; then
        echo "$plugin_data" | jq -r --arg id "${name}@${marketplace}" '.[] | select(.id == $id) | @json' 2>/dev/null | head -1
    else
        # Otherwise, look for any plugin with matching name
        echo "$plugin_data" | jq -r --arg name "$name" '.[] | select(.id | startswith($name + "@")) | @json' 2>/dev/null | head -1
    fi
}

# Get plugin information
PLUGIN_INFO=$(get_plugin_info "$PLUGIN_NAME" "$PLUGIN_MARKETPLACE")

if [[ -z "$PLUGIN_INFO" ]]; then
    echo "Error: Plugin '$PLUGIN_INPUT' not found"
    echo ""
    echo "Installed plugins:"

    if command -v claude &> /dev/null; then
        claude plugin list --json 2>/dev/null | jq -r '.[].id' | sed 's/^/  - /'
    else
        echo "  (claude CLI not available)"
    fi
    exit 1
fi

# Extract plugin details
PLUGIN_ID=$(echo "$PLUGIN_INFO" | jq -r '.id')
PLUGIN_VERSION=$(echo "$PLUGIN_INFO" | jq -r '.version // "unknown"')
PLUGIN_PATH=$(echo "$PLUGIN_INFO" | jq -r '.installPath // ""')
PLUGIN_NAME="${PLUGIN_ID%@*}"
PLUGIN_MARKETPLACE="${PLUGIN_ID#*@}"

# Determine plugin source type
get_plugin_source() {
    local install_path="$1"

    # Marketplace plugins are in cache directory
    if [[ "$install_path" == *"/cache/"* ]]; then
        echo "marketplace"
        return
    fi

    # Check if it's a git repository
    if [[ -d "${install_path}/.git" ]]; then
        echo "git"
        return
    fi

    echo "local"
}

SOURCE=$(get_plugin_source "$PLUGIN_PATH")

upgrade_git_plugin() {
    local plugin_path="$1"
    local dry_run="$2"

    echo "Upgrading Git plugin: $PLUGIN_NAME"
    echo "Path: $plugin_path"

    cd "$plugin_path"

    # Get current state
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    echo "Current branch: $current_branch"
    echo "Current commit: $current_commit"

    if [[ "$dry_run" == "--dry-run" ]]; then
        echo ""
        echo "[DRY RUN] Would execute:"
        echo "  git fetch --all --tags"
        echo "  git pull origin $current_branch"

        # Show what would change
        git fetch --all --tags --quiet 2>/dev/null || true
        behind_count=$(git rev-list --count HEAD..origin/$current_branch 2>/dev/null || echo "0")

        if [[ "$behind_count" -gt 0 ]]; then
            echo ""
            echo "Changes available: $behind_count commit(s)"
            git log --oneline HEAD..origin/$current_branch 2>/dev/null | head -10 || true
        else
            echo ""
            echo "Already up to date."
        fi
    else
        echo ""
        echo "Fetching updates..."
        git fetch --all --tags

        echo "Pulling changes..."
        if git pull origin "$current_branch"; then
            new_commit=$(git rev-parse --short HEAD)
            echo ""
            echo "✓ Successfully upgraded!"
            echo "  Previous: $current_commit"
            echo "  Current:  $new_commit"
        else
            echo ""
            echo "✗ Upgrade failed. You may need to resolve conflicts manually."
            exit 1
        fi
    fi
}

upgrade_marketplace_plugin() {
    local plugin_id="$1"
    local plugin_path="$2"
    local current_version="$3"
    local dry_run="$4"

    echo "Marketplace plugin: $PLUGIN_NAME"
    echo "Plugin ID: $plugin_id"
    echo "Current version: $current_version"
    echo "Marketplace: $PLUGIN_MARKETPLACE"
    echo ""

    if [[ "$dry_run" == "--dry-run" ]]; then
        echo "[DRY RUN] Would execute:"
        echo "  claude plugin update \"$plugin_id\""
    else
        echo "Updating marketplace plugin..."
        if claude plugin update "$plugin_id" 2>&1; then
            echo ""
            echo "✓ Update command executed successfully."
            echo "  Restart Claude Code to apply changes."
        else
            echo ""
            echo "✗ Update failed. Try running manually:"
            echo "  claude plugin update \"$plugin_id\""
            exit 1
        fi
    fi
}

# Main logic
case "$SOURCE" in
    "git")
        upgrade_git_plugin "$PLUGIN_PATH" "$DRY_RUN"
        ;;
    "marketplace")
        upgrade_marketplace_plugin "$PLUGIN_ID" "$PLUGIN_PATH" "$PLUGIN_VERSION" "$DRY_RUN"
        ;;
    "local")
        echo "Plugin '$PLUGIN_NAME' is a local plugin (no Git repository)."
        echo "Path: $PLUGIN_PATH"
        echo ""
        echo "Local plugins cannot be automatically upgraded."
        echo "Please update the files manually."
        ;;
    *)
        echo "Unknown plugin source type: $SOURCE"
        exit 1
        ;;
esac
