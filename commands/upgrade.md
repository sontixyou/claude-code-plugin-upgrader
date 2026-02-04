---
description: Interactively select and upgrade multiple plugins (including marketplace plugins)
allowed-tools: Bash, Read, AskUserQuestion
---

Help the user interactively upgrade their Claude Code plugins, including marketplace plugins.

## Step 1: Gather Plugin Information

First, get the list of installed plugins with update information:
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/list-plugins-with-updates.sh 2>/dev/null || bash ${CLAUDE_PLUGIN_ROOT}/scripts/list-plugins.sh --check-updates`

## Step 2: Identify Upgradable Plugins

Analyze the output and identify plugins that can be upgraded:
- **Marketplace plugins**: Plugins managed by Claude Code that show "update available" status
- **Git plugins**: Plugins installed from Git repositories (if any)
- **Up to date**: Plugins where installed version matches latest version
- **Managed**: Plugins where version comparison is not available (still can try to update)

## Step 3: Present Options to User

If upgradable plugins are found (status is "update available" or user wants to check managed plugins), use AskUserQuestion to let the user select which plugins to upgrade.

Create a multi-select question with all upgradable plugins as options. For each plugin, show:
- Plugin name
- Current version → Latest version (if available)
- Marketplace name

Example format for options:
- Label: "plugin-name (v1.0.0 → v1.2.0)"
- Description: "Marketplace: claude-plugins-official"

Also include an option for "managed" plugins if the user wants to check for updates even without confirmed new versions.

## Step 4: Execute Upgrades

For each selected plugin, execute the upgrade using the plugin ID format (`name@marketplace`):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/upgrade-plugin.sh <plugin-name>@<marketplace>
```

Or for specific plugin ID:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/upgrade-plugin.sh <plugin-id>
```

Report progress for each plugin:
- Starting upgrade
- Success or failure
- Output from the update command

## Step 5: Summary

After all upgrades complete, provide a summary:
- Number of plugins upgraded successfully
- Any failures and suggested actions
- **IMPORTANT**: Remind user to restart Claude Code for changes to take effect

## Edge Cases

- **No plugins installed**: Inform user and suggest installing plugins
- **All plugins up to date**: Congratulate user and suggest using `/plugin-upgrade:check` periodically
- **User cancels selection**: Acknowledge and suggest running again when ready
- **Upgrade fails**: Show error details and suggest manual intervention with `claude plugin update <plugin-id>`
- **Managed plugins without version info**: Offer to try updating anyway as versions may be available on the marketplace
