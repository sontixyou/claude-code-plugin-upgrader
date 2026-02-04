---
description: Interactively select and upgrade multiple plugins
allowed-tools: Bash, Read, AskUserQuestion
---

Help the user interactively upgrade their Claude Code plugins.

## Step 1: Gather Plugin Information

First, get the list of installed plugins and check for updates:
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/list-plugins.sh --check-updates 2>/dev/null || bash ${CLAUDE_PLUGIN_ROOT}/scripts/list-plugins.sh`

## Step 2: Identify Upgradable Plugins

Analyze the output and identify:
- **Git plugins**: Plugins installed from Git repositories that can be upgraded via `git pull`
- **Marketplace plugins**: Plugins managed by Claude Code (note: these use Claude's built-in update mechanism)
- **Local plugins**: Cannot be automatically upgraded

## Step 3: Present Options to User

If upgradable plugins are found, use AskUserQuestion to let the user select which plugins to upgrade.

Create a multi-select question with all upgradable plugins as options. For each plugin, show:
- Plugin name
- Current version
- Latest version (if available)
- Source type (git/marketplace)

Example format for options:
- Label: "plugin-name (v1.0.0 → v1.2.0)"
- Description: "Git repository plugin - 2 commits behind"

## Step 4: Execute Upgrades

For each selected plugin, execute the upgrade:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/upgrade-plugin.sh <plugin-name>
```

Report progress for each plugin:
- Starting upgrade
- Success or failure
- New version (if successful)

## Step 5: Summary

After all upgrades complete, provide a summary:
- Number of plugins upgraded successfully
- Any failures and suggested actions
- Reminder to restart Claude Code if needed for changes to take effect

## Edge Cases

- **No plugins installed**: Inform user and suggest installing plugins
- **All plugins up to date**: Congratulate user and suggest using `/plugin-upgrade:check` periodically
- **User cancels selection**: Acknowledge and suggest running again when ready
- **Upgrade fails**: Show error details and suggest manual intervention
