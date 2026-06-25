#!/usr/bin/env bash
# PreToolUse hook to block non-ASCII bytes in file writes

set -euo pipefail

JQ=/home/jle/.nix-profile/bin/jq

if [[ "${1:-}" == "--test" ]]; then
    pass=0
    fail=0
    tmp=$(mktemp)
    trap "rm -f $tmp" EXIT

    expect() {
        local desc="$1" expected="$2"
        # content is already in $tmp
        local exit_code
        set +e
        "$0" < "$tmp" >/dev/null 2>&1
        exit_code=$?
        set -e

        if [[ "$expected" == "block" && "$exit_code" == "2" ]]; then
            echo "  PASS: $desc (blocked)"
            pass=$((pass + 1))
        elif [[ "$expected" == "pass" && "$exit_code" == "0" ]]; then
            echo "  PASS: $desc (allowed)"
            pass=$((pass + 1))
        else
            echo "  FAIL: $desc (expected=$expected, got exit=$exit_code)"
            fail=$((fail + 1))
        fi
    }

    echo "Running check-ascii tests..."
    echo

    # em dash U+2014
    printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"comment \xe2\x80\x94 here"}}' > "$tmp"
    expect "em dash" block

    # en dash U+2013
    printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"range 1\xe2\x80\x932"}}' > "$tmp"
    expect "en dash" block

    # smart quotes U+201C U+201D
    printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"msg = \xe2\x80\x9chello\xe2\x80\x9d"}}' > "$tmp"
    expect "smart quotes" block

    # plain ASCII
    printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"foo = bar + baz"}}' > "$tmp"
    expect "plain ASCII" pass

    # normal haskell
    printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"import Data.Map qualified as M"}}' > "$tmp"
    expect "normal haskell" pass

    # ASCII punctuation
    printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"-- comment: foo-bar (baz) [quux] {x} ~!@#$%%^&*"}}' > "$tmp"
    expect "ASCII punctuation" pass

    echo
    echo "Results: $pass passed, $fail failed"
    [[ "$fail" == "0" ]]
    exit $?
fi

input=$(cat)
tool_name=$(echo "$input" | $JQ -r '.tool_name')

if [[ "$tool_name" == "Edit" ]]; then
    content=$(echo "$input" | $JQ -r '.tool_input.new_string // empty')
elif [[ "$tool_name" == "Write" ]]; then
    content=$(echo "$input" | $JQ -r '.tool_input.content // empty')
else
    exit 0
fi

match=$(echo "$content" | grep -oP '[^\x00-\x7F]' | head -5 || true)
if [[ -n "$match" ]]; then
    cat >&2 <<EOF
Blocked: non-ASCII bytes detected. Only ASCII is allowed in file writes.
Found: $(echo "$match" | tr '\n' ' ')
Source code should never contain non-ASCII characters. If you need non-ASCII in a string literal or in UI, use unicode escape sequences. Unicode is never suitable in prose (markdown, descriptions).
EOF
    exit 2
fi

exit 0
