#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Colors
GRAY="\033[38;5;248m"           # context % (always)
GREEN="\033[32m"                # token budget (healthy)
YELLOW="\033[33m"               # token budget (mid)
RED="\033[31m"                  # token budget (high)
RESET="\033[0m"

# --- Smart-zone budget (tune as Claude evolves) ---------------------------
YELLOW_AT=120         # k tokens -> yellow ("wrap up soon")
RED_AT=150            # k tokens -> red ("compact / new session")
# --------------------------------------------------------------------------

# Token count colored by the smart-zone thresholds above:
#   green < YELLOW_AT, yellow >= YELLOW_AT, red >= RED_AT (in k tokens).
# The % is always gray and shows real fill of the live context window (200k/1M).
# Both come live from the statusline JSON (tokens = input incl. cache reads/writes).
USED_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
USED_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$USED_TOKENS" ] && [ "$USED_TOKENS" != "null" ]; then
    USED_K=$(awk -v t="$USED_TOKENS" 'BEGIN { printf "%.1f", t / 1000 }')
    PCT=$(awk -v p="${USED_PCT:-0}" 'BEGIN { printf "%.0f", p }')
    TIER=$(awk -v t="$USED_TOKENS" -v y="$YELLOW_AT" -v r="$RED_AT" \
        'BEGIN { k = t / 1000; if (k >= r) print 2; else if (k >= y) print 1; else print 0 }')
    case "$TIER" in
        2) TOK_COLOR="$RED" ;;
        1) TOK_COLOR="$YELLOW" ;;
        *) TOK_COLOR="$GREEN" ;;
    esac
    printf "%b\n" "${TOK_COLOR}${USED_K}k ${GRAY}~${PCT}%${RESET}"
fi
