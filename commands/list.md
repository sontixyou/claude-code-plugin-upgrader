---
description: List all installed Claude Code plugins with version information
allowed-tools: Bash, Read
---

List all installed Claude Code plugins with their version information.

Execute the plugin listing script:
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/list-plugins.sh`

Present the results in a clear, formatted table showing:
- Plugin name
- Current version
- Source (git, marketplace, local)
- Installation path

If no plugins are found, inform the user that no plugins are installed and suggest how to install plugins using Claude Code.
