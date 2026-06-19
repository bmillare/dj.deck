#!/usr/bin/env bash
# ralph.sh — fresh-context autonomous loop for Claude Code.
#
# Each iteration is a brand-new `claude -p` process, so every run gets a fresh
# context window with zero carryover. Durable state lives in your files + git,
# not in the model's context. No --resume/--continue is used, on purpose.
#
# Stop gracefully at any time:  touch .ralph-stop   (or Ctrl-C)

set -uo pipefail

### ---- config (override via env or edit here) -----------------------------
WORKSPACE_DIR="${HOME}/this_directory"
PROMPT_FILE="${PROMPT_FILE:-${WORKSPACE_DIR}/ralph-prompt.md}"
MAX_ITERATIONS="${MAX_ITERATIONS:-100}"   # hard safety cap
SLEEP_BETWEEN="${SLEEP_BETWEEN:-100}"      # seconds between iterations
MAX_STAGNANT="${MAX_STAGNANT:-1}"        # stop after N iters with no new commit
STOP_FILE="${STOP_FILE:-${WORKSPACE_DIR}/ralph-stop}"    # touch this file to halt after current iter
LOG_DIR="${LOG_DIR:-${WORKSPACE_DIR}/ralph-logs}"
NTFY_ENDPOINT="" #ntfy.sh/put_your_custom_topic_name_here

# Permission flags. Scope as tightly as you can — ideally move most of this into
# .claude/settings.json (allow/deny rules) and trim here. For a fully unattended
# run that edits files and commits, you need edits auto-accepted and git via Bash.
# `--dangerously-skip-permissions` removes ALL prompts; only use it in a sandbox
# or a throwaway worktree.
#CLAUDE_FLAGS="${CLAUDE_FLAGS:---permission-mode acceptEdits --allowedTools Read,Edit,Write,Bash}"
CLAUDE_FLAGS="--dangerously-skip-permissions"
### --------------------------------------------------------------------------

command -v claude >/dev/null || { echo "claude CLI not found in PATH"; exit 1; }
command -v jq     >/dev/null || { echo "jq not found (needed to parse output)"; exit 1; }
[[ -f "$PROMPT_FILE" ]]      || { echo "prompt file not found: $PROMPT_FILE"; exit 1; }
git rev-parse --git-dir >/dev/null 2>&1 || { echo "not inside a git repo"; exit 1; }

mkdir -p "$LOG_DIR"
PROMPT="$(cat "$PROMPT_FILE")"
stagnant=0
trap 'echo; echo "[ralph] interrupted — exiting cleanly."; exit 130' INT TERM

for (( i=1; i<=MAX_ITERATIONS; i++ )); do
  if [[ -f "$STOP_FILE" ]]; then
    echo "[ralph] stop file present — halting."; rm -f "$STOP_FILE"; break
  fi

  ts="$(date +%Y%m%d-%H%M%S)"
  log="$LOG_DIR/iter-$(printf '%03d' "$i")-$ts.json"
  head_before="$(git rev-parse HEAD 2>/dev/null || echo none)"
  echo "[ralph] === iteration $i/$MAX_ITERATIONS @ $ts ==="

  # Fresh process = fresh context. No --resume / --continue.
  claude -p "$PROMPT" $CLAUDE_FLAGS --output-format json \
    >"$log" 2>>"$LOG_DIR/stderr.log"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    status="CRASHED_EXIT_${rc}"
    echo "[ralph] claude exited $rc — see $LOG_DIR/stderr.log. Stopping."; break
    
  fi

  result="$(jq -r '.result // empty' "$log" 2>/dev/null)"
  if [[ -z "$result" ]]; then
    echo "[ralph] empty result (log: $log). Stopping."; break
  fi

  # Last RALPH_STATUS token in the output wins.
  status="$(printf '%s\n' "$result" \
    | grep -oE 'RALPH_STATUS=(CONTINUE|BLOCKED|DONE)' | tail -n1 | cut -d= -f2)"

  head_after="$(git rev-parse HEAD 2>/dev/null || echo none)"
  if [[ "$head_after" == "$head_before" ]]; then
    stagnant=$((stagnant+1))
    echo "[ralph] no new commit (stagnant $stagnant/$MAX_STAGNANT)."
  else
    stagnant=0
    echo "[ralph] committed: $head_after"
  fi

  case "$status" in
    DONE)     echo "[ralph] model reports DONE — finishing.";    break ;;
    BLOCKED)  echo "[ralph] model reports BLOCKED — finishing."; break ;;
    CONTINUE) echo "[ralph] model reports CONTINUE." ;;
    *)        echo "[ralph] no status token (log: $log) — stopping."; break ;;
  esac

  if (( stagnant >= MAX_STAGNANT )); then
    echo "[ralph] $MAX_STAGNANT iterations with no progress — stopping to avoid spinning."
    break
  fi

  curl -d "[ralph] $status $i/$MAX_ITERATIONS @ $ts" $NTFY_ENDPOINT
  sleep "$SLEEP_BETWEEN"
done

curl -d "[ralph] DONE and $status" $NTFY_ENDPOINT
echo "[ralph] done. Per-iteration logs in $LOG_DIR/"
