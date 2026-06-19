# Agent Guide (AGENTS.md / CLAUDE.md)

> `CLAUDE.md` is a symlink to this file so any coding agent picks up the same
> conventions. Edit `AGENTS.md`, not the symlink.

This `agent/` directory is the **agent's memory / workspace** for
building X product/feature. It is its own git repo. The actual product
code lives in **sibling repos one level up** (see Layout) and is NOT
tracked by this repo.

## Layout

<need_agent>Update this</need_agent>
```
../workspace_folder/
├── agent/            <- THIS repo (memory, planning, research). git-tracked here.
│   ├── AGENTS.md     <- this file (CLAUDE.md -> AGENTS.md symlink)
│   └── ledger/       <- point-in-time docs (research, deep dives, plans)
├── repo1/            <- FE
├── repo2/            <- BE
└── repo3/            <- util
```

## Where things go (important)

- **Code edits** → the relevant sibling repo
- **Deep dives / research articles / design docs** → `ledger/`. These
  are the agent's main written output besides code. Treat them as
  **point-in-time snapshots**: write a dated, standalone doc; don't
  keep mutating it after the fact (write a new one instead unless you
  are actively working on it now). Link to them from the watson log /
  TODO rather than pasting their contents inline.
- **Live, mutable state** (the log, the todo list) → `agent/` root. These are
  expected to change continuously.

## Watson method (how we track work)

Progress is tracked as **Reflective Inquiry (RI)** entries in
`live/watson_log.md`.  See `live/guides/watson_log_guide_agents.md`
for the full rationale. Each entry has four sections in order: **DONE
→ KNOW → TO KNOW → TO DO**, where *TO KNOW* (the knowledge gaps) is
the driver and every *TO DO* serves a *TO KNOW*. You should be logging
entries here after every major turn. (Some turns are called out to be
ephemeral)

Conventions:
- New RI entries are appended at the **bottom** of `watson_log.md` (oldest first).
- Keep entries short; link out to `ledger/` docs for anything heavy.
- When `watson_log.md` exceeds ~700 lines, migrate older entries +
  completed todos into `ledger/`. After a housekeeping pass, there
  shouldn't be any completed todo items in TODO.md

Keep in mind: The key idea behind the watson log is that software
development is fundamentally a process about improving
understanding. We want to improve our understanding of the product and
the use cases, not just write code. This is why we want to be explicit
about the knowledge gaps (to know) vs the actions. There are huge
codebases that exist that are hard to work in them because much of the
knowledge is in the developers head. Now, with us using coding agents,
we want to make sure we capture this knowledge in our notes (logs,
live state docs, and ledger artifacts).

## TODO.md

- Holds **active** todo items only; each item tags which RI it came from, e.g.
  `(RI 2) ...`.
- A small "recently completed" section is fine; it gets migrated to the ledger
  during the 700-line cleanup above.

## Session handoff (surviving a context clear)

The human may clear the conversation between major turns **while
services are still running**. This means that after any major turn,
you should log your work in the watson log. To resume without
re-standing-up anything:

- run status scripts to reorient yourself quickly
- Then read `watson_log.md` (newest RI at the bottom), `TODO.md`, and
  the latest dated `ledger/` doc for the narrative. The repo being
  committed each turn (see above) is what makes this handoff reliable.

## Human-review flag (search/scan convention)

Anything that needs the developer input, a decision, or sign-off is marked with a
greppable token so he can scan the log / TODO for open questions:

- **`[NEEDS-HUMAN]`** — open: blocked on a human answer or approval. Put the
  actual question right next to it.
- **`[NEEDS-HUMAN ✓]`** — resolved: keep the tag (so history stays searchable),
  append the answer/decision inline, and stop treating it as open.

Workflow: the agent raises `[NEEDS-HUMAN]` items; Human answers them; the agent
(or Human) flips them to `[NEEDS-HUMAN ✓]` with the resolution and acts on it.
Grep open items with: `grep -rn "\[NEEDS-HUMAN\]"` (the resolved ones won't match
because of the trailing ✓).

## Notifications (live coding sessions)

In **interactive live sessions with Human** (i.e. a real back-and-forth, **not**
scripted/ralph-loop runs driven from bash), ping him via `ntfy` whenever you
either **finish a major turn** or **hit a `[NEEDS-HUMAN]` question** — so he can
step away and come back when there's something for him.

**Keep messages VERY short — they go to Human's wrist watch.** He just needs the
**RI ID** and whether it's done or a **question** (a few words at most). The
detail lives in the log/ledger, not the notification. Examples:

```bash
curl -d "RI 14 done" <put_topic_url_here />
curl -d "RI 14 ❓ approve opera scheduling slice?" <put_topic_url_here />
```

Add at most a 3–5 word tail only if it changes whether he comes back now. Don't
notify on every small tool call — only turn-completion or a real question. Skip
entirely for non-interactive/scripted runs.

## Identity

- Human: <first /> <last /> — <email />
- git author here is configured as <first /> <last /> — <email />
