#!/bin/sh
input=$(cat)

# Parse every field in one jq pass (this script re-renders constantly).
# One value per line; empty fields stay empty (unlike collapsing tab/IFS splits).
{
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r used
  IFS= read -r worktree
  IFS= read -r current_dir
  IFS= read -r rl_5h_pct
  IFS= read -r rl_5h_reset
  IFS= read -r rl_7d_pct
  IFS= read -r rl_7d_reset
} <<EOF
$(printf '%s' "$input" | jq -r '[
  .model.display_name // "Unknown Model",
  .effort.level // "",
  .context_window.used_percentage // "",
  .worktree.name // "",
  .worktree.original_cwd // "",
  .rate_limits.five_hour.used_percentage // "",
  .rate_limits.five_hour.resets_at // "",
  .rate_limits.seven_day.used_percentage // "",
  .rate_limits.seven_day.resets_at // ""
] | .[]')
EOF

[ -n "$rl_5h_pct" ] && rl_5h_pct=$(printf "%.0f" "$rl_5h_pct")
[ -n "$rl_7d_pct" ] && rl_7d_pct=$(printf "%.0f" "$rl_7d_pct")

if [ -n "$used" ]; then
  used_pct=$(printf "%.0f" "$used")
else
  used_pct=0
fi

if [ -n "$worktree" ]; then
  worktree_str="${worktree}"
else
  worktree_str="no worktree"
fi

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

git_str=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  staged=$(git diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git diff --numstat 2>/dev/null | wc -l | tr -d ' ')

  git_str="$branch"
  [ "$staged" -gt 0 ] && git_str="${git_str} $(printf "${GREEN}+${staged}${RESET}")"
  [ "$modified" -gt 0 ] && git_str="${git_str} $(printf "${YELLOW}~${modified}${RESET}")"
else
  git_str="no branch"
fi

make_bar() {
  pct="$1"
  width=10
  filled=$(( pct * width / 100 ))
  empty=$(( width - filled ))
  bar=""
  i=0
  while [ $i -lt $filled ]; do bar="${bar}█"; i=$(( i + 1 )); done
  while [ $i -lt $width ]; do bar="${bar}░"; i=$(( i + 1 )); done
  printf "%s" "$bar"
}

pct_color() {
  if [ "$1" -ge 90 ]; then printf "%s" "$RED"
  elif [ "$1" -ge 70 ]; then printf "%s" "$YELLOW"
  else printf "%s" "$GREEN"
  fi
}

usage_str=$(printf "$(pct_color "$used_pct")$(make_bar "$used_pct") ${used_pct}%%${RESET}")

rate_limit_str=""
if [ -n "$rl_5h_pct" ]; then
  reset_5h=$(date -r "$rl_5h_reset" "+%-I:%M%p" 2>/dev/null || date -d "@$rl_5h_reset" "+%-I:%M%p" 2>/dev/null)
  rate_limit_str=$(printf "$(pct_color "$rl_5h_pct")${rl_5h_pct}%% resets ${reset_5h}${RESET}")
fi

week_str=""
[ -n "$rl_7d_pct" ] && week_str=$(printf "🌐 $(pct_color "$rl_7d_pct")${rl_7d_pct}%%${RESET}")

repo_root=$(cd "$current_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "$current_dir")
dir_display=$(basename "$repo_root")

if [ -n "$effort" ]; then
  printf "🤖 %s | 💪 %s | 🧠 %s | ⏱️ %s | %s\n📁 %s | 🌳 %s | 🌿 %s" "$model" "$effort" "$usage_str" "$rate_limit_str" "$week_str" "$dir_display" "$worktree_str" "$git_str"
else
  printf "🤖 %s | 🧠 %s | ⏱️ %s | %s\n📁 %s | 🌳 %s | 🌿 %s" "$model" "$usage_str" "$rate_limit_str" "$week_str" "$dir_display" "$worktree_str" "$git_str"
fi
