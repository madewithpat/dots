#!/usr/bin/env bash
# Stow package: ornith (~/.local/bin/llama-server-ornith-wrapper.sh) — moved
# here 2026-08-21 from the second-brain vault's .scripts/. Invoked directly
# by launchd (see Library/LaunchAgents/com.mwp.llama-server-ornith.plist in
# this same package) via its stowed $HOME path.
#
# Runs llama-server directly for ornith-1.5:35b — bypassing Ollama's own
# scheduler, which currently refuses parallel requests for this model's
# architecture (qwen35moe):
#   msg="model architecture does not currently support parallel requests"
# The underlying llama-server binary has no such restriction; -np works fine
# called directly. See 02_Areas/_homelab/activity-log.md (2026-08-20) and
# 06_Metadata/Solutions/2026-08-20-ollama-blocks-parallel-requests-by-architecture.md
# for the full story.
#
# GGUF/mmproj paths are pinned below rather than resolved at runtime via
# `ollama show` — this service intentionally has no dependency on `ollama
# serve` being up. If you `ollama pull` a newer ornith-1.5:35b, refresh the
# two paths below:
#   ollama serve &            # temporarily, just for the lookup
#   ollama show ornith-1.5:35b --modelfile
#   # copy the two FROM paths in below, then restart this service:
#   ornith restart
#
# Parallel slots and context-per-slot are NOT hardcoded here — they're read
# from ~/.config/ornith/server.env, which `ornith config` edits. Adjust that
# instead of this file for day-to-day tuning.
set -euo pipefail

LLAMA_SERVER="/opt/homebrew/Cellar/ollama/0.32.14/libexec/lib/ollama/llama-server"
GGUF_PATH="/Users/patrick/.ollama/models/blobs/sha256-aaeb640f98a892980ef54876024293cc8d6987a86523aa1b947ffa9274ef800a"
MMPROJ_PATH="/Users/patrick/.ollama/models/blobs/sha256-d9ce31026d1cb1f3f8d5152e2e2a014d9d2b302b6c93a7dc07bb0a0487f52837"

CONFIG_FILE="$HOME/.config/ornith/server.env"
mkdir -p "$(dirname "$CONFIG_FILE")"
if [[ ! -f "$CONFIG_FILE" ]]; then
  cat > "$CONFIG_FILE" <<'DEFAULTS'
# Ornith llama-server runtime config.
# Edit directly, or use: ornith config --parallel N --context N
# Restart to apply: ornith restart
ORNITH_PARALLEL=2
ORNITH_CONTEXT_PER_SLOT=80000
DEFAULTS
fi
# shellcheck disable=SC1090
source "$CONFIG_FILE"
ORNITH_PARALLEL="${ORNITH_PARALLEL:-2}"
ORNITH_CONTEXT_PER_SLOT="${ORNITH_CONTEXT_PER_SLOT:-80000}"
TOTAL_CTX=$(( ORNITH_CONTEXT_PER_SLOT * ORNITH_PARALLEL ))

if [[ ! -f "$GGUF_PATH" ]]; then
  echo "GGUF blob not found: $GGUF_PATH — model may have been re-pulled; see refresh instructions above" >&2
  exit 1
fi

echo "Starting: -np ${ORNITH_PARALLEL} slots x ${ORNITH_CONTEXT_PER_SLOT} ctx (total -c ${TOTAL_CTX})" >&2

exec "$LLAMA_SERVER" \
  --model "$GGUF_PATH" \
  --alias ornith-1.5-35b \
  --mmproj "$MMPROJ_PATH" \
  --host 0.0.0.0 \
  --port 11434 \
  --no-webui \
  -c "$TOTAL_CTX" \
  -np "$ORNITH_PARALLEL" \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --flash-attn on \
  -b 1024 -ub 1024 \
  --context-shift \
  --keep 4 \
  --log-verbosity 4 --no-log-prefix --no-log-timestamps
