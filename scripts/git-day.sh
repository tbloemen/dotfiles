#!/usr/bin/env bash
set -euo pipefail

DAY="${1:-}"
AUTHOR="${GIT_DAY_AUTHOR:-$(git config user.email)}"

if [[ -z "$DAY" ]]; then
  echo "Usage: git-day.sh YYYY-MM-DD"
  exit 1
fi

# Validate date (basic check)
if ! date -d "$DAY" >/dev/null 2>&1; then
  echo "Invalid date format. Use YYYY-MM-DD"
  exit 1
fi

SINCE="$DAY 00:00"
UNTIL="$DAY 23:59"

# Get commits
COMMITS=$(git log \
  --since="$SINCE" \
  --until="$UNTIL" \
  --author="$AUTHOR" \
  --no-merges \
  --pretty=format:'%h|%s|%cd' 2>/dev/null || true)

if [[ -z "$COMMITS" ]]; then
  exit 0
fi

while IFS="|" read -r hash msg time; do
  printf "%s [%s] %s\n" "$hash" "$time" "$msg"
done <<<"$COMMITS"
