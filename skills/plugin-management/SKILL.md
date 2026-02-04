---
name: Plugin Management
description: Use this skill when the user asks about "plugin management", "plugin upgrade issues", "plugin troubleshooting", "plugin version", "plugin not working after upgrade", "rollback plugin", "downgrade plugin", or has problems with Claude Code plugins. Provides guidance on managing, upgrading, and troubleshooting Claude Code plugins.
version: 0.1.0
---

# Plugin Management for Claude Code

## Overview

This skill provides guidance for managing Claude Code plugins, including installation, upgrading, troubleshooting, and best practices.

## Plugin Locations

Claude Code plugins are stored in these locations:

| Location | Description |
|----------|-------------|
| `~/.claude/plugins/` | User-installed plugins |
| `~/.claude/plugins/cache/` | Marketplace plugins (managed by Claude Code) |
| `.claude-plugin/` | Project-local plugins |

## Plugin Types by Source

### Git Repository Plugins

Plugins installed from Git repositories:
- Can be upgraded using `git pull`
- Support version tags
- May have upstream changes

**Upgrade method:**
```bash
cd ~/.claude/plugins/<plugin-name>
git fetch --all
git pull origin main
```

### Marketplace Plugins

Official plugins from Claude Code marketplace:
- Managed by Claude Code
- Located in `~/.claude/plugins/cache/claude-plugins-official/`
- Upgrade via Claude CLI: `claude plugins update <plugin-name>`

### Local Plugins

Plugins created or copied locally:
- No automatic upgrade path
- Must be updated manually
- Check plugin repository for updates

## Troubleshooting

### Plugin Not Loading

1. **Check plugin structure:**
   - Verify `.claude-plugin/plugin.json` exists
   - Confirm JSON syntax is valid
   - Check `name` field is present

2. **Verify installation:**
   ```bash
   ls -la ~/.claude/plugins/<plugin-name>/
   cat ~/.claude/plugins/<plugin-name>/.claude-plugin/plugin.json
   ```

3. **Check Claude Code logs:**
   ```bash
   claude --debug
   ```

### Plugin Broken After Upgrade

1. **Check for breaking changes:**
   - Read plugin's CHANGELOG or release notes
   - Check if dependencies updated

2. **Rollback to previous version:**
   ```bash
   cd ~/.claude/plugins/<plugin-name>
   git log --oneline  # Find previous commit
   git checkout <commit-hash>
   ```

3. **Or checkout specific tag:**
   ```bash
   git tag -l  # List available tags
   git checkout v1.0.0  # Checkout stable version
   ```

### Commands Not Appearing

1. **Check command file location:**
   - Commands must be in `commands/` directory
   - Files must have `.md` extension

2. **Verify YAML frontmatter:**
   ```yaml
   ---
   description: Command description
   ---
   ```

3. **Restart Claude Code:**
   - Exit current session
   - Start new session

### Hooks Not Executing

1. **Verify hooks.json syntax:**
   ```bash
   cat ~/.claude/plugins/<plugin-name>/hooks/hooks.json | jq .
   ```

2. **Check hook scripts are executable:**
   ```bash
   chmod +x ~/.claude/plugins/<plugin-name>/hooks/scripts/*.sh
   ```

3. **Test hooks with debug mode:**
   ```bash
   claude --debug
   ```

## Upgrade Strategies

### Conservative Upgrade

Upgrade one plugin at a time, test after each:
1. Check for updates: `/plugin-upgrade:check`
2. Read release notes
3. Upgrade single plugin
4. Test plugin functionality
5. Proceed to next plugin

### Batch Upgrade

Upgrade multiple plugins at once:
1. Check for updates: `/plugin-upgrade:check`
2. Review all changes available
3. Use `/plugin-upgrade:upgrade` to select multiple
4. Test all upgraded plugins

### Rollback Plan

Before upgrading, prepare rollback:
1. Note current versions
2. For Git plugins, note current commit hash
3. After upgrade, if issues occur, rollback immediately

## Best Practices

### Before Upgrading

- Read release notes or CHANGELOG
- Check for breaking changes
- Backup custom configurations
- Note current working version

### After Upgrading

- Restart Claude Code session
- Test core plugin functionality
- Check for deprecation warnings
- Update any dependent configurations

### Regular Maintenance

- Check for updates periodically
- Keep plugins reasonably current
- Remove unused plugins
- Document custom plugin modifications

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| "Plugin not found" | Check plugin directory exists and has valid plugin.json |
| "Command not recognized" | Restart Claude Code, verify command file exists |
| "Hook timeout" | Increase timeout in hooks.json or optimize hook script |
| "Git pull failed" | Check for local changes, try `git stash` first |
| "Permission denied" | Run `chmod +x` on script files |

## Getting Help

If you encounter persistent issues:
1. Check plugin's GitHub issues
2. Review plugin documentation
3. Use `claude --debug` for detailed logs
4. Contact plugin maintainer
