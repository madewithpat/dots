#!/usr/bin/env bash

input=$(cat)

# --- JSON fields ---
cwd=$(echo "$input" | jq -r '.cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
agent_name=$(echo "$input" | jq -r '.agent.name // empty')
agent_type=$(echo "$input" | jq -r '.agent.type // empty')

# --- Git info (skip optional locks) ---
git_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
git_status=$(git -C "$cwd" status --short 2>/dev/null)

# --- Symbols ---
arrow_ahead=$(printf '\xe2\x86\x91')  # ↑ U+2191
arrow_behind=$(printf '\xe2\x86\x93') # ↓ U+2193

# --- ANSI colors ---
reset='\033[0m'
bold='\033[1m'
yellow='\033[33m'
cyan='\033[36m'
green='\033[32m'
red='\033[31m'
magenta='\033[35m'
blue='\033[34m'
dim='\033[2m'

# --- Build segments ---
segments=()

# Git branch and status
if [ -n "$git_branch" ]; then
  if [ -n "$git_status" ]; then
    # Count each category from git status porcelain output
    staged=$(echo "$git_status" | grep -c '^[MADRC]' || true)
    modified=$(echo "$git_status" | grep -c '^.[MD]' || true)
    deleted=$(echo "$git_status" | grep -c '^.D\|^D.' || true)
    renamed=$(echo "$git_status" | grep -c '^R.' || true)
    untracked=$(echo "$git_status" | grep -c '^??' || true)

    # Ahead/behind remote
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    git_indicators=""
    [ "$staged"    -gt 0 ] && git_indicators="${git_indicators} +${staged}"
    [ "$modified"  -gt 0 ] && git_indicators="${git_indicators} ~${modified}"
    [ "$deleted"   -gt 0 ] && git_indicators="${git_indicators} -${deleted}"
    [ "$renamed"   -gt 0 ] && git_indicators="${git_indicators} r${renamed}"
    [ "$untracked" -gt 0 ] && git_indicators="${git_indicators} ?${untracked}"
    [ "$ahead"     -gt 0 ] && git_indicators="${git_indicators} ${arrow_ahead}${ahead}"
    [ "$behind"    -gt 0 ] && git_indicators="${git_indicators} ${arrow_behind}${behind}"

    segments+=("$(printf "${yellow}${bold}%s${reset}${yellow}%s${reset}" "$git_branch" "$git_indicators")")
  else
    # Check ahead/behind even on clean working tree
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo 0)
    git_indicators=""
    [ "$ahead"  -gt 0 ] && git_indicators="${git_indicators} ${arrow_ahead}${ahead}"
    [ "$behind" -gt 0 ] && git_indicators="${git_indicators} ${arrow_behind}${behind}"
    segments+=("$(printf "${green}${bold}%s${reset}${green}%s${reset}" "$git_branch" "$git_indicators")")
  fi
fi

# Vim mode
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    INSERT) segments+=("$(printf "${green}[INSERT]${reset}")") ;;
    NORMAL) segments+=("$(printf "${cyan}[NORMAL]${reset}")") ;;
    *)      segments+=("$(printf "${dim}[%s]${reset}" "$vim_mode")") ;;
  esac
fi

# Agent / plan mode info
if [ -n "$agent_name" ] && [ -n "$agent_type" ]; then
  segments+=("$(printf "${cyan}agent:%s (%s)${reset}" "$agent_name" "$agent_type")")
elif [ -n "$agent_name" ]; then
  segments+=("$(printf "${cyan}agent:%s${reset}" "$agent_name")")
elif [ -n "$agent_type" ]; then
  segments+=("$(printf "${cyan}agent:%s${reset}" "$agent_type")")
fi

# Token counts and context usage
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  if [ "$used_int" -ge 80 ]; then
    ctx_color="$red"
  elif [ "$used_int" -ge 50 ]; then
    ctx_color="$yellow"
  else
    ctx_color="$green"
  fi
  token_str=""
  if [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
    token_str=" ${dim}(in:${input_tokens} out:${output_tokens})${reset}"
  fi
  segments+=("$(printf "${ctx_color}ctx:%s%%%s${reset}" "$used_pct" "$token_str")")
elif [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
  segments+=("$(printf "${dim}in:%s out:%s${reset}" "$input_tokens" "$output_tokens")")
fi

# Current working directory
if [ -n "$cwd" ]; then
  # Shorten $HOME to ~
  short_cwd="${cwd/#$HOME/~}"
  segments+=("$(printf "${blue}%s${reset}" "$short_cwd")")
fi

# Model
if [ -n "$model" ]; then
  segments+=("$(printf "${magenta}${dim}%s${reset}" "$model")")
fi

# --- Join with separator ---
sep="$(printf "${dim} | ${reset}")"
result=""
for seg in "${segments[@]}"; do
  if [ -z "$result" ]; then
    result="$seg"
  else
    result="${result}${sep}${seg}"
  fi
done

printf "%b\n" "$result"
