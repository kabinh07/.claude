#!/usr/bin/env bash

input=$(cat)

model=$(echo "$input"    | jq -r '.model.display_name // "Unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
max_tok=$(echo "$input"  | jq -r '.context_window.context_window_size // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_rst=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_rst=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

email=$(cat /home/kavinh07/.claude/account-email.txt 2>/dev/null || echo "")

# Catppuccin Mocha (256-color)
R=$'\033[0m'
LAVENDER=$'\033[38;5;147m'
SKY=$'\033[38;5;117m'
TEAL=$'\033[38;5;116m'
MAUVE=$'\033[38;5;183m'
PEACH=$'\033[38;5;215m'
GREEN=$'\033[38;5;157m'
DIM=$'\033[38;5;245m'

BAR_LO=$'\033[38;5;157m'
BAR_MID=$'\033[38;5;222m'
BAR_HI=$'\033[38;5;210m'

bar_color() {
  awk "BEGIN {exit !($1 <= 50)}" && printf "%s" "$BAR_LO" && return
  awk "BEGIN {exit !($1 <= 80)}" && printf "%s" "$BAR_MID" && return
  printf "%s" "$BAR_HI"
}

make_bar() {
  local pct="${1:-0}" width="${2:-10}"
  local filled; filled=$(awk "BEGIN {printf \"%.0f\", $pct/100*$width}")
  local empty=$(( width - filled ))
  local col; col=$(bar_color "$pct")
  local f="" e="" i
  for (( i=0; i<filled; i++ )); do f="${f}█"; done
  for (( i=0; i<empty;  i++ )); do e="${e}░"; done
  printf "▕%s%s%s%s▏" "$col" "$f" "$R" "$e"
}

fmt_tok() {
  local n="$1"
  [ -z "$n" ] || [ "$n" = "null" ] && return
  awk "BEGIN {
    n=$n
    if (n >= 1000000) printf \"%.1fM\", n/1000000
    else if (n >= 1000) printf \"%.1fk\", n/1000
    else printf \"%d\", n
  }"
}

fmt_time() {
  local ts="$1" fmt="$2"
  [ -z "$ts" ] && return
  date -d "@${ts}" "$fmt" 2>/dev/null || date -r "${ts}" "$fmt" 2>/dev/null
}

# ── Line 1: model + usage bars ───────────────────────────────────────────────
parts=()
parts+=("${LAVENDER}${model}${R}")

if [ -n "$five_pct" ]; then
  bar=$(make_bar "$five_pct" 10)
  col=$(bar_color "$five_pct")
  clk=""
  [ -n "$five_rst" ] && clk=" ${DIM}◔ $(fmt_time "$five_rst" "+%H:%M")${R}"
  parts+=("${SKY}D:${R} ${bar} ${col}$(printf "%.0f" "$five_pct")%${R}${clk}")
fi

if [ -n "$week_pct" ]; then
  bar=$(make_bar "$week_pct" 10)
  col=$(bar_color "$week_pct")
  clk=""
  [ -n "$week_rst" ] && clk=" ${DIM}◔ $(fmt_time "$week_rst" "+%a %H:%M")${R}"
  parts+=("${TEAL}W:${R} ${bar} ${col}$(printf "%.0f" "$week_pct")%${R}${clk}")
fi

if [ -n "$used_pct" ]; then
  bar=$(make_bar "$used_pct" 10)
  col=$(bar_color "$used_pct")
  tok_str=""
  if [ -n "$used_tok" ] && [ -n "$max_tok" ]; then
    tok_str=" ${MAUVE}$(fmt_tok "$used_tok")${DIM}/${R}${MAUVE}$(fmt_tok "$max_tok")${R}"
  fi
  parts+=("${MAUVE}Context:${R} ${bar} ${col}$(printf "%.0f" "$used_pct")%${R}${tok_str}")
fi

sep=" ${DIM}│${R} "
line1=""
for p in "${parts[@]}"; do
  [ -z "$line1" ] && line1="$p" || line1="${line1}${sep}${p}"
done

# ── Line 2: active plugins ───────────────────────────────────────────────────
plugins=()
if [ -n "$vim_mode" ] && [ "$vim_mode" != "null" ]; then
  plugins+=("${GREEN}Vim: ${vim_mode}${R}")
fi
# Read enabled plugins from settings.json
while IFS= read -r entry; do
  [ -z "$entry" ] || [ "$entry" = "null" ] && continue
  # Strip @marketplace suffix, capitalize first letter
  name="${entry%%@*}"
  name_cap=$(echo "$name" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  plugins+=("${PEACH}[${name_cap}]${R}")
done < <(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' \
           /home/kavinh07/.claude/settings.json 2>/dev/null)

line2=""
if [ ${#plugins[@]} -gt 0 ]; then
  for p in "${plugins[@]}"; do
    [ -z "$line2" ] && line2="$p" || line2="${line2}${sep}${p}"
  done
fi

# ── Line 3: account email ────────────────────────────────────────────────────
line3=""
[ -n "$email" ] && line3="${DIM}${email}${R}"

# ── Output ───────────────────────────────────────────────────────────────────
printf "%s\n" "$line1"
[ -n "$line2" ] && printf "%s\n" "$line2"
[ -n "$line3" ] && printf "%s\n" "$line3"
