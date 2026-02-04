# Plugin Upgrade

Claude Code プラグインを複数選択してアップグレードできるプラグインです。

## Features

- インストール済みプラグイン一覧: バージョン情報付きで表示
- 更新チェック: 最新バージョンとの比較
- 一括アップグレード: 対話形式で複数プラグインを選択してアップグレード
- マーケットプレイス更新: マーケットプレイス自体を対話形式でアップグレード
- 自動通知: セッション開始時に更新可能なプラグインを通知

## Commands

| コマンド | 説明 |
|---------|------|
| `/plugin-upgrade:upgrade` | 対話形式でプラグインを選択してアップグレード |
| `/plugin-upgrade:upgrade-marketplace` | 対話形式でマーケットプレイスを選択してアップグレード |
| `/plugin-upgrade:list` | インストール済みプラグインの一覧表示 |
| `/plugin-upgrade:check` | 更新可能なプラグインをチェック |

## Installation

### 1. マーケットプレイスを追加

```bash
/plugin marketplace add sontixyou/claude-code-plugin-upgrader
```

### 2. プラグインをインストール

```bash
/plugin install plugin-upgrade@plugin-upgrader
```

## Settings

`~/.claude/plugin-upgrade.local.md` で設定をカスタマイズできます：

```markdown
# Plugin Upgrade Settings

## Auto Check
enabled: true

## Excluded Plugins
- some-plugin-to-exclude
```

## Requirements

- Claude Code CLI
- Git (Git リポジトリからのアップグレード用)

## License

MIT
