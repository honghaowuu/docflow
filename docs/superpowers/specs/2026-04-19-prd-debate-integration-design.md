# Design Spec: prd-debate Deep Integration into DocFlow

**Date:** 2026-04-19  
**Status:** Approved for implementation planning

---

## Problem

DocFlow's documentation pipeline is only as good as its root. The PRD (Level 0) feeds all 7 downstream documents. A shallow or misaligned PRD doesn't produce one bad document — it produces seven, each internally consistent but built on a flawed foundation. Two additional failure modes compound this:

1. **Weak intent clarification** — guided intake doesn't surface real constraints before generation begins
2. **No cross-document consistency enforcement** — downstream docs read upstream prose but have no canonical truth to verify against; documents drift

---

## Solution

Port prd-debate's adversarial debate machinery into docflow as a deep integration — not a wrapper. The PRD stage becomes a full debate orchestration. All downstream stages gain a commitment-aware consistency gate.

No Codex dependency. Claude subagents replace GPT/Codex: Opus as proposer, Sonnet as reviewer, main session Claude as host/orchestrator.

---

## Architecture

```
/docflow:start
  → docflow:intent-brief     [NEW] mandatory clarification gate, writes intent-brief.md
  → docflow:prd              [REPLACED] full debate loop, writes prd.md + commitments.md
  → docflow:use-cases        [ENHANCED] consistency check before generation
  → docflow:ux-flow          [ENHANCED] same
  → docflow:domain-model     [ENHANCED] same
  → docflow:ui-spec          [ENHANCED] same
  → docflow:api-spec         [ENHANCED] same
  → docflow:api-implement-logic  [ENHANCED] same
  → docflow:test-spec        [ENHANCED] same
```

**New files introduced:**

| File | Purpose |
|---|---|
| `.docflow/intent-brief.md` | Written output of intent clarification; feeds PRD debate |
| `.docflow/commitments.md` | Extracted core commitments from PRD debate; canonical truth for all downstream docs |
| `.docflow/debate/<slug>/` | Debate workspace — state, rounds, phase files |
| `.docflow/debate/<slug>/.debate-state` | YAML checkpoint for session recovery |

**What does not change:** dependency graph, approval gates, status.yaml tracking, annotation/review/commit flow for all downstream docs.

---

## Component 1: Intent Clarification (`docflow:intent-brief`)

Mandatory gate before PRD debate begins. Implemented as a sub-step inside `docflow:prd` — automatically triggered when `.docflow/intent-brief.md` does not exist. Can also be invoked directly to redo clarification (e.g., if scope changed).

**Protocol:** Ported directly from `prd-debate/references/intent-clarification.md`. Five clarification dimensions, one question at a time:

1. Background and motivation — why this, why now, what business goal
2. Target users and scenarios — who, current workarounds, core use case
3. Scope and boundaries — size, explicit exclusions, related modules
4. Expectations and constraints — desired output depth, hard constraints, existing preferences
5. Success criteria — measurable outcomes, stakeholders to align

Host asks 3-5 questions dynamically (not all dimensions if already clear from context). After sufficient clarity, presents a written summary for user confirmation. On confirmation, writes `.docflow/intent-brief.md` and updates `status.yaml`.

**Output format:**
```markdown
# Intent Brief
> DocFlow project: {project name}
> Clarified at: {ISO timestamp}

## Background and Motivation
## Target Users
## Scope (In / Out / TBD)
## Constraints
## Expected Output
## Success Criteria
```

**Special cases (from prd-debate protocol):**
- Topic already clear → compress to 1 round, confirm understanding
- User pushes to skip → explain cost of misalignment, offer 1-round fast version
- Direction changes mid-debate → pause, update intent-brief.md, reassess framework

---

## Component 2: PRD Debate Loop (`docflow:prd`)

Full port of prd-debate's SKILL.md with three mechanical adaptations:

| prd-debate | docflow |
|---|---|
| `debates/<slug>/` | `.docflow/debate/<slug>/` |
| `.debate-state` YAML | `.docflow/debate/<slug>/.debate-state` + entry in `status.yaml` |
| `codex exec --full-auto` bash call | `Agent(model: "opus")` tool call |
| Claude subagent reviewer | `Agent(model: "sonnet")` tool call |
| `output/prd.md` | standard docflow `prd.md` → annotation → review → commit flow |
| `core-commitments.md` | `.docflow/commitments.md` |

**All reference files port with path-only changes:**
- `intent-clarification.md` → `skills/prd/references/intent-clarification.md`
- `framework-design.md` → `skills/prd/references/framework-design.md`
- `backtracking-algorithm.md` → `skills/prd/references/backtracking-algorithm.md`
- `context-management.md` → `skills/prd/references/context-management.md`
- `phase-progression.md` → `skills/prd/references/phase-progression.md`
- `proposer-protocol.md` → `skills/prd/references/proposer-protocol.md`
- `reviewer-protocol.md` → `skills/prd/references/reviewer-protocol.md`
- `session-recovery.md` → `skills/prd/references/session-recovery.md`
- `prd-template.md` → `skills/prd/references/prd-template.md`
- `proposer-decomposition.md` → `skills/prd/references/proposer-decomposition.md`
- `reviewer-decomposition.md` → `skills/prd/references/reviewer-decomposition.md`

**Debate phases (unchanged from prd-debate):**
1. Initialization — parse topic, check for existing debate (recovery), create workspace, init `.debate-state`
2. Intent clarification — reads `.docflow/intent-brief.md` (already written by intent-brief step)
3. Framework design — custom 4-7 phase framework from intent-brief, product-only focus
4. Codebase research (conditional) — Explore subagent scans project if topic involves existing code
5. Per-phase debate — for each phase: optional probe round → optional module decomposition → 2-5 standard rounds (Opus proposer → Sonnet reviewer → host convergence check) → consensus + commitment extraction + backtracking verification
6. Final synthesis — all consensus files → prd.md (per prd-template.md)
7. Commitment extraction → `.docflow/commitments.md`

**Subagent communication model:**
- Host constructs each subagent's context precisely — no subagent sees another's prompt
- Proposer sees: phase goal + key questions + prior round summary + core commitments
- Reviewer sees: phase goal + proposer's output only + core commitments
- Host sees everything; maintains all state in files; judges convergence

**Convergence criteria (from phase-progression.md):** 3 of 5 signals must be met before advancing. Maximum 5 rounds per phase, then force-advance with documented open items.

**Backtracking verification (from backtracking-algorithm.md):** 3 dimensions checked at each phase boundary — alignment, scope, priority. Hard violation (contradiction) blocks advancement and triggers a correction round. Soft violation is documented in consensus.md but does not block.

**PRD output:** Product-only — what and why, not how. No technical architecture, no implementation details, no schedules. Technical constraints appear only as product constraints ("must be compatible with existing X feature").

**Handoff to docflow pipeline:** When `output/prd.md` is produced, host copies it to standard `prd.md` location, triggers docflow's existing annotation → human review → commit flow. On approval, extracts commitments to `.docflow/commitments.md` and updates `status.yaml`.

---

## Component 3: Downstream Consistency Check

Applied to all 7 downstream document skills before generation begins.

**Pre-generation gate (added to each downstream skill):**

1. Read `.docflow/commitments.md`
2. Read all approved upstream docs for this document's level
3. Check: does the planned generation context contradict any commitment?
4. If conflict found: surface to user with specific commitment reference (`C{phase}.{index}`) — user chooses to regenerate PRD or explicitly override
5. If clean: proceed with generation
6. Post-generation: verify produced doc against commitments before presenting for review

**`commitments.md` structure:**

```markdown
# DocFlow Core Commitments

Extracted from PRD debate. All downstream documents must honor these commitments.
Last updated: {ISO timestamp}

## C1.1 — {Commitment title}
{One sentence statement}
Source: Phase 1, Round 2 consensus

## C1.2 — ...

## C2.1 — ...
```

`C{phase}.{index}` numbering matches prd-debate exactly — no structural change.

**What this replaces:** downstream skills currently read upstream approved files and trust them. This adds an explicit verification layer. The commitments file is the canonical truth; prose docs are its expression.

---

## References Port Plan

All 11 prd-debate reference files are ported into `skills/prd/references/`. Changes per file:

- Path references: `debates/<slug>/` → `.docflow/debate/<slug>/`
- State file references: `.debate-state` → `.docflow/debate/<slug>/.debate-state`
- Codex command references: removed, replaced with Agent tool call description
- Language: files currently in Chinese — translate to English for consistency with docflow
- No structural or logic changes to any reference file

---

## What Does Not Change

- Dependency graph and generation order
- `status.yaml` approval tracking
- Annotation format (AI Reasoning, Assumption, Review Focus)
- Human review gate before any commit
- Fast mode for downstream docs (still available when all dependencies approved)
- Git-tracked approval and commit flow

---

## Out of Scope

- Applying full adversarial debate to downstream docs (use-cases, ux-flow, etc.) — consistency check is sufficient
- Multi-project debate state — each docflow project has its own isolated debate workspace
- Streaming subagent output in real time — each Agent call completes before host reads result
