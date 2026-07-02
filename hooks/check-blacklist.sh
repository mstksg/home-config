#!/usr/bin/env bash
# PreToolUse hook to block blacklisted content from file writes

set -euo pipefail

JQ=/home/jle/.nix-profile/bin/jq

input=$(cat)
tool_name=$(echo "$input" | $JQ -r '.tool_name')

# Extract the content being written
if [[ "$tool_name" == "Edit" ]]; then
    content=$(echo "$input" | $JQ -r '.tool_input.new_string // empty')
elif [[ "$tool_name" == "Write" ]]; then
    content=$(echo "$input" | $JQ -r '.tool_input.content // empty')
else
    exit 0
fi

# Check for circled unicode numbers (U+2460-U+24FF Enclosed Alphanumerics)
if echo "$content" | grep -P '[\x{2460}-\x{24FF}]' >/dev/null 2>&1; then
    cat >&2 <<EOF
Blocked: You used circled unicode numbers. These are stupid. The user thinks they are stupid. Use normal numbers like a normal person.
EOF
    exit 2
fi

# Block edits to hlint config files
file_path=$(echo "$input" | $JQ -r '.tool_input.file_path // empty')
if [[ "$file_path" == *hlint* && ( "$file_path" == *.yaml || "$file_path" == *.yml ) ]]; then
    cat >&2 <<'EOF'
Blocked: Do not edit hlint configuration files. This is requirements-circumventing behavior - you are trying to disable lint rules instead of fixing your code. Ask the user if you think a rule is wrong.
EOF
    exit 2
fi

# Check for HLINT ignore pragmas in Haskell files
if [[ "$file_path" == *.hs ]]; then
    if echo "$content" | grep -qiP '\{-#?\s*HLINT\s+ignore'; then
        cat >&2 <<'EOF'
Blocked: Do not use {-# HLINT ignore #-} pragmas. This is requirements-circumventing behavior - you are trying to suppress lint rules inline instead of fixing your code. Ask the user if you think a rule is wrong.
EOF
        exit 2
    fi
fi

# Check for GHC.Err.error in Haskell files
if [[ "$file_path" == *.hs ]]; then
    if echo "$content" | grep -qF 'GHC.Err.error'; then
        cat >&2 <<'EOF'
Blocked: Do not use GHC.Err.error (or Prelude.error). Using error is requirements-circumventing behavior - it means you are trying to do something sneaky instead of asking the user. If you cannot satisfy the types, ask the user how to proceed.
EOF
        exit 2
    fi
    if echo "$content" | grep -qP '\bunsafeCoerce\b'; then
        cat >&2 <<'EOF'
Blocked: Do not use unsafeCoerce. This is requirements-circumventing behavior - you are bypassing the type checker instead of solving the actual problem. If you cannot satisfy the types, ask the user how to proceed.
EOF
        exit 2
    fi
    if echo "$content" | grep -qP 'OPTIONS_GHC'; then
        cat >&2 <<'EOF'
Blocked: Do not add OPTIONS_GHC pragmas. This is requirements-circumventing behavior - you are trying to disable warnings or change compiler behavior instead of fixing your code. Ask the user if you think a GHC option is needed.
EOF
        exit 2
    fi
fi

exit 0
