#!/bin/bash
# Upgrade a single Claude Code plugin
# Usage: upgrade-plugin.sh <plugin-name> [--dry-run]

set -e

PLUGIN_NAME="$1"
DRY_RUN="${2:-}"
PLUGINS_DIR="${HOME}/.claude/plugins"

if [[ -z "$PLUGIN_NAME" ]]; then
    echo "Error: Plugin name required"
    echo "Usage: upgrade-plugin.sh <plugin-name> [--dry-run]"
    exit 1
fi

# Find plugin directory
find_plugin_dir() {
    local name="$1"

    # Check direct plugin directory
    if [[ -d "${PLUGINS_DIR}/${name}" ]]; then
        echo "${PLUGINS_DIR}/${name}"
        return
    fi

    # Check cache directory
    for source_dir in "${PLUGINS_DIR}/cache"/*/; do
        if [[ -d "${source_dir}${name}" ]]; then
            # Find nested directory with actual plugin
            for nested in "${source_dir}${name}"/*/; do
                if [[ -d "${nested}.claude-plugin" ]]; then
                    echo "$nested"
                    return
                fi
            done
        fi
    done

    echo ""
}

get_plugin_source() {
    local plugin_path="$1"

    if [[ "$plugin_path" == *"/cache/claude-plugins-official/"* ]]; then
        echo "marketplace"
        return
    fi

    if [[ -d "${plugin_path}/.git" ]]; then
        echo "git"
        return
    fi

    echo "local"
}

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
    local plugin_path="$1"
    local dry_run="$2"

    echo "Marketplace plugin: $PLUGIN_NAME"
    echo "Path: $plugin_path"
    echo ""

    if [[ "$dry_run" == "--dry-run" ]]; then
        echo "[DRY RUN] Marketplace plugins are managed by Claude Code."
        echo "To upgrade, use: claude plugins update $PLUGIN_NAME"
    else
        echo "Marketplace plugins are managed by Claude Code."
        echo "To upgrade, use: claude plugins update $PLUGIN_NAME"
        echo ""
        echo "Attempting to trigger update..."
        if command -v claude &> /dev/null; then
            claude plugins update "$PLUGIN_NAME" 2>/dev/null || echo "Note: Please run 'claude plugins update $PLUGIN_NAME' manually if update fails."
        else
            echo "Claude CLI not found. Please update manually."
        fi
    fi
}

# Main logic
PLUGIN_DIR=$(find_plugin_dir "$PLUGIN_NAME")

if [[ -z "$PLUGIN_DIR" ]]; then
    echo "Error: Plugin '$PLUGIN_NAME' not found"
    echo ""
    echo "Installed plugins:"
    bash "${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}/scripts/list-plugins.sh" 2>/dev/null | tail -n +3 | awk '{print "  - " $1}' || ls -1 "$PLUGINS_DIR" 2>/dev/null | grep -v cache | sed 's/^/  - /'
    exit 1
fi

SOURCE=$(get_plugin_source "$PLUGIN_DIR")

case "$SOURCE" in
    "git")
        upgrade_git_plugin "$PLUGIN_DIR" "$DRY_RUN"
        ;;
    "marketplace")
        upgrade_marketplace_plugin "$PLUGIN_DIR" "$DRY_RUN"
        ;;
    "local")
        echo "Plugin '$PLUGIN_NAME' is a local plugin (no Git repository)."
        echo "Path: $PLUGIN_DIR"
        echo ""
        echo "Local plugins cannot be automatically upgraded."
        echo "Please update the files manually."
        ;;
    *)
        echo "Unknown plugin source type: $SOURCE"
        exit 1
        ;;
esac
