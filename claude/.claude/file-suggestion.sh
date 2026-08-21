#!/usr/bin/env bash
# Claude Code fileSuggestion hook — fzf-backed fuzzy file search for the
# `@` file-mention picker, run on every keystroke after `@`.
# https://code.claude.com/docs/en/settings#file-suggestion-settings
#
# stdin:  {"query": "text typed after @"}
# stdout: matching file paths, one per line (Claude Code shows up to ~15)
set -euo pipefail

query=$(jq -r '.query // ""')

# `|| true`: head closing the pipe after 15 lines sends SIGPIPE upstream to
# fzf/fd, which pipefail would otherwise turn into a nonzero exit for this
# whole script even though stdout is already correct.
fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --filter="$query" 2>/dev/null | head -n 15 || true
