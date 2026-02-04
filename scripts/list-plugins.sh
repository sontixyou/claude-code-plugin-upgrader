#!/bin/bash
# List installed Claude Code plugins with version information
# Usage: list-plugins.sh [--check-updates]

set -e

PLUGINS_DIR="${HOME}/.claude/plugins"
CACHE_DIR="${PLUGINS_DIR}/cache"
CHECK_UPDATES="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

get_plugin_version() {
    local plugin_path="$1"
    local manifest="${plugin_path}/.claude-plugin/plugin.json"

    if [[ -f "$manifest" ]]; then
        version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" 2>/dev/null | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        if [[ -n "$version" ]]; then
            echo "$version"
            return
        fi
    fi

    # Try to get version from git tag
    if [[ -d "${plugin_path}/.git" ]]; then
        git_version=$(cd "$plugin_path" && git describe --tags --abbrev=0 2>/dev/null || echo "")
        if [[ -n "$git_version" ]]; then
            echo "$git_version"
            return
        fi
    fi

    echo "unknown"
}

get_plugin_source() {
    local plugin_path="$1"

    # Check if it's from official marketplace (in cache directory)
    if [[ "$plugin_path" == *"/cache/claude-plugins-official/"* ]]; then
        echo "marketplace"
        return
    fi

    # Check if it's a git repository
    if [[ -d "${plugin_path}/.git" ]]; then
        remote_url=$(cd "$plugin_path" && git remote get-url origin 2>/dev/null || echo "")
        if [[ -n "$remote_url" ]]; then
            echo "git"
            return
        fi
    fi

    echo "local"
}

get_latest_version_git() {
    local plugin_path="$1"

    if [[ ! -d "${plugin_path}/.git" ]]; then
        echo ""
        return
    fi

    # Fetch latest tags quietly
    (cd "$plugin_path" && git fetch --tags --quiet 2>/dev/null) || true

    # Get latest tag
    latest_tag=$(cd "$plugin_path" && git describe --tags --abbrev=0 origin/HEAD 2>/dev/null || git tag --sort=-v:refname | head -1 2>/dev/null || echo "")

    if [[ -n "$latest_tag" ]]; then
        echo "$latest_tag"
    else
        # Check if there are new commits
        local_commit=$(cd "$plugin_path" && git rev-parse HEAD 2>/dev/null || echo "")
        remote_commit=$(cd "$plugin_path" && git rev-parse origin/HEAD 2>/dev/null || git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null || echo "")

        if [[ -n "$local_commit" && -n "$remote_commit" && "$local_commit" != "$remote_commit" ]]; then
            echo "new-commits"
        fi
    fi
}

check_updates_available() {
    local plugin_path="$1"
    local current_version="$2"
    local source="$3"

    case "$source" in
        "git")
            latest=$(get_latest_version_git "$plugin_path")
            if [[ -n "$latest" && "$latest" != "$current_version" ]]; then
                echo "$latest"
            fi
            ;;
        "marketplace")
            # For marketplace plugins, we would need to check the marketplace API
            # For now, return empty (future enhancement)
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# Output header
if [[ "$CHECK_UPDATES" == "--check-updates" ]]; then
    printf "%-30s %-15s %-15s %-12s %s\n" "PLUGIN" "VERSION" "LATEST" "SOURCE" "STATUS"
    printf "%-30s %-15s %-15s %-12s %s\n" "------" "-------" "------" "------" "------"
else
    printf "%-30s %-15s %-12s %s\n" "PLUGIN" "VERSION" "SOURCE" "PATH"
    printf "%-30s %-15s %-12s %s\n" "------" "-------" "------" "----"
fi

# List plugins from main plugins directory (excluding cache)
for plugin_dir in "$PLUGINS_DIR"/*/; do
    # Skip if it's the cache directory
    if [[ "$plugin_dir" == *"/cache/" ]]; then
        continue
    fi

    # Check if it's a valid plugin (has .claude-plugin or plugin.json)
    if [[ ! -d "${plugin_dir}.claude-plugin" && ! -f "${plugin_dir}plugin.json" ]]; then
        continue
    fi

    plugin_name=$(basename "$plugin_dir")
    version=$(get_plugin_version "$plugin_dir")
    source=$(get_plugin_source "$plugin_dir")

    if [[ "$CHECK_UPDATES" == "--check-updates" ]]; then
        latest=$(check_updates_available "$plugin_dir" "$version" "$source")
        if [[ -n "$latest" ]]; then
            status="${YELLOW}update available${NC}"
            printf "%-30s %-15s %-15s %-12s %b\n" "$plugin_name" "$version" "$latest" "$source" "$status"
        else
            status="${GREEN}up to date${NC}"
            printf "%-30s %-15s %-15s %-12s %b\n" "$plugin_name" "$version" "-" "$source" "$status"
        fi
    else
        printf "%-30s %-15s %-12s %s\n" "$plugin_name" "$version" "$source" "$plugin_dir"
    fi
done

# List plugins from cache directory (marketplace plugins)
if [[ -d "$CACHE_DIR" ]]; then
    for source_dir in "$CACHE_DIR"/*/; do
        source_name=$(basename "$source_dir")
        for plugin_dir in "$source_dir"/*/; do
            if [[ ! -d "$plugin_dir" ]]; then
                continue
            fi

            # Find the actual plugin directory (might be nested with hash)
            for nested_dir in "$plugin_dir"/*/; do
                if [[ -d "${nested_dir}.claude-plugin" || -f "${nested_dir}plugin.json" ]]; then
                    plugin_name=$(basename "$plugin_dir")
                    version=$(get_plugin_version "$nested_dir")

                    if [[ "$CHECK_UPDATES" == "--check-updates" ]]; then
                        printf "%-30s %-15s %-15s %-12s %b\n" "$plugin_name" "$version" "-" "marketplace" "${GREEN}managed${NC}"
                    else
                        printf "%-30s %-15s %-12s %s\n" "$plugin_name" "$version" "marketplace" "$nested_dir"
                    fi
                    break
                fi
            done
        done
    done
fi
