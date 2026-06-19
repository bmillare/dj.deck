# dj.deck
Coding agent repository template / seed

# Motivation

I've found that a document heavy oriented agentic coding workflow
gives best results. Doing this requires a lot of initial setup and a
particular/opinionated view of habits, practices, and folder
structure.  While every repo will need to eventually grow organically
on it's own, this template intends accelerate the process and be a
common seed for which to grow from.

# Main ideas

- agent scratch space is in ./agent
- separate live mutable artifacts ./agent/live from point-in-time
  mostly immutable/append-only artifacts in ./agent/ledger
- a watson log in ./agent/live/watson_log.md
  - an opinionated understanding oriented progress log for effective
    research and software development
    - see Rich Hickey's "Design In Practice"
      https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/DesignInPractice.md
  - better then just going off of git history or a todo list
- active todos in ./agent/live/TODO.md
- north_star.md doc to create broad context and guidance without
  defining how to do it

# Usage

- clone this template as your WORKSPACE directory
- initialize a NEW git repo inside the agent/ directory
  - be sure to edit/customize AGENTS.md
    - especially by adding your name etc
- initialize/clone your CODE repos inside this WORKSPACE directory
  - WORKSPACE should contain repo folders, not the immediate code
    items
