# Claude Code Plugin Upgrader

A command-line tool written in Go to manage and upgrade Claude Code plugins installed on your local PC.

## Features

- 🔍 **List installed plugins**: Display all Claude Code plugins with their versions
- 🔄 **Upgrade plugins**: Update plugins to their latest versions
- 🎯 **Selective upgrade**: Upgrade specific plugins by name
- 🖥️ **Cross-platform**: Supports macOS, Linux, and Windows

## Installation

### From Source

```bash
git clone https://github.com/sontixyou/claude-code-plugin-upgrader.git
cd claude-code-plugin-upgrader
go build -o claude-plugin-upgrader
```

### Binary Installation

You can also download pre-built binaries from the releases page.

## Usage

### List Installed Plugins

To see all Claude Code plugins currently installed on your system:

```bash
./claude-plugin-upgrader -list
```

Example output:
```
Installed Claude Code plugins:
-------------------------------
Name:    @anthropic/claude-helper
Version: 1.2.3
Path:    /Users/username/.config/claude-code/extensions/@anthropic/claude-helper

Name:    my-custom-plugin
Version: 0.5.0
Path:    /Users/username/.config/claude-code/extensions/my-custom-plugin
```

### Upgrade All Plugins

To check and upgrade all installed plugins to their latest versions:

```bash
./claude-plugin-upgrader -upgrade
```

### Upgrade Specific Plugin

To upgrade a specific plugin by name:

```bash
./claude-plugin-upgrader -upgrade -plugin "@anthropic/claude-helper"
```

## Plugin Directory Locations

The tool automatically detects the plugin directory based on your operating system:

- **macOS**: `~/Library/Application Support/Claude Code/extensions`
- **Linux**: `~/.config/claude-code/extensions`
- **Windows**: `%APPDATA%/Claude Code/extensions`

## How It Works

1. **Discovery**: The tool scans the Claude Code extensions directory
2. **Version Check**: Reads `package.json` files to determine current versions
3. **Registry Query**: Checks npm registry or other sources for latest versions
4. **Upgrade**: Downloads and installs updated versions (when available)

## Development

### Requirements

- Go 1.19 or later

### Building

```bash
go build -o claude-plugin-upgrader
```

### Testing

```bash
go test ./...
```

## Supported Plugin Formats

Currently supports plugins that:
- Have a `package.json` file in their root directory
- Are available on npm registry (for version checking)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - See LICENSE file for details

## Notes

This tool is designed to work with Claude Code plugins. The upgrade functionality checks npm registry for version information. For plugins not available on npm, manual upgrade may be required.

## Troubleshooting

### No plugins found

If the tool reports no plugins found:
1. Verify Claude Code is installed on your system
2. Check that you have installed at least one plugin
3. Verify the plugin directory exists at the expected location

### Permission errors

If you encounter permission errors:
- Ensure you have read/write access to the Claude Code extensions directory
- On Unix systems, you may need to adjust file permissions

## Future Enhancements

- [ ] Support for downloading and installing plugins from marketplace
- [ ] Backup functionality before upgrades
- [ ] Rollback capability
- [ ] Configuration file support
- [ ] Interactive mode for selecting plugins to upgrade