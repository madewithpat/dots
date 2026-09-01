#!/usr/bin/env bash
# Stow package: ornith (~/.local/bin/ollama-ornith-setup.sh) — moved here
# 2026-08-21 from the second-brain vault's .scripts/.
#
# Ornith-1.5-35B-A3B, local on this Mac — model management via Ollama,
# serving via a direct llama-server instance.
#
# Config decided 2026-08-20 (see 02_Areas/_homelab/activity-log.md):
#   - Quant: Q4_K_M (leaves headroom for concurrent-session KV cache on 48GB unified memory)
#   - KV cache: quantized (q8_0) — roughly halves KV memory for a small quality cost
#   - Flash attention: on
#   - Context: 80,000 tokens PER SESSION (160,000 total, split across 2 slots)
#   - Concurrency: 2 parallel slots against one resident model copy — verified
#     with real simultaneous requests, ~35-38 tok/s each, no serialization
#   - Exposed on the LAN (0.0.0.0:11434) for other machines on the network
#
# Why not `ollama serve`: Ollama's own scheduler refuses parallel requests
# for this model's architecture —
#   msg="model architecture does not currently support parallel requests" architecture=qwen35moe
# — silently overriding OLLAMA_NUM_PARALLEL and loading with n_slots=1
# regardless. The underlying llama-server binary (same one Ollama uses
# internally) has no such restriction. So: Ollama pulls/manages the model
# file, but a direct llama-server instance (launchd agent
# com.mwp.llama-server-ornith, see llama-server-ornith-wrapper.sh) serves it.
#
# Idempotent for the pull/install steps. Re-run any time to install Ollama
# and/or pull ornith-1.5:35b if missing; does NOT touch the running service —
# run llama-server-ornith-wrapper.sh's refresh instructions separately if
# you pull a newer model version and want the service to pick it up.
#
# Verify empirically — this script does not attempt to compute or guarantee
# exact memory headroom. Watch memory_pressure / Activity Monitor and the
# service's own log (~/Library/Logs/llama-server-ornith/stderr.log, look for
# "common_memory_breakdown_print") once both sessions are actually in use.

set -euo pipefail

MODEL="ornith-1.5:35b"

echo "==> Checking for Ollama (model management only — not used for serving)..."
if ! command -v ollama >/dev/null 2>&1; then
  echo "==> Installing Ollama via Homebrew"
  brew install ollama
else
  echo "==> Ollama already installed: $(ollama --version 2>&1 | head -1)"
fi

if ! ollama list 2>/dev/null | grep -q "^${MODEL}"; then
  echo "==> Pulling ${MODEL} (Q4 — large download, ~21-24GB)"
  echo "    (needs a running 'ollama serve' — starting one temporarily if none is up)"
  if ! curl -s --max-time 2 http://localhost:11435/api/tags >/dev/null 2>&1; then
    OLLAMA_HOST=127.0.0.1:11435 ollama serve >/tmp/ollama-serve-temp.log 2>&1 &
    TEMP_OLLAMA_PID=$!
    sleep 3
  fi
  OLLAMA_HOST=127.0.0.1:11435 ollama pull "$MODEL"
  [[ -n "${TEMP_OLLAMA_PID:-}" ]] && kill "$TEMP_OLLAMA_PID" 2>/dev/null || true
else
  echo "==> ${MODEL} already pulled"
fi

echo ""
echo "==> Model management done. To (re)start the actual serving layer:"
echo "    See llama-server-ornith-wrapper.sh and the launchd agent"
echo "    com.mwp.llama-server-ornith (~/Library/LaunchAgents/) — already"
echo "    set up and running as of 2026-08-20 if this is the same machine."
echo ""
echo "    Check status:  curl http://localhost:11434/v1/models"
echo "    From LAN:      curl http://<this-mac-lan-ip>:11434/v1/models"
echo "    Restart:       launchctl kickstart -k gui/\$(id -u)/com.mwp.llama-server-ornith"
