---
name: docflow:prd
description: Use when the user wants to generate the Product Requirements Document (prd.md) for a DocFlow project — runs a structured multi-phase adversarial debate (Opus proposer + Sonnet reviewer) to produce a high-quality PRD grounded in explicit intent clarification
---

# Generate PRD via Structured Debate

**Announce at start:** "I'm using docflow:prd to generate the Product Requirements Document via structured adversarial debate."

This skill orchestrates a multi-phase debate loop. The host (this session) runs intent clarification, designs a custom debate framework, then dispatches an Opus proposer subagent and Sonnet reviewer subagent across 2-5 rounds per phase to produce a high-quality PRD.

---

## Phase 1: Initialization

1. Parse the user's topic from the invocation
2. Check `.docflow/debate/` for any in-progress debate — read `references/session-recovery.md` for the full recovery protocol:
   - Found with `status != "completed"` → read `.debate-state` → offer: A) Resume B) Start new
   - Not found → continue
3. Generate `debate-slug` (lowercase, hyphens, max 40 characters)
4. Create workspace directories:
   ```
   .docflow/debate/<slug>/
   .docflow/debate/<slug>/phases/
   .docflow/debate/<slug>/output/
   ```
5. Initialize `.docflow/debate/<slug>/.debate-state`:

```yaml
version: "1.0"
debate_name: "<descriptive name>"
debate_slug: "<slug>"
topic: "<user's original topic verbatim>"
created_at: "<ISO timestamp>"
current_phase: 0
current_round: 0
total_phases: 0
status: "initializing"
research_done: false
intent_confirmed: false
phase_statuses: {}
last_action: "init"
last_action_at: "<ISO timestamp>"
```

---

## Phase 2: Intent Clarification (Mandatory)

**Read `references/intent-clarification.md` for the full protocol.**

If `.docflow/intent-brief.md` already exists: read it and confirm with the user whether to reuse or redo.

Conduct structured clarification (one question at a time, 3-5 questions across the five dimensions). Present a written summary for user confirmation. On confirmation:
- Write `.docflow/intent-brief.md`
- Update `.debate-state`: `intent_confirmed: true`, `last_action: "intent_clarified"`

---

## Phase 3: Framework Design

**Read `references/framework-design.md` for the full design protocol.**

1. Read `.docflow/intent-brief.md` as primary input
2. Classify topic type and select a base pattern
3. Design 4-7 phases, each with: name, objective, key questions (3-5), completion criteria, dependencies
4. Validate all key questions are product-level — no technical implementation, no technical timelines
5. Write `.docflow/debate/<slug>/debate-framework.md`
6. Present to user for confirmation
7. On confirmation: update `.debate-state` (`total_phases`, `status: "in_progress"`, `last_action: "framework_confirmed"`), proceed to codebase research check

---

## Codebase Research (Conditional)

**Trigger when:** topic involves existing codebase, key questions reference existing implementation, user mentioned specific modules.
**Skip when:** pure strategy/business topic, brand new product, no meaningful codebase.

When triggered:
1. Dispatch Explore subagent(s) to scan the project
2. Host synthesizes findings into `.docflow/debate/<slug>/codebase-context.md` (1000-2000 words covering: tech stack, directory structure, relevant modules, data models, reusable patterns)
3. Update `.debate-state`: `research_done: true`, `last_action: "codebase_research"`

Context injection rules per round: read `references/context-management.md`.

---

## Phase 4: Per-Phase Debate Loop

For each phase in the framework, execute the following:

### Step 1: Determine Execution Mode

**Probe round?** Trigger when: early phase, insufficient information, key questions need deeper definition. Skip when: later phases with rich prior commitments or evaluative objectives.

**Module decomposition?** Trigger when: 3+ independent sub-modules identified, key questions naturally group by module. Skip when: single cohesive topic.

Both can coexist: probe round → decomposition → integration rounds.

For probe and decomposition details, read `references/phase-progression.md`.

### Step 2: Execute Standard Rounds

**Read `references/proposer-protocol.md` and `references/reviewer-protocol.md` for exact prompt templates.**

For each standard round:

**2a. Construct proposer prompt** using the appropriate template from `references/proposer-protocol.md`:
- Phase goal + key questions (from `debate-framework.md`)
- Host-synthesized round summary from prior round (~500 words, Round N > 1 only)
- Reviewer's prior round output verbatim (Round N > 1 only)
- Relevant core commitments from `core-commitments.md` (if phase > 1)
- Codebase context from `codebase-context.md` (Round 1 only, if `research_done: true`)
- **Do NOT include full debate history**

Write prompt to `phases/<phase>/prompts/round-NN-proposer-prompt.md`.

**2b. Dispatch Opus proposer:**
```
Agent({
  model: "opus",
  prompt: <contents of round-NN-proposer-prompt.md>
})
```
Write result to `.docflow/debate/<slug>/phases/<phase>/round-NN-proposer.md`.

**2c. Validate output:** length ≥ 200 words, required sections present, key questions covered. If validation fails, re-prompt with explicit gap description (max 2 retries).

**2d. Construct reviewer prompt** using the appropriate template from `references/reviewer-protocol.md`:
- Reviewer role definition (always included, ~500 words)
- Phase goal + key questions
- Proposer's current round output verbatim
- Reviewer's own prior round output (Round N > 1 only, for continuity)
- Codebase context condensed (Round 1 only, if `research_done: true`)
- **Do NOT include proposer's prompt, round summary, or other phases**

**2e. Dispatch Sonnet reviewer:**
```
Agent({
  model: "sonnet",
  prompt: <constructed reviewer prompt>
})
```
Write result to `.docflow/debate/<slug>/phases/<phase>/round-NN-reviewer.md`.

**2f. Update `.debate-state`** with `last_action: "reviewer_round_N_phase_P"`.

**2g. Judge convergence** using the 3-of-5 criteria from `references/phase-progression.md`:
- ≥ 3 criteria met → ADVANCE (Step 3)
- N < 5 → synthesize round summary, continue to next round
- N = 4 with structural objections → use mediation prompt for Round 5
- N = 5 → FORCE ADVANCE with open items

For probe rounds and module decomposition rounds, read `references/phase-progression.md` for their specific progression logic.

### Step 3: Phase Completion

**3a. Write consensus:**
```
.docflow/debate/<slug>/phases/<phase>/consensus.md
```
```markdown
# Phase {N} Consensus — {phase_name}

## Agreed Positions
{positions where both sides agree or proposer satisfactorily justified}

## Compromised Positions
{positions where a middle ground was reached — what each side gave up}

## Open Items
{disagreements not resolved — both sides' positions and core of disagreement}
```

**3b. Extract core commitments** — append to `.docflow/debate/<slug>/core-commitments.md` with `C{phase}.{index}` numbering. See `references/backtracking-algorithm.md` for extraction rules.

**3c. Run backtracking validation** — read `references/backtracking-algorithm.md` for the full algorithm:
- Check each prior commitment against the new consensus across 3 dimensions (alignment, scope, priority)
- Hard violation → block advancement, run supplementary round
- Soft violation → document deviation in consensus, allow advancement
- Write `.docflow/debate/<slug>/phases/<phase>/backtrack-check.md`

**3d. Update `.debate-state`:** `phase_statuses.{N}: "completed"`, `current_phase` incremented, `last_action: "advance_to_phase_{N+1}"`.

**3e. Auto-advance to next phase.**

---

## Phase 5: Final Synthesis

All phases complete. Read all of:
- `.docflow/debate/<slug>/phases/*/consensus.md`
- `.docflow/debate/<slug>/core-commitments.md`
- `.docflow/debate/<slug>/debate-framework.md`
- `.docflow/intent-brief.md`
- `.docflow/debate/<slug>/codebase-context.md` (if exists)

Produce `.docflow/debate/<slug>/output/prd.md` — read `references/prd-template.md` for structure:
- **Product perspective only** — what and why, not how
- No technical architecture, interface definitions, implementation schedule
- Technical constraints appear only as product constraints ("must be compatible with existing X")

---

## Phase 6: Commitment Extraction and Handoff

1. Write `.docflow/commitments.md` from the debate's `core-commitments.md`:

```markdown
# DocFlow Core Commitments

Extracted from PRD debate. All downstream documents must honor these commitments.
Last updated: {ISO timestamp}

## C1.1 — {commitment title}
{one sentence statement}
Source: Phase 1, Round 2 consensus

## C1.2 — ...
```

2. Copy `.docflow/debate/<slug>/output/prd.md` to `docs/prd.md`

3. Update `.debate-state`: `status: "completed"`, `last_action: "synthesis_complete"`

4. Present to user:
```
Debate complete: "{debate_name}"
{total_phases} phases · {total_rounds} rounds · {commitment_count} commitments

Output:
- docs/prd.md — Product Requirements Document
- .docflow/commitments.md — {commitment_count} core commitments for downstream docs

Proceeding to annotation and review.
```

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

## User Interventions

| User says | Host action |
|---|---|
| "Consider X" / "Don't forget Y" | Add as constraint to next round prompt |
| "Wrong direction" / "Focus on Z" | Adjust phase strategy, modify key questions |
| "Skip this phase" | Mark as skipped, advance |
| "Pause" | Save state, wait |
| "Go back to phase N" | Reset to that phase |
| "Add a phase about X" | Insert new phase in framework |

After any intervention, **explicitly confirm the change** before continuing.

---

## Error Handling

**Subagent failure:** Retry once → if still failing, dispatch a Sonnet subagent as temporary proposer and log the fallback in `.debate-state`.

**Poor output quality:** Re-prompt with explicit gap description (max 2 retries). If still poor, advance and flag.

**Runaway debate:** If total rounds > `total_phases × 4`, alert user and offer compression or early conclusion.

---

## Prohibitions

| Do NOT | Reason |
|---|---|
| Skip intent clarification | Misalignment wastes debate rounds and corrupts PRD direction |
| Use a fixed phase template for all topics | Framework must be custom-designed |
| Include technical implementation in the PRD | PRD is product-level: what and why, not how |
| Pass full debate history to subagents | Context overflow — use bounded summaries |
| Let reviewer see proposer's prompt | Creates anchoring bias |
| Advance after only 1 round | Minimum 2 rounds for robustness |
| Skip backtracking verification | Core mechanism — never skip |
| Inject host's own opinions into debate | Host orchestrates, does not participate |
