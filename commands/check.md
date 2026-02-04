---
description: Check for available plugin updates
allowed-tools: Bash, Read
---

Check all installed Claude Code plugins for available updates.

Execute the update check script:
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/list-plugins.sh --check-updates`

Analyze the results and present:

1. **Plugins with updates available**: List each plugin that has a newer version, showing current version and latest version
2. **Up-to-date plugins**: Briefly mention how many plugins are already at their latest version
3. **Marketplace plugins**: Note that these are managed by Claude Code and can be updated via the marketplace

If updates are available, suggest running `/plugin-upgrade:upgrade` to interactively upgrade selected plugins.

If all plugins are up to date, congratulate the user on keeping their plugins current.
