#!/bin/sh
input=$(cat)

# Parse every field in one jq pass (this script re-renders constantly).
# One value per line; empty fields stay empty (unlike collapsing tab/IFS splits).
{
  IFS= read -r model
  IFS= read -r effort
  IFS= read -r used
  IFS= read -r worktree
  IFS= read -r total_cost
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
  .cost.total_cost_usd // "",
  .worktree.original_cwd // "",
  .rate_limits.five_hour.used_percentage // "",
  .rate_limits.five_hour.resets_at // "",
  .rate_limits.seven_day.used_percentage // "",
  .rate_limits.seven_day.resets_at // ""
] | .[]')
EOF

[ -n "$rl_5h_pct" ] && rl_5h_pct=$(printf "%.0f" "$rl_5h_pct")

if [ -n "$used" ]; then
  used_display=$(printf "%.0f" "$used")
  usage_str="${used_display}%"
else
  usage_str="0%"
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

if [ -n "$total_cost" ]; then
  cost_display=$(awk "BEGIN { printf \"%.2f\", $total_cost }")
  block_str="\$${cost_display}"
else
  block_str="\$0.00"
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

format_rl() {
  pct="$1"
  reset_ts="$2"
  label="$3"
  [ -z "$pct" ] && return
  if [ "$pct" -ge 90 ]; then color="$RED"
  elif [ "$pct" -ge 70 ]; then color="$YELLOW"
  else color="$GREEN"
  fi
  reset_time=$(date -r "$reset_ts" "+%-I:%M%p" 2>/dev/null || date -d "@$reset_ts" "+%-I:%M%p" 2>/dev/null)
  bar=$(make_bar "$pct")
  printf "${color}${label} ${bar} ${pct}%% resets ${reset_time}${RESET}"
}

rate_limit_str=""
rate_limit_str="${rate_limit_str}$(format_rl "$rl_5h_pct" "$rl_5h_reset" "5h")"
# rate_limit_str="${rate_limit_str}$(format_rl "$rl_7d_pct" "$rl_7d_reset" "7d")"

repo_root=$(cd "$current_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || echo "$current_dir")
dir_display=$(basename "$repo_root")

if [ -n "$effort" ]; then
  printf "🤖 %s | 💪 %s | 🧠 %s | 💰 %s | ⏱️ %s\n📁 %s | 🌳 %s | 🌿 %s" "$model" "$effort" "$usage_str" "$block_str" "$rate_limit_str" "$dir_display" "$worktree_str" "$git_str"
else
  printf "🤖 %s | 🧠 %s | 💰 %s | ⏱️ %s\n📁 %s | 🌳 %s | 🌿 %s" "$model" "$usage_str" "$block_str" "$rate_limit_str" "$dir_display" "$worktree_str" "$git_str"
fi
