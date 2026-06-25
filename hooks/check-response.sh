#!/usr/bin/env bash
# Stop hook to block banned phrases in assistant responses
set -euo pipefail

input=$(cat)
message=$(echo "$input" | jq -r '.last_assistant_message // empty')

if [[ -z "$message" ]]; then
  exit 0
fi

banned=(
  "You're absolutely right"
  "You are absolutely right"
  "pre-existing"
  "pre existing"
  "preexisting"
)

for phrase in "${banned[@]}"; do
  if echo "$message" | grep -qiF "$phrase"; then
    case "$phrase" in
      pre-existing|pre\ existing|preexisting)
        echo "Blocked: Do not claim anything is \"pre-existing\". Master is not broken. If tests are failing after your changes, the breakage is your fault. Investigate and fix it." >&2
        ;;
      *)
        echo "Blocked phrase detected: \"${phrase}\". Rephrase without sycophancy." >&2
        ;;
    esac
    exit 2
  fi
done

exit 0
