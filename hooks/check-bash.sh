#!/usr/bin/env bash
# PreToolUse hook to block certain Bash commands
set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command')

# Block git push -u / --set-upstream
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)git push\b.*(?:\s-u(?:\s|$)|\s--set-upstream(?:\s|$))'; then
  echo 'git push -u / --set-upstream is blocked. Use git push without -u instead.' >&2
  exit 2
fi

# Block git commit --amend
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)git commit\b.*--amend'; then
  echo 'git commit --amend is blocked. Create a new commit instead.' >&2
  exit 2
fi

# Block git commit with HEREDOC body
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)git commit\b'; then
  if echo "$cmd" | grep -qP '\$\(cat\s*<<'; then
    echo 'git commit with HEREDOC message is blocked. Use a simple -m "message" instead.' >&2
    exit 2
  fi
fi

# Block piping to tail on any command
if echo "$cmd" | grep -qP '\|\s*tail\b'; then
  echo '| tail is blocked. If the output is too long, run the command as a background process and read the results file with offset/limit.' >&2
  exit 2
fi

# Block sed -i (agents always nuke files with this)
if echo "$cmd" | grep -qP '(?:^\s*|&&\s*|;\s*|\|\s*|\|\|\s*)sed\s+-\S*i'; then
  echo 'sed -i is blocked. Use the Edit tool instead. You have never once succeeded with sed -i.' >&2
  exit 2
fi

# Block python http.server
if echo "$cmd" | grep -qP 'python3?\s+(-m\s+)?http\.server'; then
  echo 'python http.server is blocked. Use miniserve instead.' >&2
  exit 2
fi

# Block rm/cp without -f (interactive prompts hang)
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)(?:rm|cp)\b'; then
  if ! echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)(?:rm|cp)\b.*\s-[a-zA-Z]*f(?:\s|$)'; then
    echo 'rm and cp must use -f to avoid interactive prompts.' >&2
    exit 2
  fi
fi


# Block gh pr create without --draft
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)gh pr create\b'; then
  if ! echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)gh pr create\b.*--draft(?:\s|$)'; then
    echo 'gh pr create without --draft is blocked. Always use --draft (not -d).' >&2
    exit 2
  fi
  if echo "$cmd" | grep -qiP 'claude'; then
    echo 'gh pr create must not mention Claude.' >&2
    exit 2
  fi
  if echo "$cmd" | grep -qP '(?:--body\b|-b\s)'; then
    if ! echo "$cmd" | grep -qP -- '--body\s+""'; then
      echo 'gh pr create with --body/-b is blocked unless --body "". LLM PR bodies are cringe.' >&2
      exit 2
    fi
  fi
  if echo "$cmd" | grep -qP '\$\(cat\s*<<'; then
    echo 'gh pr create with HEREDOC body is blocked. Use --body "" or no body at all.' >&2
    exit 2
  fi
  if echo "$cmd" | grep -P '[^\x00-\x7F]'; then
    echo 'gh pr create contains non-ASCII characters. Only ASCII is allowed.' >&2
    exit 2
  fi
fi

# Block npx and pip - use nix-shell or nix run instead
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)(?:npx|pip|pip3)\b'; then
  echo 'npx/pip is blocked. Use nix-shell or nix run instead.' >&2
  exit 2
fi

# Block git diff with two-dot notation (require three-dot)
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)git diff\b.*[^\.]\.\.(?!\.)'; then
  echo 'git diff with two-dot (..) is blocked. Always use three-dot (...) notation.' >&2
  exit 2
fi

# Block gh pr comment / gh issue comment
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)gh (?:pr|issue) comment\b'; then
  echo 'gh pr/issue comment is blocked. Do not post comments on PRs or issues. There is nothing functional you can activate using comments. Use gh workflow commands if you are trying to trigger anything.' >&2
  exit 2
fi

# Block gh api for posting comments
if echo "$cmd" | grep -qP '(?:^|&&\s*|;\s*|\|\s*|\|\|\s*)gh api\b.*(?:comments|reviews)'; then
  if echo "$cmd" | grep -qP '(?:-X\s*POST|--method\s*POST|-f\s|--field\s)'; then
    echo 'Posting comments via gh api is blocked. Do not post comments on PRs or issues. There is nothing functional you can activate using comments. Use gh workflow commands if you are trying to trigger anything.' >&2
    exit 2
  fi
fi

exit 0
