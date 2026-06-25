#!/usr/bin/env bash
# PreToolUse hook to check HLint issues in Haskell code edits

set -euo pipefail

# Use absolute paths for tools
JQ=/home/jle/.nix-profile/bin/jq
HLINT=/home/jle/.nix-profile/bin/hlint

# Debug logging
DEBUG_LOG=/tmp/hlint-hook-debug.log
echo "=== Hook triggered at $(date) ===" >> "$DEBUG_LOG" 2>&1

# Read the tool input from stdin
input=$(cat)
echo "$input" >> "$DEBUG_LOG" 2>&1

# Extract tool name and file path
tool_name=$(echo "$input" | $JQ -r '.tool_name')
file_path=$(echo "$input" | $JQ -r '.tool_input.file_path // empty')

# Only check Haskell files
if [[ ! "$file_path" =~ \.hs$ ]]; then
    exit 0
fi

# Get old and new content based on tool type
if [[ "$tool_name" == "Edit" ]]; then
    old_content=$(echo "$input" | $JQ -r '.tool_input.old_string // empty')
    new_content=$(echo "$input" | $JQ -r '.tool_input.new_string // empty')
elif [[ "$tool_name" == "Write" ]]; then
    new_content=$(echo "$input" | $JQ -r '.tool_input.content // empty')
    # For Write, check if file already exists
    if [[ -f "$file_path" ]]; then
        old_content=$(cat "$file_path")
    else
        old_content=""
    fi
else
    exit 0
fi

# Create temporary files for hlint checking
temp_old=$(mktemp --suffix=.hs)
temp_new=$(mktemp --suffix=.hs)
trap "rm -f $temp_old $temp_new" EXIT

echo "$old_content" > "$temp_old"
echo "$new_content" > "$temp_new"

# Run hlint on both old and new content
hook_dir="$(dirname "$0")"
old_has_error=false
new_has_error=false
old_parse_failed=false
new_parse_failed=false

# Check old content
old_output=$($HLINT --hint="$hook_dir/hlint.yaml" "$temp_old" 2>&1 || true)
if echo "$old_output" | grep -q "Parse error"; then
    old_parse_failed=true
elif echo "$old_output" | grep -qE "(Warning:|Error:|Suggestion:)"; then
    old_has_error=true
fi

# Check new content
new_output=$($HLINT --hint="$hook_dir/hlint.yaml" "$temp_new" 2>&1 || true)
if echo "$new_output" | grep -q "Parse error"; then
    new_parse_failed=true
elif echo "$new_output" | grep -qE "(Warning:|Error:|Suggestion:)"; then
    new_has_error=true
fi

# If new content has parse errors, allow it (syntax errors are the compiler's job)
if [[ "$new_parse_failed" == "true" ]]; then
    exit 0
fi

# Only block if new content has hlint errors but old content didn't
if [[ "$new_has_error" == "true" && "$old_has_error" == "false" ]]; then
    cat >&2 <<EOF
❌ Blocked: HLint issues detected
$new_output
EOF
    exit 2
fi

# Allow the operation (either no error, or error was already present)
exit 0
