#!/usr/bin/env bash
set -euo pipefail

# Remove only the retired integration. Preserve permissions and other hooks.
LOCAL_SETTINGS="$HOME/.claude/settings.local.json"
[ -f "$LOCAL_SETTINGS" ] || exit 0
if [ -L "$LOCAL_SETTINGS" ]; then
  echo "Refusing to replace symlink: $LOCAL_SETTINGS" >&2
  exit 1
fi

FILTER='
  def bartender:
    (.type == "command") and
    ((.command // "") | contains("notchbar-agents-claude-hook") or
      contains("/Bartender/NotchBar/AgentStatus/hooks/claude-event-hook.sh"));
  if any(.hooks[]?.[]?.hooks[]?; bartender) then
    .hooks |= with_entries(
      .value |= map(
        if any(.hooks[]?; bartender) then
          .hooks |= map(select(bartender | not)) |
          select(.hooks | length > 0)
        else . end
      ) |
      select(.value | length > 0)
    ) |
    if .hooks == {} then del(.hooks) else . end
  else . end
'

# Compare parsed values before writing so repeat runs leave the file untouched.
original="$(jq -c . "$LOCAL_SETTINGS")"
updated="$(jq -c "$FILTER" "$LOCAL_SETTINGS")"
[ "$original" != "$updated" ] || exit 0

temporary="$(mktemp "${LOCAL_SETTINGS}.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
cp -p "$LOCAL_SETTINGS" "$temporary"
printf '%s\n' "$updated" | jq . > "$temporary"
mv "$temporary" "$LOCAL_SETTINGS"
echo "Removed Bartender hooks; preserved other local settings."
