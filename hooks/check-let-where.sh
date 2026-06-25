#!/usr/bin/env bash
# PreToolUse hook to block let...in and do-blocks-starting-with-let in Haskell/PureScript

set -euo pipefail

JQ=/home/jle/.nix-profile/bin/jq

# Self-test mode
if [[ "${1:-}" == "--test" ]]; then
    pass=0
    fail=0

    tmp=$(mktemp)
    trap "rm -f $tmp" EXIT

    expect() {
        local desc="$1" expected="$2" content="$3"
        local exit_code
        printf '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.hs","old_string":"","new_string":"%s"}}' "$content" > "$tmp"
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

    echo "Running check-let-where tests..."
    echo

    # let...in checks
    expect "top-level let...in" block \
        "foo x =\\n  let y = x + 1\\n  in y * 2"

    expect "single-line top-level let...in" block \
        "foo x = let y = x + 1 in y * 2"

    expect "let...in inside case branch (multiline)" pass \
        "foo x = case x of\\n  Just y ->\\n    let z = y + 1\\n    in z * 2\\n  Nothing -> 0"

    expect "let...in inside case branch (single-line)" pass \
        "foo x = case x of\\n  Just y -> let z = y + 1 in z * 2\\n  Nothing -> 0"

    # do-let checks
    expect "do block starting with let (after =)" block \
        "foo = do\\n  let x = 5\\n  print x"

    expect "let in middle of do block (after <-)" pass \
        "foo = do\\n  x <- getLine\\n  let y = read x\\n  print y"

    expect "do-let inside lambda (no where available)" pass \
        "foo stRef el =\\n  withCell stRef el \\\\cell -> do\\n    let raw = cell.content\\n    print raw"

    expect "do-let inside case branch (no where available)" pass \
        "foo x = case x of\\n  Just y -> do\\n    let z = show y\\n    putStrLn z\\n  Nothing -> pure ()"

    # BlockArguments / nested do blocks (no where available)
    expect "when ... do starting with let" pass \
        "foo = do\\n  x <- getLine\\n  when (not $ null x) do\\n    let y = read x\\n    print y"

    expect "atomically do starting with let" pass \
        "foo var = do\\n  x <- getLine\\n  atomically do\\n    let y = read x\\n    writeTVar var y"

    expect "void $ async do starting with let" pass \
        "foo = do\\n  x <- getLine\\n  void $ async do\\n    let y = process x\\n    send y"

    expect "for_ xs $ \\x -> do starting with let" pass \
        "foo xs = do\\n  for_ xs $ \\\\x -> do\\n    let y = show x\\n    putStrLn y"

    expect "$ do starting with let (definition)" block \
        "foo = runSomething $ do\\n  let x = 5\\n  print x"

    # More edge cases
    expect "let...in inside filter lambda" pass \
        "foo = filter (\\\\x -> let y = bar x in y > 0) xs"

    expect "identifiers containing let/in substrings" pass \
        "foo = M.insert x (indexOf y) m"

    expect "= do on separate line, starting with let" block \
        "foo x\\n  = do\\n  let y = 5\\n  print y"

    # non-haskell
    expect "no let at all" pass \
        "foo x = x + 1"

    echo
    echo "Results: $pass passed, $fail failed"
    [[ "$fail" == "0" ]]
    exit $?
fi

# Normal hook mode: read from stdin
input=$(cat)
tool_name=$(echo "$input" | $JQ -r '.tool_name')
file_path=$(echo "$input" | $JQ -r '.tool_input.file_path // empty')

# Only check Haskell and PureScript files
if [[ ! "$file_path" =~ \.(hs|purs)$ ]]; then
    exit 0
fi

# Extract the new content being written
if [[ "$tool_name" == "Edit" ]]; then
    new_content=$(echo "$input" | $JQ -r '.tool_input.new_string // empty')
    old_content=$(echo "$input" | $JQ -r '.tool_input.old_string // empty')
elif [[ "$tool_name" == "Write" ]]; then
    new_content=$(echo "$input" | $JQ -r '.tool_input.content // empty')
    if [[ -f "$file_path" ]]; then
        old_content=$(cat "$file_path")
    else
        old_content=""
    fi
else
    exit 0
fi

issues=()

# Detect let...in that should be 'where'.
# let...in is acceptable ONLY inside case/lambda branches (after ->).
# Strategy: find each "in" keyword on its own line (or single-line let...in),
# locate the matching "let", then scan backwards from the let. If we find
# "->" before hitting a top-level definition (line starting with non-space or
# containing " = "), it's inside a branch (allowed).
count_bad_let_in() {
    echo "$1" | perl -0777 -ne '
        my @lines = split /\n/;
        my $count = 0;

        for my $i (0..$#lines) {
            my $line = $lines[$i];

            # Case 1: single-line let...in (let ... in ... on same line)
            if ($line =~ /\blet\b.*\bin\b/) {
                # Check if "->" precedes "let" on this line
                my ($before_let) = $line =~ /^(.*?)\blet\b/;
                if ($before_let !~ /->/) {
                    # Scan backwards for -> or =
                    my $found_arrow = 0;
                    for my $j (reverse 0..($i-1)) {
                        if ($lines[$j] =~ /->/) { $found_arrow = 1; last; }
                        if ($lines[$j] =~ /^\S/ || $lines[$j] =~ /^\s*\w+.*=\s/) { last; }
                    }
                    $count++ unless $found_arrow;
                }
                next;
            }

            # Case 2: multiline — "in" on its own line
            if ($line =~ /^\s*in\b/) {
                # Find matching "let" scanning backwards
                my $let_line = -1;
                for my $j (reverse 0..($i-1)) {
                    if ($lines[$j] =~ /\blet\b/) {
                        $let_line = $j;
                        last;
                    }
                }
                next if $let_line == -1;

                # Check if "->" is on the let line before "let"
                my ($before_let) = $lines[$let_line] =~ /^(.*?)\blet\b/;
                if (defined $before_let && $before_let =~ /->/) {
                    next;  # inside a branch, allowed
                }

                # Scan backwards from let line for -> or =
                my $found_arrow = 0;
                for my $j (reverse 0..($let_line-1)) {
                    if ($lines[$j] =~ /->/) { $found_arrow = 1; last; }
                    if ($lines[$j] =~ /^\S/ || $lines[$j] =~ /^\s*\w+.*=\s/) { last; }
                }
                $count++ unless $found_arrow;
            }
        }
        print $count;
    ' 2>/dev/null || echo "0"
}

new_let_in=$(count_bad_let_in "$new_content")
old_let_in=$(count_bad_let_in "$old_content")

if [[ "$new_let_in" -gt "$old_let_in" ]]; then
    issues+=("let...in detected — use 'where' instead (let...in is only acceptable inside case/lambda branches)")
fi

# Detect do blocks that start with let, but ONLY when the do is the body of
# a definition (has "=" on the same line). Nested do blocks (when, unless,
# atomically, async, for_, etc.) don't have a 'where' clause available.
count_bad_do_let() {
    echo "$1" | perl -0777 -ne '
        my @lines = split /\n/;
        my $count = 0;

        for my $i (0..$#lines) {
            # Find "do" at end of line, followed by let on next line
            if ($lines[$i] =~ /\bdo\s*$/ && $i + 1 <= $#lines && $lines[$i+1] =~ /^\s+let\b/) {
                my $doline = $lines[$i];
                # Only flag if this is a definition: line has "=" (but not <- or == etc)
                # This means the do is directly the body of a function/binding
                next unless $doline =~ /[^!<>=\/]=[^=]/;
                next if $doline =~ /<-/;
                $count++;
            }
        }
        print $count;
    ' 2>/dev/null || echo "0"
}

new_do_let=$(count_bad_do_let "$new_content")
old_do_let=$(count_bad_do_let "$old_content")

if [[ "$new_do_let" -gt "$old_do_let" ]]; then
    issues+=("do block starts with 'let' — move binding to 'where' clause")
fi

if [[ ${#issues[@]} -gt 0 ]]; then
    cat >&2 <<EOF
❌ Blocked: where > let violation
$(printf '  • %s\n' "${issues[@]}")

Rule: Never use let...in where 'where' works. Never start a do block with let.
If a let doesn't depend on a prior (<-) binding, it must be in 'where'.
let...in is only acceptable inside case branches where 'where' is unavailable.
EOF
    exit 2
fi

exit 0
