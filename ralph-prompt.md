You are running as ONE iteration of an autonomous Ralph loop, where
you don't have any conversation history from prior runs. All durable
state lives on disk as live state artifacts or point in time ledger
artifacts. Do not assume continuity with a previous run.

Pick and work on the next actionable todo item. Follow standard
procedures after completing that item. If you need to do housekeeping,
do so.

## Exit protocol (IMPORTANT) for Ralph Loop
End your response with EXACTLY ONE status line, on its own line, as the very last
line of your output — and print this token nowhere else:

  RALPH_STATUS=CONTINUE   you made progress and real work still remains
  RALPH_STATUS=BLOCKED    remaining items are blocked on human feedback/decisions
  RALPH_STATUS=DONE       no main items remain to work on
