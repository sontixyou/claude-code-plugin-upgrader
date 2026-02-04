#!/bin/bash
# List installed Claude Code plugins with update information from marketplace
# Usage: list-plugins-with-updates.sh [--json]

set -e

JSON_OUTPUT="${1:-}"
MARKETPLACES_DIR="${HOME}/.claude/plugins/marketplaces"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "Error: claude CLI not found" >&2
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq not found" >&2
    exit 1
fi

# Get plugin data from claude CLI
PLUGIN_DATA=$(claude plugin list --json 2>/dev/null)

if [[ -z "$PLUGIN_DATA" ]]; then
    echo "Error: Failed to get plugin list from claude CLI" >&2
    exit 1
fi

# Function to get latest version from marketplace cache
# Handles different marketplace structures:
# - <marketplace>/<plugin>/.claude-plugin/plugin.json
# - <marketplace>/plugins/<plugin>/.claude-plugin/plugin.json
# - <marketplace>/external_plugins/<plugin>/.claude-plugin/plugin.json
get_marketplace_version() {
    local plugin_name="$1"
    local marketplace="$2"
    local base_path="${MARKETPLACES_DIR}/${marketplace}"

    # Try different possible paths
    local paths=(
        "${base_path}/${plugin_name}/.claude-plugin/plugin.json"
        "${base_path}/plugins/${plugin_name}/.claude-plugin/plugin.json"
        "${base_path}/external_plugins/${plugin_name}/.claude-plugin/plugin.json"
    )

    for manifest_path in "${paths[@]}"; do
        if [[ -f "$manifest_path" ]]; then
            jq -r '.version // "unknown"' "$manifest_path" 2>/dev/null
            return
        fi
    done

    echo ""
}

# Process installed plugins and add marketplace version info
RESULT="[]"

while IFS= read -r plugin; do
    id=$(echo "$plugin" | jq -r '.id')
    version=$(echo "$plugin" | jq -r '.version // "unknown"')
    enabled=$(echo "$plugin" | jq -r '.enabled // true')

    # Parse plugin name and marketplace from id (format: name@marketplace)
    plugin_name="${id%@*}"
    marketplace="${id#*@}"

    # Get available version from marketplace cache
    available_version=$(get_marketplace_version "$plugin_name" "$marketplace")

    # Determine update status
    update_available="false"
    if [[ -n "$available_version" && "$available_version" != "unknown" && "$version" != "$available_version" ]]; then
        update_available="true"
    fi

    # Handle empty available version
    if [[ -z "$available_version" ]]; then
        available_json="null"
    else
        available_json="\"$available_version\""
    fi

    # Build JSON object
    plugin_json=$(cat <<EOF
{
    "id": "$id",
    "name": "$plugin_name",
    "marketplace": "$marketplace",
    "version": "$version",
    "availableVersion": $available_json,
    "enabled": $enabled,
    "updateAvailable": $update_available
}
EOF
)

    RESULT=$(echo "$RESULT" | jq --argjson p "$plugin_json" '. + [$p]')
done < <(echo "$PLUGIN_DATA" | jq -c '.[]')

# JSON output mode
if [[ "$JSON_OUTPUT" == "--json" ]]; then
    echo "$RESULT" | jq '.'
    exit 0
fi

# Table output mode
printf "%-35s %-15s %-15s %-25s %s\n" "PLUGIN" "VERSION" "LATEST" "MARKETPLACE" "STATUS"
printf "%-35s %-15s %-15s %-25s %s\n" "------" "-------" "------" "-----------" "------"

echo "$RESULT" | jq -r '.[] | [.name, .version, (.availableVersion // "-"), .marketplace, (.updateAvailable | tostring)] | @tsv' | while IFS=$'\t' read -r name version latest marketplace update_available; do
    # Determine status and display
    if [[ "$update_available" == "true" ]]; then
        status="${YELLOW}update available${NC}"
    elif [[ "$latest" != "-" && "$latest" != "null" ]]; then
        status="${GREEN}up to date${NC}"
    else
        status="${BLUE}managed${NC}"
    fi

    # Handle null latest version
    if [[ "$latest" == "null" ]]; then
        latest="-"
    fi

    printf "%-35s %-15s %-15s %-25s %b\n" "$name" "$version" "$latest" "$marketplace" "$status"
done
