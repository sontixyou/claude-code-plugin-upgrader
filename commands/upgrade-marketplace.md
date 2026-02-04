---
description: Interactively select and upgrade marketplaces
allowed-tools: Bash, AskUserQuestion
---

Help the user interactively upgrade their Claude Code marketplaces.

## Step 1: Get Marketplace List

First, get the list of configured marketplaces:
!`claude plugin marketplace list 2>/dev/null || echo "Error: Could not list marketplaces"`

## Step 2: Parse Marketplace Information

From the output, identify each marketplace:
- Name (e.g., "claude-plugins-official")
- Source (e.g., "GitHub (anthropics/claude-plugins-official)" or "Git (https://...)")

## Step 3: Present Options to User

Use AskUserQuestion to let the user select which marketplaces to update.

Create a multi-select question with all marketplaces as options:
- Label: marketplace name
- Description: source information

## Step 4: Execute Updates

For each selected marketplace, execute the update:

```bash
claude plugin marketplace update <marketplace-name>
```

Report progress for each marketplace:
- Starting update
- Success or failure
- Any errors encountered

## Step 5: Summary

After all updates complete, provide a summary:
- Number of marketplaces updated successfully
- Any failures and error details
- Reminder that plugins using updated marketplaces may have new versions available
- Suggest running `/plugin-upgrade:check` to see if any plugin updates are available

## Edge Cases

- **No marketplaces configured**: Inform user and suggest adding a marketplace with `claude plugin marketplace add`
- **User cancels selection**: Acknowledge and suggest running again when ready
- **Update fails**: Show error details and suggest checking network connectivity or marketplace source
