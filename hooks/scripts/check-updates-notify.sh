#!/bin/bash
# Check for plugin updates and output notification message
# Used by SessionStart hook to notify user of available updates

set -e

PLUGINS_DIR="${HOME}/.claude/plugins"
SETTINGS_FILE="${HOME}/.claude/plugin-upgrade.local.md"

# Check if auto-check is disabled in settings
if [[ -f "$SETTINGS_FILE" ]]; then
    if grep -qi "enabled:[[:space:]]*false" "$SETTINGS_FILE" 2>/dev/null; then
        # Auto-check disabled, exit silently
        exit 0
    fi
fi

# Count plugins with updates available
count_updates() {
    local count=0

    # Check Git-based plugins
    for plugin_dir in "$PLUGINS_DIR"/*/; do
        # Skip cache directory
        if [[ "$plugin_dir" == *"/cache/" ]]; then
            continue
        fi

        # Check if it's a git repository
        if [[ -d "${plugin_dir}.git" ]]; then
            # Fetch quietly and check for updates
            (cd "$plugin_dir" && git fetch --quiet 2>/dev/null) || continue

            current_branch=$(cd "$plugin_dir" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
            local_commit=$(cd "$plugin_dir" && git rev-parse HEAD 2>/dev/null || echo "")
            remote_commit=$(cd "$plugin_dir" && git rev-parse "origin/$current_branch" 2>/dev/null || echo "")

            if [[ -n "$local_commit" && -n "$remote_commit" && "$local_commit" != "$remote_commit" ]]; then
                count=$((count + 1))
            fi
        fi
    done

    echo "$count"
}

# Get update count
UPDATE_COUNT=$(count_updates)

# Only output if updates are available
if [[ "$UPDATE_COUNT" -gt 0 ]]; then
    if [[ "$UPDATE_COUNT" -eq 1 ]]; then
        echo "📦 1 plugin has updates available. Run /plugin-upgrade:upgrade to update."
    else
        echo "📦 $UPDATE_COUNT plugins have updates available. Run /plugin-upgrade:upgrade to update."
    fi
fi

exit 0
