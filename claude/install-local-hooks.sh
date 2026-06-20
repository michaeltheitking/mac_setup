#!/usr/bin/env bash
set -euo pipefail

# Per-machine Claude Code settings that must NOT be committed/symlinked:
#   - Bartender NotchBar "AgentStatus" hooks (machine-specific app paths)
#   - local permission allowlist
#
# Claude merges ~/.claude/settings.local.json over the shared settings.json.
# This file is intentionally created in place (not symlinked) and is covered by
# the global gitignore rule **/.claude/settings.local.json.
#
# Idempotent: skips if the file already exists so local edits are preserved.

LOCAL_SETTINGS="$HOME/.claude/settings.local.json"
BARTENDER_HOOK="$HOME/Library/Application Support/Bartender/NotchBar/AgentStatus/hooks/claude-event-hook.sh"

mkdir -p "$HOME/.claude"

if [ -f "$LOCAL_SETTINGS" ]; then
  echo "settings.local.json already exists, leaving it untouched: $LOCAL_SETTINGS"
  exit 0
fi

cat > "$LOCAL_SETTINGS" <<JSON
{
  "permissions": {
    "allow": [
      "Bash(brew search *)",
      "Bash(git add *)",
      "Bash(git commit -m ' *)",
      "Bash(git push *)",
      "mcp__claude_ai_Notion__notion-fetch",
      "mcp__claude_ai_Notion__notion-update-page",
      "Bash(claude --version)",
      "Bash(npm view *)"
    ]
  },
  "hooks": {
    "Notification": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Waiting # notchbar-agents-claude-hook" } ] }
    ],
    "PostToolUse": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Auto # notchbar-agents-claude-hook" } ] }
    ],
    "PostToolUseFailure": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' ToolFail # notchbar-agents-claude-hook" } ] }
    ],
    "PreToolUse": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Working # notchbar-agents-claude-hook" } ] }
    ],
    "SessionEnd": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Ended # notchbar-agents-claude-hook" } ] }
    ],
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Idle # notchbar-agents-claude-hook" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Idle # notchbar-agents-claude-hook" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "'$BARTENDER_HOOK' Working # notchbar-agents-claude-hook" } ] }
    ]
  }
}
JSON

echo "Created $LOCAL_SETTINGS"
