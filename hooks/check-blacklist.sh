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
    # Block adding/removing comments (only in work projects)
    if [[ -n "${CLAUDE_COMMENT_MORATORIUM:-}" ]] && { echo "$content" | grep -qP '^\s*--(?!\s*\||\s*\^)' || echo "$content" | grep -qP '\{-(?!#)'; }; then
        # For Edit, only block if the comment is NEW (not preserved from old_string)
        if [[ "$tool_name" == "Edit" ]]; then
            old_string=$(echo "$input" | $JQ -r '.tool_input.old_string // empty')
            new_comments=$(echo "$content" | grep -P '^\s*--(?!\s*\||\s*\^)' || true)
            old_comments=$(echo "$old_string" | grep -P '^\s*--(?!\s*\||\s*\^)' || true)
            # Check for added comments
            added=$(comm -23 <(echo "$new_comments" | sort) <(echo "$old_comments" | sort))
            if [[ -n "$added" ]]; then
                cat >&2 <<'EOF'
Blocked: Do not add comments. The user has a moratorium on LLM-written comments.
EOF
                exit 2
            fi
            # Check for removed comments
            removed=$(comm -23 <(echo "$old_comments" | sort) <(echo "$new_comments" | sort))
            if [[ -n "$removed" ]]; then
                cat >&2 <<'EOF'
Blocked: Do not remove or delete existing comments. Preserve all comments exactly as they are.
EOF
                exit 2
            fi
            # Same check for block comments
            new_block=$(echo "$content" | grep -P '\{-(?!#)' || true)
            old_block=$(echo "$old_string" | grep -P '\{-(?!#)' || true)
            added_block=$(comm -23 <(echo "$new_block" | sort) <(echo "$old_block" | sort))
            if [[ -n "$added_block" ]]; then
                cat >&2 <<'EOF'
Blocked: Do not add comments. The user has a moratorium on LLM-written comments.
EOF
                exit 2
            fi
            removed_block=$(comm -23 <(echo "$old_block" | sort) <(echo "$new_block" | sort))
            if [[ -n "$removed_block" ]]; then
                cat >&2 <<'EOF'
Blocked: Do not remove or delete existing comments. Preserve all comments exactly as they are.
EOF
                exit 2
            fi
        elif [[ "$tool_name" == "Write" ]]; then
            cat >&2 <<'EOF'
Blocked: Do not add comments. The user has a moratorium on LLM-written comments.
EOF
            exit 2
        fi
    fi
    if echo "$content" | grep -qP 'OPTIONS_GHC'; then
        cat >&2 <<'EOF'
Blocked: Do not add OPTIONS_GHC pragmas. This is requirements-circumventing behavior - you are trying to disable warnings instead of fixing your code. Do NOT work around this by putting the option in cabal files, per-module ghc-options, or any other mechanism. If you believe the warning is unfixable, STOP and ask the user. Do not suppress it by any means.
EOF
        exit 2
    fi
fi

exit 0
