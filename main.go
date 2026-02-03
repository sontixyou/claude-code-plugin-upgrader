package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

const (
	pluginDirName = ".claude-code"
	pluginSubDir  = "extensions"
)

type PluginInfo struct {
	Name    string `json:"name"`
	Version string `json:"version"`
	Path    string `json:"-"`
}

type MarketplacePlugin struct {
	Name        string `json:"name"`
	Version     string `json:"version"`
	DownloadURL string `json:"downloadUrl"`
}

func main() {
	listFlag := flag.Bool("list", false, "List all installed Claude Code plugins")
	upgradeFlag := flag.Bool("upgrade", false, "Upgrade all plugins to latest versions")
	pluginName := flag.String("plugin", "", "Specific plugin name to upgrade")
	flag.Parse()

	if *listFlag {
		listPlugins()
		return
	}

	if *upgradeFlag {
		if *pluginName != "" {
			upgradePlugin(*pluginName)
		} else {
			upgradeAllPlugins()
		}
		return
	}

	flag.Usage()
}

func getPluginDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	var pluginPath string
	switch runtime.GOOS {
	case "darwin":
		// macOS: ~/Library/Application Support/Claude Code/extensions
		pluginPath = filepath.Join(homeDir, "Library", "Application Support", "Claude Code", pluginSubDir)
	case "linux":
		// Linux: ~/.config/claude-code/extensions
		pluginPath = filepath.Join(homeDir, ".config", "claude-code", pluginSubDir)
	case "windows":
		// Windows: %APPDATA%/Claude Code/extensions
		appData := os.Getenv("APPDATA")
		if appData == "" {
			appData = filepath.Join(homeDir, "AppData", "Roaming")
		}
		pluginPath = filepath.Join(appData, "Claude Code", pluginSubDir)
	default:
		// Fallback
		pluginPath = filepath.Join(homeDir, ".claude-code", pluginSubDir)
	}

	return pluginPath, nil
}

func listPlugins() {
	pluginDir, err := getPluginDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	plugins, err := discoverPlugins(pluginDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering plugins: %v\n", err)
		os.Exit(1)
	}

	if len(plugins) == 0 {
		fmt.Println("No Claude Code plugins found.")
		fmt.Printf("Plugin directory: %s\n", pluginDir)
		return
	}

	fmt.Println("Installed Claude Code plugins:")
	fmt.Println("-------------------------------")
	for _, plugin := range plugins {
		fmt.Printf("Name:    %s\n", plugin.Name)
		fmt.Printf("Version: %s\n", plugin.Version)
		fmt.Printf("Path:    %s\n", plugin.Path)
		fmt.Println()
	}
}

func discoverPlugins(pluginDir string) ([]PluginInfo, error) {
	var plugins []PluginInfo

	if _, err := os.Stat(pluginDir); os.IsNotExist(err) {
		return plugins, nil
	}

	entries, err := os.ReadDir(pluginDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read plugin directory: %w", err)
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		pluginPath := filepath.Join(pluginDir, entry.Name())
		packageJSONPath := filepath.Join(pluginPath, "package.json")

		if _, err := os.Stat(packageJSONPath); err == nil {
			plugin, err := readPluginInfo(packageJSONPath, pluginPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Warning: failed to read plugin info for %s: %v\n", entry.Name(), err)
				continue
			}
			plugins = append(plugins, plugin)
		}
	}

	return plugins, nil
}

func readPluginInfo(packageJSONPath, pluginPath string) (PluginInfo, error) {
	var plugin PluginInfo

	data, err := os.ReadFile(packageJSONPath)
	if err != nil {
		return plugin, fmt.Errorf("failed to read package.json: %w", err)
	}

	var packageJSON map[string]interface{}
	if err := json.Unmarshal(data, &packageJSON); err != nil {
		return plugin, fmt.Errorf("failed to parse package.json: %w", err)
	}

	if name, ok := packageJSON["name"].(string); ok {
		plugin.Name = name
	}

	if version, ok := packageJSON["version"].(string); ok {
		plugin.Version = version
	}

	plugin.Path = pluginPath

	return plugin, nil
}

func upgradeAllPlugins() {
	pluginDir, err := getPluginDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	plugins, err := discoverPlugins(pluginDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering plugins: %v\n", err)
		os.Exit(1)
	}

	if len(plugins) == 0 {
		fmt.Println("No Claude Code plugins found to upgrade.")
		return
	}

	fmt.Printf("Found %d plugin(s) to check for updates...\n\n", len(plugins))

	for _, plugin := range plugins {
		fmt.Printf("Checking %s...\n", plugin.Name)
		if err := upgradePluginByInfo(plugin); err != nil {
			fmt.Fprintf(os.Stderr, "Failed to upgrade %s: %v\n", plugin.Name, err)
		}
		fmt.Println()
	}
}

func upgradePlugin(name string) {
	pluginDir, err := getPluginDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	plugins, err := discoverPlugins(pluginDir)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error discovering plugins: %v\n", err)
		os.Exit(1)
	}

	for _, plugin := range plugins {
		if strings.EqualFold(plugin.Name, name) {
			fmt.Printf("Upgrading %s...\n", plugin.Name)
			if err := upgradePluginByInfo(plugin); err != nil {
				fmt.Fprintf(os.Stderr, "Failed to upgrade %s: %v\n", plugin.Name, err)
				os.Exit(1)
			}
			return
		}
	}

	fmt.Fprintf(os.Stderr, "Plugin '%s' not found.\n", name)
	os.Exit(1)
}

func upgradePluginByInfo(plugin PluginInfo) error {
	// Check for updates (this is a simplified version)
	// In a real implementation, this would query a marketplace or registry
	fmt.Printf("  Current version: %s\n", plugin.Version)

	// Simulate checking for updates
	// In a real implementation, you would:
	// 1. Query a package registry or marketplace API
	// 2. Compare versions
	// 3. Download and install if newer version available

	latestVersion, err := checkLatestVersion(plugin.Name)
	if err != nil {
		return fmt.Errorf("failed to check latest version: %w", err)
	}

	if latestVersion == "" {
		fmt.Println("  No update information available (plugin may not be in registry)")
		return nil
	}

	if latestVersion == plugin.Version {
		fmt.Println("  Already up to date!")
		return nil
	}

	fmt.Printf("  Latest version: %s\n", latestVersion)
	fmt.Println("  Upgrade functionality would be implemented here")
	fmt.Println("  (downloading and installing new version)")

	return nil
}

func checkLatestVersion(pluginName string) (string, error) {
	// This is a placeholder implementation
	// In a real scenario, you would query:
	// - VSCode Marketplace API
	// - npm registry (if plugins are npm packages)
	// - A custom Claude Code plugin registry
	// - GitHub releases API

	// For demonstration, we'll check if it's an npm package
	if strings.HasPrefix(pluginName, "@") || !strings.Contains(pluginName, "/") {
		return checkNpmVersion(pluginName)
	}

	return "", nil
}

func checkNpmVersion(packageName string) (string, error) {
	url := fmt.Sprintf("https://registry.npmjs.org/%s", packageName)

	resp, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 404 {
		return "", nil
	}

	if resp.StatusCode != 200 {
		return "", fmt.Errorf("npm registry returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var npmData map[string]interface{}
	if err := json.Unmarshal(body, &npmData); err != nil {
		return "", err
	}

	if distTags, ok := npmData["dist-tags"].(map[string]interface{}); ok {
		if latest, ok := distTags["latest"].(string); ok {
			return latest, nil
		}
	}

	return "", nil
}
