# Context Management

Core strategy for managing subagent context windows: files as external memory, each agent sees only what it needs.

## Core Principles

1. **Bounded context**: Each agent sees a fixed maximum per round — does not grow linearly with debate rounds
2. **Files as memory**: All discussion output is written to files; read from files when needed
3. **Host as hub**: Host runs in the main session and can read any file; constructs context for each agent
4. **Summaries, not transcripts**: What passes to the next round is a host-synthesized summary, not the full discussion history

## Context Boundaries per Role

### Proposer (each round)

| Content | Source | Size limit |
|---|---|---|
| Phase goal and key questions | `debate-framework.md` | ~200 words |
| Prior round summary | Host-synthesized | ~500 words |
| Reviewer's prior round output | `round-(N-1)-reviewer.md` verbatim | unlimited (typically 500-1500 words) |
| Relevant core commitments | `core-commitments.md` relevant section | ~300 words |
| Codebase context | `codebase-context.md` (Round 1 only) | ≤1000 words |
| **Total** | | **~1500-3500 words** |

**Do NOT pass:**
- Full debate history (any phase)
- Other phases' details
- Proposer's own prior round full output (use summary instead)
- Reviewer's internal reasoning process
- `backtrack-check.md` results (if violation found, embed constraint in prompt)
- Codebase context in Round 2+ (already established in Round 1)

### Reviewer (each round)

| Content | Source | Size limit |
|---|---|---|
| Role definition | `reviewer-protocol.md` template | ~500 words (fixed) |
| Phase goal and key questions | `debate-framework.md` | ~200 words |
| Proposer's current round output | `round-NN-proposer.md` verbatim | unlimited (typically 1000-3000 words) |
| Reviewer's own prior round output | `round-(N-1)-reviewer.md` verbatim | unlimited (for continuity) |
| Codebase context (condensed) | `codebase-context.md` condensed (Round 1 only) | ≤500 words |
| **Total** | | **~2000-4500 words** |

**Do NOT pass:**
- Proposer's prompt (reviewer does not need to know what the proposer was asked)
- Round summary (that is for the proposer)
- Any content from other phases
- `core-commitments.md` (backtracking is the host's responsibility)

### Host (main session)

Host runs in the main session and can read any file in the workspace. Host's context management is not about limiting reads — it is about:

1. **Update `.debate-state` after each round** — ensure state is persisted
2. **Synthesize round summary after each round** — compress the round to ~500 words
3. **Write `consensus.md` after each phase** — compress the full phase to core conclusions
4. **Update `core-commitments.md` after each phase** — extract the most important decisions

## File Pipeline

### Write sequence (Standard Round)

```
Round N start:
  1. Host writes → phases/<phase>/prompts/round-NN-proposer-prompt.md
  2. Agent (opus) produces → Host writes → phases/<phase>/round-NN-proposer.md
  3. Host constructs reviewer prompt (in memory, not to disk)
  4. Agent (sonnet) produces → Host writes → phases/<phase>/round-NN-reviewer.md
  5. Host updates → .debate-state

If continuing to next round:
  6. Host synthesizes round summary (in session memory)

If advancing to next phase:
  6. Host writes → phases/<phase>/consensus.md
  7. Host appends → core-commitments.md
  8. Host writes → phases/<phase>/backtrack-check.md
  9. Host updates → .debate-state (phase complete)
```

### Read dependencies

```
Proposer Round N reads:
  ← debate-framework.md (current phase section)
  ← round-(N-1) summary (host-synthesized, in prompt)
  ← round-(N-1)-reviewer.md
  ← core-commitments.md (relevant section, if phase > 1)

Reviewer Round N reads:
  ← debate-framework.md (current phase section)
  ← round-NN-proposer.md (this round)
  ← round-(N-1)-reviewer.md (own prior round)

Host at phase advance reads:
  ← debate-framework.md
  ← round-NN-proposer.md (latest)
  ← round-NN-reviewer.md (latest)
  ← core-commitments.md (full)
  ← consensus.md (just written, for backtracking)
```

## Round Summary Synthesis

When the host decides to CONTINUE (not advance), synthesize a round summary for the next proposer round.

```markdown
## Round {N} Summary

### Positions Established
{For each key question: proposer's current position in one sentence}

### Resolved This Round
{Prior round's structural objections that were satisfactorily addressed this round}

### Open Objections (must address next round)
{Reviewer's structural objections this round — verbatim key quotes}

### Key Changes
{Substantive position changes proposer made vs. prior round}
```

Quality standards:
- **300-500 words**: too short loses information, too long eats proposer's context budget
- **Delta only**: do not repeat already-confirmed content
- **Quote, don't interpret**: for key disagreements, quote the original text
- **Explicitly flag open items**: ensure proposer knows the must-answer items for next round

## Cross-Phase Context

Later phases' proposers do not directly see earlier phases' discussions. They get prior information through two files:

1. **`core-commitments.md`**: Core decisions from prior phases, one sentence each
2. **`debate-framework.md`**: The framework itself implies the logical relationships between phases

When a phase's key questions explicitly reference a prior phase's conclusions, the host adds to the proposer prompt:

```xml
<prior_phase_context>
In Phase {X} ("{phase_name}"), the following was established:
{relevant excerpt from that phase's consensus.md, max 300 words}
</prior_phase_context>
```

Add only when necessary, not every round.

## Codebase Context Injection

When `research_done: true`, inject `codebase-context.md` content into agent prompts:

| Round type | Proposer | Reviewer |
|---|---|---|
| Each phase Round 1 | Full version ≤1000 words | Condensed ≤500 words |
| Round 2+ | Do not inject | Do not inject |
| Probe Round (Round 0) | Full version | Condensed |
| Decomposition Round | Full version | Condensed |
| Per-Module Round | Relevant module section ≤300 words | Do not inject |
| Integration Round | Full version | Condensed |

**Condensed version**: Extract Tech Stack (all) + Relevant Modules (location + purpose + key interfaces only) + Architectural Constraints (all). Omit Project Structure, Data Models, Reusable Components.
