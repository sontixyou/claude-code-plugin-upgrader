# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Claude Code プラグインを管理・アップグレードするためのプラグイン。インストール済みプラグインの一覧表示、更新チェック、対話形式での一括アップグレード機能を提供する。

## アーキテクチャ

```
claude-code-plugin-upgrader/
├── .claude-plugin/
│   ├── plugin.json          # プラグインメタデータ (name, version, etc.)
│   └── marketplace.json     # マーケットプレイス公開用定義
├── commands/                 # スラッシュコマンド定義 (Markdown)
│   ├── check.md             # /plugin-upgrade:check - 更新チェック
│   ├── list.md              # /plugin-upgrade:list - 一覧表示
│   ├── upgrade.md           # /plugin-upgrade:upgrade - 対話形式アップグレード
│   └── upgrade-marketplace.md # /plugin-upgrade:upgrade-marketplace - マーケットプレイス更新
├── scripts/                  # Bash スクリプト (コマンドから呼び出される)
│   ├── list-plugins.sh      # プラグイン一覧取得・更新チェック
│   └── upgrade-plugin.sh    # 個別プラグインのアップグレード実行
├── hooks/
│   ├── hooks.json           # SessionStart フックの定義
│   └── scripts/
│       └── check-updates-notify.sh  # セッション開始時の更新通知
└── skills/
    └── plugin-management/
        └── SKILL.md         # トラブルシューティングガイド
```

## コマンドとスクリプトの関係

- **commands/*.md**: Claude が解釈するワークフロー定義。`!` バッククォート記法でスクリプトを実行
- **scripts/*.sh**: 実際のシェル処理。`${CLAUDE_PLUGIN_ROOT}` 環境変数でプラグインルートを参照
- **hooks/**: SessionStart 時に `check-updates-notify.sh` が自動実行され、更新があればユーザーに通知

## プラグインソースの種類

スクリプトは3種類のプラグインソースを区別して処理:
1. **git**: `~/.claude/plugins/<name>/` にある Git リポジトリ → `git pull` で更新
2. **marketplace**: `~/.claude/plugins/cache/` 内 → Claude CLI で管理
3. **local**: Git なしのローカルディレクトリ → 自動更新不可

## 開発時の確認コマンド

```bash
# スクリプトの動作確認
bash scripts/list-plugins.sh
bash scripts/list-plugins.sh --check-updates
bash scripts/upgrade-plugin.sh <plugin-name> --dry-run

# フックスクリプトの確認
bash hooks/scripts/check-updates-notify.sh
```

## 設定ファイル

ユーザー設定は `~/.claude/plugin-upgrade.local.md` で管理。`enabled: false` で自動通知を無効化可能。
