# PRD-Debate Deep Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port prd-debate's adversarial debate machinery into docflow — replacing the PRD guided intake with a full multi-phase debate loop (Opus proposer + Sonnet reviewer + host orchestrator), and adding commitment-aware consistency checks to all 7 downstream skills.

**Architecture:** The new `skills/prd/SKILL.md` orchestrates a debate loop using the Agent tool instead of Codex CLI. All 11 prd-debate reference files are ported into `skills/prd/references/` with path substitutions and English translation. Each downstream skill gains a pre-generation consistency gate that reads `.docflow/commitments.md`.

**Tech Stack:** Claude Code skills (markdown), bash (validate.sh), Claude Agent tool (opus proposer, sonnet reviewer)

---

## File Structure

**New files:**
- `skills/prd/references/intent-clarification.md`
- `skills/prd/references/framework-design.md`
- `skills/prd/references/backtracking-algorithm.md`
- `skills/prd/references/context-management.md`
- `skills/prd/references/phase-progression.md`
- `skills/prd/references/proposer-protocol.md`
- `skills/prd/references/reviewer-protocol.md`
- `skills/prd/references/session-recovery.md`
- `skills/prd/references/prd-template.md`
- `skills/prd/references/proposer-decomposition.md`
- `skills/prd/references/reviewer-decomposition.md`

**Modified files:**
- `tests/validate.sh` — remove old prd candidate-first check, add checks for reference files + debate patterns + downstream consistency
- `skills/prd/SKILL.md` — full replacement with debate orchestration
- `skills/use-cases/SKILL.md` — add Consistency Check section
- `skills/ux-flow/SKILL.md` — add Consistency Check section
- `skills/domain-model/SKILL.md` — add Consistency Check section
- `skills/ui-spec/SKILL.md` — add Consistency Check section
- `skills/api-spec/SKILL.md` — add Consistency Check section
- `skills/api-implement-logic/SKILL.md` — add Consistency Check section
- `skills/test-spec/SKILL.md` — add Consistency Check section

---

## Task 1: Update validate.sh with new checks (TDD gate)

**Files:**
- Modify: `tests/validate.sh`

- [ ] **Step 1: Remove the prd candidate-first check** (it will break when we replace prd SKILL.md)

Find and remove this line in `tests/validate.sh`:
```bash
check_contains "skills/prd/SKILL.md" "\*(recommended)\*" "prd: has candidate-first recommendations"
```

Replace it with:
```bash
check_contains "skills/prd/SKILL.md" "debate-state" "prd: has debate state management"
check_contains "skills/prd/SKILL.md" "commitments.md" "prd: extracts commitments"
check_contains "skills/prd/SKILL.md" "model.*opus\|opus.*model" "prd: dispatches opus proposer"
```

- [ ] **Step 2: Add reference file existence checks**

Add after the `check_file "skills/prd/SKILL.md"` line:
```bash
for ref in intent-clarification framework-design backtracking-algorithm context-management phase-progression proposer-protocol reviewer-protocol session-recovery prd-template proposer-decomposition reviewer-decomposition; do
    check_file "skills/prd/references/$ref.md"
done
```

- [ ] **Step 3: Add downstream consistency check content checks**

Add a new section at the end of the Iron Laws block:
```bash
echo ""
echo "--- Consistency Check Gate ---"
for skill in use-cases ux-flow domain-model ui-spec api-spec api-implement-logic test-spec; do
    check_contains "skills/$skill/SKILL.md" "commitments.md" "$skill: has consistency check"
done
```

- [ ] **Step 4: Run validate.sh to confirm the red state**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | tail -30
```

Expected: Multiple FAIL lines for missing reference files, prd debate checks, and downstream consistency checks. The PASS count should be lower than before. This is correct — we now have failing tests to drive implementation.

- [ ] **Step 5: Commit the updated validate.sh**

```bash
git add tests/validate.sh
git commit -m "test: add TDD checks for prd-debate integration"
```

---

## Task 2: Create reference directory and port intent-clarification + session-recovery

**Files:**
- Create: `skills/prd/references/intent-clarification.md`
- Create: `skills/prd/references/session-recovery.md`

- [ ] **Step 1: Create the references directory**

```bash
mkdir -p /home/honghaowu/project/docflow/skills/prd/references
```

- [ ] **Step 2: Run validate.sh to confirm reference files still fail**

```bash
bash tests/validate.sh 2>&1 | grep "references"
```

Expected: All reference file checks show FAIL.

- [ ] **Step 3: Write `skills/prd/references/intent-clarification.md`**

```markdown
# Intent Clarification Protocol

## Why Intent Clarification Is Needed

Users' initial descriptions are often vague or incomplete. A statement like "I want to build X feature" may hide:
- Unstated business context and constraints
- Different understandings of the feature's scope
- Implicit priority and trade-off preferences
- Specific user scenarios and pain points
- Hidden expectations about success criteria

## Clarification Dimensions

The host asks questions across the following dimensions, but **does not need to cover all dimensions at once**. Adjust dynamically based on user responses — skip dimensions that are already clear.

### 1. Background and Motivation
- What is the source of this requirement? (user feedback / business goal / competitive pressure / internal discovery)
- Why now? What triggered this?
- What is the ultimate business objective?

### 2. Target Users and Scenarios
- Who is this feature/solution for?
- How are users currently solving this problem? (existing solutions / workarounds)
- What is the core use case? Can you give a concrete example?

### 3. Scope and Boundaries
- How large is this effort in your view? (small feature / medium feature / large product direction)
- Is there anything explicitly out of scope?
- What existing features or modules does this relate to?

### 4. Expectations and Constraints
- What form of output do you expect? (directional exploration / detailed PRD / option comparison / problem diagnosis)
- Are there any hard constraints? (time, resources, technical limitations, compliance requirements)
- Do you already have preferences or leanings?

### 5. Success Criteria
- How will you know this was done well? Are there measurable indicators?
- Who are the stakeholders that need to be aligned?

## Confirmation Template

When the host believes it has sufficient information, present a summary for user confirmation:

```
Based on our conversation, here is my understanding of what you need:

**Background**: {…}
**Core objective**: {…}
**Target users**: {…}
**Key scenarios**: {…}
**Scope**: {…}
**Constraints**: {…}
**Expected output**: {…}

Is my understanding accurate? Anything to add or correct?
```

## Output: `.docflow/intent-brief.md`

```markdown
# Intent Brief

> DocFlow project: "{project_name}"
> Clarified at: {ISO timestamp}

## Background and Motivation
{Business context, source of requirement, triggering factors}

## Core Objective
{What the user wants to achieve — 1-3 sentences}

## Target Users
{User profiles and priority order}

## Key Scenarios
{Core use cases with concrete examples}

## Scope and Boundaries
- **In scope**: {explicitly included}
- **Out of scope**: {explicitly excluded}
- **TBD**: {needs confirmation during discussion}

## Constraints
{Hard constraints: time, resources, compliance, compatibility}

## Expected Output
{Desired form and depth of the final output}

## Success Criteria
{How to measure success}
```

## State Update

After writing the brief, update `.docflow/debate/<slug>/.debate-state`:
```yaml
last_action: "intent_clarified"
intent_confirmed: true
intent_confirmed_at: "<ISO timestamp>"
```

## Special Cases

- **Topic is already very clear**: Still run intent clarification, but compress to 1 round. Confirm: "Your description is already quite clear — let me confirm my understanding…"
- **User pushes to skip**: Explain the cost of misalignment, but if they insist, compress to 1 round and mark as "fast confirmation."
- **User changes direction mid-debate**: If the change is significant, pause, update `intent-brief.md`, then reassess whether the debate framework needs adjustment.
```

- [ ] **Step 4: Write `skills/prd/references/session-recovery.md`**

```markdown
# Session Recovery

How to resume a debate after a session interruption.

## Recovery Detection

When `docflow:prd` is invoked, the host first checks for any in-progress debate:

```
1. Check whether .docflow/debate/ directory exists
2. If it exists, scan subdirectories for .debate-state files
3. Read each .debate-state, filter for status != "completed"
4. If multiple in-progress debates found, list them for user selection
5. If one in-progress debate found, offer to resume it
```

## State File Format

`.docflow/debate/<slug>/.debate-state` full fields:

```yaml
version: "1.0"
debate_name: "AI Customer Support System Design"
debate_slug: "ai-customer-support"
topic: "<user's original topic verbatim>"
created_at: "2026-04-19T10:00:00Z"
current_phase: 2
current_round: 1
total_phases: 5
status: "in_progress"           # initializing | in_progress | paused | completed | failed
research_done: true
research_at: "2026-04-19T10:15:00Z"
intent_confirmed: true
phase_statuses:
  1: "completed"                # pending | in_progress | completed | completed_with_open_items | skipped
  2: "in_progress"
  3: "pending"
  4: "pending"
  5: "pending"
last_action: "proposer_round_1_phase_2"
last_action_at: "2026-04-19T11:30:00Z"
user_interventions: 0
backtrack_violations_total: 0
backtrack_hard_violations: 0
```

## State Checkpoints

`.debate-state` is updated at these moments:

| Event | last_action value | Other updates |
|---|---|---|
| Initialization complete | `"init"` | status → "initializing" |
| Intent confirmed | `"intent_clarified"` | intent_confirmed → true |
| Framework confirmed | `"framework_confirmed"` | total_phases, status → "in_progress" |
| Codebase research complete | `"codebase_research"` | research_done → true |
| Codebase research skipped | `"codebase_research_skipped"` | research_done → false |
| Proposer output written | `"proposer_round_N_phase_P"` | current_round |
| Reviewer output written | `"reviewer_round_N_phase_P"` | — |
| Phase consensus written | `"consensus_phase_P"` | phase_statuses.P → "completed" |
| Backtracking complete | `"backtrack_phase_P"` | backtrack_violations_total |
| Advanced to next phase | `"advance_to_phase_P"` | current_phase, current_round → 1 |
| Final synthesis complete | `"synthesis_complete"` | status → "completed" |
| User intervention | `"user_intervention"` | user_interventions++ |
| User paused | `"user_paused"` | status → "paused" |

## Recovery Flow

### Step 1: Read state

```
Read .debate-state → get current_phase, current_round, last_action, status
```

### Step 2: Determine recovery point

| last_action | Resume from |
|---|---|
| `"init"` | Framework design (Phase 3) |
| `"intent_clarified"` | Framework design (Phase 3) |
| `"framework_confirmed"` | First phase, Round 1 |
| `"proposer_round_N_phase_P"` | Reviewer for that round (proposer already done) |
| `"reviewer_round_N_phase_P"` | Host convergence judgment (reviewer already done) |
| `"consensus_phase_P"` | Backtracking validation |
| `"backtrack_phase_P"` | Advance to next phase |
| `"advance_to_phase_P"` | Round 1 proposer of that phase |
| `"user_paused"` | State before pause |

### Step 3: Gather context

```
Always read:
  - .debate-state
  - debate-framework.md
  - core-commitments.md (if phase > 1)

Read as needed:
  - Latest round-NN-proposer.md for current phase
  - Latest round-NN-reviewer.md for current phase
  - Prior phase's consensus.md (if phase just advanced)
```

### Step 4: Confirm with user

Always present status and wait for confirmation before resuming:

```
Found in-progress debate: "{debate_name}"

Status:
  - Phase: {current_phase}/{total_phases} — {phase_name}
  - Round: {current_round}
  - Last action: {human_readable_last_action}
  - Completed phases: {list}
  - Core commitments so far: {count}

A) Continue from where we left off
B) Review current phase progress before continuing
C) Start a new debate (this one will be preserved)
```

Wait for user selection. **Never resume without confirmation.**

### Step 5: Resume execution

Once confirmed, enter the appropriate flow step based on the recovery point. Do not re-run steps already completed.

## Error Handling

**Corrupt state file:** Try to infer state from filesystem (which round-NN files exist). If inferable, reconstruct `.debate-state` and confirm with user. If not inferable, tell user and suggest resuming from the last phase that has a `consensus.md`.

**Missing round file:** If `round-02-proposer.md` exists but `round-02-reviewer.md` does not, resume from Reviewer Round 2.

**Long interruption (>24 hours):** In addition to status, show the most recent phase's consensus summary to help the user re-orient before resuming.
```

- [ ] **Step 5: Run validate.sh to confirm those two pass**

```bash
bash tests/validate.sh 2>&1 | grep "intent-clarification\|session-recovery"
```

Expected: `PASS: skills/prd/references/intent-clarification.md exists` and `PASS: skills/prd/references/session-recovery.md exists`

- [ ] **Step 6: Commit**

```bash
git add skills/prd/references/intent-clarification.md skills/prd/references/session-recovery.md
git commit -m "feat: port intent-clarification and session-recovery references"
```

---

## Task 3: Port framework-design + context-management + prd-template

**Files:**
- Create: `skills/prd/references/framework-design.md`
- Create: `skills/prd/references/context-management.md`
- Create: `skills/prd/references/prd-template.md`

- [ ] **Step 1: Write `skills/prd/references/framework-design.md`**

```markdown
# Framework Design

How the host designs a custom debate framework for the user's topic.

## Design Principles

1. **Dependency chain first** — later phases must build on earlier phase conclusions. If a phase does not depend on prior conclusions, it may not belong in this framework.
2. **Each phase has a concrete output** — not "further discussion." The output must be something writable into `consensus.md`.
3. **Why → What → How** — clarify why, then what, before discussing how. Do not jump to solutions in Phase 1.
4. **4-7 phases** — fewer than 4 usually means critical layers are skipped; more than 7 is too granular and reduces efficiency.
5. **Each phase escalates** — each phase should be more specific or deeper than the previous on some dimension.

## Design Process

### Step 1: Classify the Topic

| Type | Characteristics | Typical entry |
|---|---|---|
| **Product Feature PRD** | User wants to build a new or improved feature | "Design a…", "I want to build…", "How should this feature work" |
| **Strategy Decision** | Choosing between multiple directions | "Should we use A or B", "technology selection", "strategic direction" |
| **Problem Diagnosis** | Known problems that need systematic analysis | "How to fix these 6 issues", "why are users churning" |
| **Process Design** | Designing workflows, pipelines, collaboration flows | "How to design the review process", "optimize the release flow" |
| **Product Positioning** | Clarifying core value and boundaries | "What exactly is this product", "how to differentiate from competitors" |

### Step 2: Select a Base Pattern

Choose one as a starting point, then tailor it to the specific topic.

#### Pattern A: Product Feature PRD

```
Phase 1: Problem Definition
  Objective: Clarify what problem to solve and for whom
  Key questions:
  - What is the core pain point? How can it be quantified?
  - Who are the target users? How many types? Priority order?
  - How are users currently solving this (workarounds)?
  - What are the success metrics?
  Completion criteria: Clear problem statement + user profile + success metrics

Phase 2: Ideal State
  Objective: Describe the ideal final state without constraints
  Key questions:
  - With no limitations, what would this feature ultimately look like?
  - What is the complete user journey? Key experience nodes?
  - What core capabilities are needed and how do they relate?
  - How does this relate to existing systems (standalone/embedded/replacement)?
  Completion criteria: Full ideal state + user journey + capability list

Phase 3: Gap Analysis
  Objective: Identify gaps between ideal state and current state
  Key questions:
  - What capabilities already exist vs. need to be built?
  - Which experiences are adequate vs. have gaps?
  - What data is needed and what is the data quality?
  - What operational support is needed post-launch?
  Completion criteria: Structured gap list with severity ratings

Phase 4: Solution Strategy
  Objective: Determine strategy and roadmap to close gaps
  Key questions:
  - What are the solution options and their trade-offs?
  - How many phases? What is each phase's core deliverable?
  - What is V1 scope? What must be included vs. deferred?
  - What are the key risks and how to mitigate them?
  Completion criteria: Phase strategy + V1 scope + risk list

Phase 5: Specification Detail
  Objective: Detailed requirements for V1 scope
  Key questions:
  - Detailed behavior for each feature?
  - Edge cases and error handling?
  - Interaction flows and state transitions?
  - Data model and interface constraints?
  Completion criteria: Requirements spec ready for engineering
```

#### Pattern B: Strategy Decision

```
Phase 1: Context Mapping — current state, constraints, stakeholders, timeline
Phase 2: Option Generation — enumerate 3-5 differentiated options
Phase 3: Multi-Dimensional Evaluation — build evaluation framework, score each option
Phase 4: Decision and Roadmap — choose, explain why, plan execution, mitigate risks
```

#### Pattern C: Problem Diagnosis

```
Phase 1: Problem Definition and Classification — group surface problems, build problem tree
Phase 2: Ideal State — positive description of the resolved state
Phase 3: Root Cause Analysis — find structural causes, map root cause → problem
Phase 4: Strategy Formulation — phased solutions with verification approach
```

#### Pattern D: Process Design

```
Phase 1: Current State Mapping — what does the current process look like
Phase 2: Pain Point Identification — bottlenecks, waste, risks
Phase 3: Process Redesign — what should the ideal process look like
Phase 4: Transition Planning — how to move from current to ideal
```

### Step 3: Tailor and Customize

The base pattern is a starting point only. Based on the specific topic:

- **Merge**: If two phases can naturally complete in one discussion, merge them
- **Split**: If a phase is too complex, split into two more focused phases
- **Add**: If the topic has special dimensions (compliance, multi-platform), add dedicated phases
- **Reorder**: If dependencies differ from the template, adjust phase order
- **Rewrite key questions**: Key questions must be specific to the topic, not generic

### Step 4: Validate the Framework

Before presenting to the user, self-check:

- [ ] Does each phase have a concrete output goal?
- [ ] Do phases form a clear dependency chain?
- [ ] Are key questions written specifically for this topic, not from a generic template?
- [ ] Are any two phases discussing the same thing?
- [ ] Does discussion depth increase from first to last phase?
- [ ] Is the count between 4 and 7?

## Presenting the Framework to the User

```
Debate Framework ({N} phases):

1. {Phase Name} — {one-sentence objective}
   Key questions: {2-3 core questions}

2. {Phase Name} — {one-sentence objective}
   Key questions: {2-3 core questions}

...

Estimated {N*2} to {N*4} rounds of discussion.

Shall we begin, or would you like to adjust the framework?
```

User may request: add/remove/merge phases, modify key questions, reorder phases, simplify or deepen overall.

After accepting adjustments, update `debate-framework.md` and proceed to Phase 4 (debate loop).
```

- [ ] **Step 2: Write `skills/prd/references/context-management.md`**

```markdown
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
```

- [ ] **Step 3: Write `skills/prd/references/prd-template.md`**

```markdown
# PRD Template (Product Feature Type)

This template applies to "Product Feature PRD" type debate outputs. For other types (Strategy Decision, Problem Diagnosis, Process Design), the agent organizes content based on the discussion.

```markdown
# {Product Name} Product Requirements Document

> Debate: "{debate_name}"
> Generated at: {ISO timestamp}
> Based on {total_phases} discussion phases, {total_rounds} debate rounds

## 1. Overview
{One paragraph: what this product is, what problem it solves, why now}

## 2. Target Users
{User profiles, priority order, current alternatives}

## 3. User Scenarios
{Core use cases, user journeys, key experience nodes}

## 4. Requirements
{Requirements organized by module/feature, with priority labels (P0/P1/P2)}

## 5. Interaction Design
{Page structure and navigation, core interaction flows, key state transitions, error and edge case handling}

## 6. Product Decision Log
{Key decisions made during discussion, chosen approaches and rationale, rejected alternatives}

## 7. Scope and Boundaries
- **In scope**: {explicitly included in this release}
- **Out of scope**: {explicitly excluded}
- **TBD**: {needs further confirmation}

## 8. Risks and Dependencies
{Identified product risks, external dependencies, prerequisites}

## 9. Open Items
{Topics that did not reach consensus, areas needing further research}

## 10. Success Criteria
{Measurable acceptance indicators}

---

> Technical implementation plans should be created separately based on this PRD.
```

## Usage Notes

- The host uses this structure to organize PRD content during the final synthesis phase
- Inputs: all `consensus.md` files + `core-commitments.md` + `debate-framework.md` + `intent-brief.md` + `codebase-context.md` (if exists)
- Sections may be trimmed based on actual discussion: if a section was not covered, mark as "Not covered in this discussion" rather than forcing content
- Product perspective only: no technical architecture, interface definitions, database design, or implementation schedules
```

- [ ] **Step 4: Run validate.sh to confirm three more pass**

```bash
bash tests/validate.sh 2>&1 | grep "framework-design\|context-management\|prd-template"
```

Expected: 3 PASS lines.

- [ ] **Step 5: Commit**

```bash
git add skills/prd/references/framework-design.md skills/prd/references/context-management.md skills/prd/references/prd-template.md
git commit -m "feat: port framework-design, context-management, prd-template references"
```

---

## Task 4: Port phase-progression + backtracking-algorithm

**Files:**
- Create: `skills/prd/references/phase-progression.md`
- Create: `skills/prd/references/backtracking-algorithm.md`

- [ ] **Step 1: Write `skills/prd/references/phase-progression.md`**

```markdown
# Phase Progression

How the host judges when a phase can advance to the next.

## Round Types and Counting Rules

| Round Type | Numbering | Counts toward 5-round limit? | Notes |
|---|---|---|---|
| Probe Round | Round 0 | No | Question framework building |
| Decomposition Round | Round D | No | Module decomposition |
| Per-Module Round | Round M1, M2… | No | One round per sub-module |
| Standard/Integration Round | Round 1-5 / I1-I5 | Yes | Proposal vs. critique |

**The 5-round limit applies only to Standard/Integration Rounds.** Probe, Decomposition, and Per-Module rounds do not count.

---

## Probe Round Progression

Probe Round runs exactly 1 round (proposer outputs framework + reviewer critiques framework). No multi-round needed.

After the Probe Round, the host evaluates framework quality:

1. **Read Reviewer's Overall Assessment**:
   - "Framework is comprehensive" → use proposer framework + reviewer additions
   - "Framework needs minor additions" → host synthesizes both, updates key questions
   - "Framework needs major expansion" → host synthesizes, updates key questions, emphasizes missed dimensions in next prompt

2. **Host merges both question frameworks**: combine proposer's questions and reviewer's missing questions, remove duplicates and questions already answered in prior phases, update the phase's key questions in `debate-framework.md`

3. **Always advance to Round 1** regardless of assessment. The probe round's purpose is to enrich key questions, not reach consensus.

---

## Module Decomposition Progression

### Decomposition Round

Runs 1 round. Host evaluates decomposition quality:

- "Decomposition is solid" → use proposer's module list
- "Decomposition needs adjustment" → host adjusts module list per reviewer feedback
- "Decomposition needs rework" → host redefines module list

Host confirms final module list → creates `modules/` subdirectory → starts Per-Module Rounds.

### Per-Module Rounds

Each sub-module gets exactly 1 round (proposer + reviewer). No multi-round.

After each sub-module completes:
1. Write `mini-consensus.md` (core decisions + key disagreements)
2. If reviewer found issues affecting other modules, record as cross-module concerns
3. Proceed to next sub-module

### Integration Rounds

Use the same progression criteria as standard rounds (3-of-5 below), but with reviewer focused on cross-module consistency (see `reviewer-decomposition.md`).

---

## Advancement Criteria (3 of 5)

The phase advances when at least 3 of the following 5 criteria are met:

### 1. Key Question Coverage

**Method**: Read the current phase's key questions in `debate-framework.md`. Check whether the proposer's latest round output addresses each question.

- All key questions addressed by proposer → **met**
- Any key question not addressed → **not met**

### 2. Diminishing Objections

**Method**: Classify all reviewer feedback items in the latest round (see `reviewer-protocol.md` for classification).

- Structural objections < 20% (i.e., minor + clarification ≥ 80%) → **met**
- Structural objections ≥ 20% → **not met**

### 3. Proposer Stability

**Method**: Compare proposer's core positions across the last two rounds.

- Core positions unchanged in substance between rounds → **met**
- Any position retracted, fundamentally revised, or direction-changing new position added → **not met**

Substantive change: conclusion direction changes, scope shrinks/grows, priorities shift. NOT substantive: wording improvements, added detail, supporting evidence.

### 4. Minimum Rounds

**Method**: Current round ≥ 2.

- Round 2 or higher → **met**
- Round 1 → **not met**

Rationale: even if reviewer fully agrees in Round 1, a second round verifies proposer stability and catches missed issues.

### 5. Reviewer Acknowledgment

**Method**: Read reviewer's latest "Overall Assessment."

- "Adequate with noted caveats" or "Strong — ready to advance" → **met**
- "Needs major revision" or "Needs minor revision" → **not met**

## Decision Flow

```
After Round N completes:

  Count satisfied criteria (1-5 above)

  IF satisfied >= 3:
    → ADVANCE: Write consensus, extract commitments, run backtracking validation

  ELIF N < 5:
    → CONTINUE: Synthesize round summary, prepare next round

    IF N == 4 AND structural objections persist:
      → MEDIATE: Use mediation prompt template for Round 5

  ELIF N == 5:
    → FORCE ADVANCE: Write partial consensus
    → Document all unresolved disagreements as OPEN ITEMS
    → Mark phase as "completed_with_open_items" in .debate-state
```

## Mediation Mechanism (Round 5)

When Round 4 ends with persistent structural disagreements (criterion 2 not met), the host uses mediation mode for Round 5.

**Proposer**: Use the mediation round template from `proposer-protocol.md`. Require compromise proposals for each disagreement. Mark positions as [AGREED] / [COMPROMISED] / [OPEN ITEM].

**Reviewer**: Additional instruction —
```
This is the FINAL round. For each of the Proposer's compromise proposals:
- Is this compromise acceptable? (Yes / No / Needs adjustment)
- If not, what is the minimum change that would make it acceptable?
- If no compromise is possible, acknowledge as an OPEN ITEM.
Do not raise NEW objections unless they are critical. Focus on evaluating the compromises.
```

## Partial Consensus

When Round 5 ends and 3-of-5 criteria are still not met:

1. Write `consensus.md` clearly labeling open items
2. In `.debate-state`: `phase_statuses.{P}: "completed_with_open_items"`
3. Briefly report to user:
   ```
   Phase {N} completed after 5 rounds. {M} core positions agreed,
   {K} items remain open. Proceeding to Phase {N+1}.
   ```
4. Open items are NOT added to `core-commitments.md` (they are not commitments)
```

- [ ] **Step 2: Write `skills/prd/references/backtracking-algorithm.md`**

```markdown
# Backtracking Validation Algorithm

Ensures that as debate deepens, earlier phase commitments are not silently undermined.

## Problem Definition

Three forms of context degradation can occur as the debate progresses:

- **Direct contradiction**: later conclusions overturn an earlier decision
- **Silent loss**: something committed to in an earlier phase quietly disappears from scope
- **Priority drift**: something established as high priority in an earlier phase becomes low priority later

Backtracking validation automatically checks for these forms of degradation at each phase transition.

## Trigger Points

1. **At each phase transition**: after `consensus.md` is written for a phase, before advancing to the next
2. **After a mediation round**: if Round 5 produced compromises, verify the compromises did not undermine core commitments

## `core-commitments.md` Format

```markdown
# Core Commitments

## Phase 1: {phase_name}
- **C1.1**: {commitment statement}
- **C1.2**: {commitment statement}

## Phase 2: {phase_name}
- **C2.1**: {commitment statement}
- **C2.2**: {commitment statement} [Modified in Phase 3: {reason}]
```

**Extraction rules** — a "core commitment" is:
- An explicit decision: chose option A over option B
- A confirmed constraint: some condition is non-negotiable
- A confirmed scope item: some feature/capability must be included
- A confirmed priority: some things are more important than others
- A confirmed definition: a key concept's definition is aligned

**Not a core commitment**: intermediate ideas during discussion, rejected options, items marked "TBD."

**Numbering**: `C{phase_number}.{sequential_index}`, e.g., C1.1, C1.2, C2.1. If a later phase modifies a commitment, add a note `[Modified in Phase N: reason]` but do NOT delete the original.

## Validation Algorithm

### Inputs
- `core_commitments`: all confirmed core commitments (read from `core-commitments.md`)
- `new_consensus`: current phase's `consensus.md` content

### Steps

```
FOR each commitment C in core_commitments:

  STEP 1: Alignment Check
    Does new_consensus SUPPORT, create TENSION with, or CONTRADICT C?

    SUPPORTED: explicitly or implicitly supports C
    TENSION: introduces elements that create friction with C (not direct contradiction)
    CONTRADICTED: directly contradicts C (position cannot coexist with C)

    Result → alignment_status: SUPPORTED | TENSION | CONTRADICTED

  STEP 2: Scope Check (only for commitments about features/capabilities)
    If C committed to including a feature/capability, is it still included?

    PRESENT: still in scope
    ABSENT: dropped without explanation
    WEAKENED: still mentioned but significantly reduced
    N/A: C is not about scope

    Result → scope_status: PRESENT | ABSENT | WEAKENED | N/A

  STEP 3: Priority Check (only for commitments that established priorities)
    If C established a priority ordering, is it maintained?

    MAINTAINED: same ordering
    SHIFTED: ordering changed but items all present
    REVERSED: high-priority became low-priority or vice versa
    N/A: C is not about priority

    Result → priority_status: MAINTAINED | SHIFTED | REVERSED | N/A

  STEP 4: Classify
    HARD VIOLATION:  alignment_status == CONTRADICTED
    SOFT VIOLATION:  scope_status == ABSENT  OR  priority_status == REVERSED
    WARNING:         alignment_status == TENSION  OR  scope_status == WEAKENED  OR  priority_status == SHIFTED
    OK:              everything else
```

### Output

Write to `phases/<phase>/backtrack-check.md`:

```markdown
# Backtracking Validation — Phase {N}: {phase_name}

Validated against {count} core commitments from Phases 1-{N-1}.

## Results Summary
- OK: {count}
- Warnings: {count}
- Soft Violations: {count}
- Hard Violations: {count}

## Hard Violations (must resolve before advancing)

### C{X}.{Y}: "{commitment text}"
- **Check**: Alignment → CONTRADICTED
- **Evidence**: The consensus states "{quote}" which directly contradicts this commitment.
- **Required action**: Proposer must address this in a supplementary round.

## Soft Violations (must acknowledge in consensus)

### C{X}.{Y}: "{commitment text}"
- **Check**: Scope → ABSENT
- **Evidence**: Committed in Phase {X} but absent from current scope.
- **Required action**: Restore it or add an explicit deviation explanation.

## Warnings (logged for traceability)

### C{X}.{Y}: "{commitment text}"
- **Check**: Alignment → TENSION
- **Evidence**: The direction toward "{quote}" creates friction.
- **Note**: Not blocking, monitor in subsequent phases.

## OK
{list of commitments that passed all checks}
```

## Violation Handling

### Hard Violation

1. **Block phase advancement** — do not update `phase_statuses` to completed
2. Host dispatches a **supplementary round**:
   - New proposer prompt with the contradiction explicitly stated, requiring a position resolution
   - Reviewer reviews the supplementary output
3. If contradiction resolved → update `consensus.md` → re-run validation
4. If contradiction cannot be resolved → mark as OPEN ITEM in consensus, advance with the record preserved in `backtrack-check.md`

### Soft Violation

1. **Does not block advancement**, but require adding to `consensus.md`:
   ```markdown
   ## Deviations from Core Commitments
   ### C{X}.{Y}: "{commitment text}"
   **Deviation**: {what changed}
   **Justification**: {why acceptable}
   **Impact**: {what this means for overall conclusions}
   ```
2. If the deviation is justified, add a note to the original entry in `core-commitments.md`

### Warning

Log only in `backtrack-check.md`. No required action. Continue tracking in subsequent phases.

## Host Execution Notes

1. **Host executes the validation** — do not delegate to Proposer or Reviewer. Host has full context and is most appropriate for cross-checking. Delegating introduces bias.

2. **Validate each commitment individually** — never say "generally consistent." Every commitment needs an explicit status.

3. **Results are visible** — `backtrack-check.md` is preserved in the workspace. If hard/soft violations found, briefly report to user before advancing.
```

- [ ] **Step 3: Run validate.sh to confirm those two pass**

```bash
bash tests/validate.sh 2>&1 | grep "phase-progression\|backtracking-algorithm"
```

Expected: 2 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add skills/prd/references/phase-progression.md skills/prd/references/backtracking-algorithm.md
git commit -m "feat: port phase-progression and backtracking-algorithm references"
```

---

## Task 5: Port proposer-protocol + reviewer-protocol

**Files:**
- Create: `skills/prd/references/proposer-protocol.md`
- Create: `skills/prd/references/reviewer-protocol.md`

- [ ] **Step 1: Write `skills/prd/references/proposer-protocol.md`**

This file contains the prompt templates for the Opus proposer subagent. The host constructs each prompt using these templates and dispatches via `Agent(model: "opus", prompt: <constructed prompt>)`.

```markdown
# Proposer Protocol

How to invoke the Opus proposer subagent, prompt templates, and output requirements.

## Invocation

```
Agent({
  model: "opus",
  prompt: <contents of the constructed prompt>
})
```

Write the result to the appropriate output file (e.g., `phases/<phase>/round-NN-proposer.md`).

Write the prompt to `phases/<phase>/prompts/round-NN-proposer-prompt.md` for auditability.

## Prompt Templates

### Probe Round Prompt (Round 0 — Question Framework)

Used when the host determines a Probe Round is needed. The proposer outputs a question framework, NOT a proposal.

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"

Current phase: {phase_name}
Phase objective: {phase_objective}

The Host has provided these initial key questions:
{key_questions_numbered_list}

DO NOT answer these questions yet. Instead, your job is to BUILD A BETTER QUESTION
FRAMEWORK. Think deeply about:
- What does it mean to FULLY address this phase's objective?
- What information is needed to produce a truly thorough analysis?
- What dimensions or perspectives might the initial questions miss?

Produce a structured question framework that, when answered, would give someone
everything they need to make excellent decisions for this phase.
</task>

{if codebase_context_available}
<codebase_context>
{codebase_context_content}
</codebase_context>
{/if}

<structured_output_contract>
## Assessment of Initial Questions
Brief evaluation: are the Host's initial key questions sufficient? What do they miss?

## Question Framework
Group questions by dimension. For each question:
- The question itself (specific, not vague)
- **Why it matters**: What goes wrong if this question isn't answered
- **What good looks like**: What a satisfactory answer would contain

## Suggested Discussion Order
Which questions should be addressed first? Why?

## Information Gaps
What information would you ideally want but don't have?
What assumptions will need to be made, and how risky are they?
</structured_output_contract>

<grounding_rules>
- Each question must be specific to this topic — no generic "what are the requirements?"
- Consider second-order questions: "if we decide X, what else must we decide?"
- If initial key questions already cover something well, say so — don't re-ask
</grounding_rules>
```

### Round 1 Prompt

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"

Current phase: {phase_name}
Phase objective: {phase_objective}

Key questions to address:
{key_questions_numbered_list}

{if phase > 1}
Context from prior phases:
The following core commitments have been established in earlier phases. Your analysis
must be consistent with these commitments. If you believe any commitment should be
reconsidered, you must explicitly argue why.

{core_commitments_for_this_phase}
{/if}

Produce a thorough, well-reasoned analysis and proposal for this phase.
</task>

{if codebase_context_available}
<codebase_context>
Your proposals MUST be compatible with this existing architecture.
{codebase_context_content}
</codebase_context>
{/if}

<structured_output_contract>
## Analysis
Key observations and reasoning. Every claim must be supported — do not assert without justification.

## Proposal
Concrete positions and recommendations for each key question. Numbered to match key questions.

## Evidence and Rationale
Supporting arguments for each position. Label assumptions explicitly: [Assumption: …]

## Trade-offs Acknowledged
What you are deliberately NOT optimizing for, and why that is acceptable.

## Open Questions
Items needing further discussion.
</structured_output_contract>

<completeness_contract>
You MUST address every key question. If you lack information, state your assumption and proceed.
</completeness_contract>

<grounding_rules>
- Ground every claim in reasoning or evidence
- Label assumptions: [Assumption: …]
- Distinguish "this is true" from "this is my recommendation"
</grounding_rules>
```

### Round N > 1 Prompt

```xml
<task>
You are the Proposer in a structured product debate, continuing Round {N}.

Topic: "{debate_topic}"
Current phase: {phase_name}
Phase objective: {phase_objective}

Key questions to address:
{key_questions_numbered_list}

## Previous Round Summary
{host_synthesized_round_summary}

## Reviewer's Objections from Previous Round
You must address EACH objection explicitly.

{reviewer_previous_round_output_verbatim}

{if phase > 1}
## Core Commitments from Prior Phases
{core_commitments_for_this_phase}
{/if}
</task>

<structured_output_contract>
## Response to Reviewer
For each objection, do ONE of:
- **Accept**: acknowledge validity, state how position changes
- **Rebut**: explain why objection is incorrect, with reasoning
- **Acknowledge as trade-off**: objection is valid but deliberately accepted — explain why

Do NOT ignore any objection.

## Revised Analysis
Updated analysis incorporating responses. Only include changed sections.

## Revised Proposal
Updated positions. Mark each: [UNCHANGED], [REVISED], or [NEW].

## Evidence and Rationale
Arguments for revised or new positions.

## Trade-offs Acknowledged
Updated trade-off list.

## Open Questions
Remaining items.
</structured_output_contract>
```

### Mediation Round Prompt (Round 5, when forced)

```xml
<task>
You are the Proposer in a structured product debate. This is the FINAL round.

Topic: "{debate_topic}"
Phase: {phase_name}

After {N-1} rounds, structural disagreements remain. You must work toward compromise.

## Unresolved Disagreements
{list_of_unresolved_structural_objections}

## Your Last Position
{summary_of_proposer_last_round}

## Reviewer's Last Position
{summary_of_reviewer_last_round}

For each unresolved disagreement, propose a COMPROMISE that:
1. Acknowledges the legitimate concern behind the Reviewer's objection
2. Preserves the core value of your original position
3. Finds a middle ground both sides can accept

If no compromise is possible, clearly state as OPEN ITEM for user escalation.
</task>

<structured_output_contract>
## Compromise Proposals
For each disagreement: the disagreement, proposed compromise, what each side gives up, why acceptable.

## Consolidated Position
Full proposal with each position marked [AGREED], [COMPROMISED], or [OPEN ITEM].

## Open Items for Escalation
Unresolved disagreements framed as clear questions for the user/stakeholder.
</structured_output_contract>
```

## Output Quality Checks

After receiving proposer output, the host checks:

1. **Length**: output < 200 words → likely insufficient quality, consider re-prompting
2. **Structure**: are all required section headings present?
3. **Coverage**: are all key questions addressed?
4. **Grounding**: are there unsubstantiated assertions or unlabeled assumptions?

For Probe Rounds, check instead: dimension coverage (not just functional), specificity (topic-specific, not generic), value explanation (why each question matters).

If checks fail, re-prompt with explicit gap description. Maximum 2 retries.

## Prompt File Management

Write all prompts to `phases/<phase>/prompts/` directory:
- `round-01-proposer-prompt.md`
- `round-02-proposer-prompt.md`
- `round-05-mediation-prompt.md`

Decomposition templates: see `proposer-decomposition.md`.

Keep prompt files for audit and debugging.
```

- [ ] **Step 2: Write `skills/prd/references/reviewer-protocol.md`**

```markdown
# Reviewer Protocol

How to invoke the Sonnet reviewer subagent, role definition, prompt templates, and feedback classification.

## Invocation

```
Agent({
  model: "sonnet",
  prompt: <reviewer role definition + round-specific task prompt>
})
```

Write the result to `phases/<phase>/round-NN-reviewer.md`.

Reviewer prompt is constructed in memory (not written to disk unless debugging).

Key constraints:
- **Pass a complete prompt each call**: subagent has no cross-round memory
- **Do not pass full history**: only what this round needs (see `context-management.md`)
- **Do not pass proposer's prompt**: prevents anchoring bias

## Reviewer Role Definition

Include at the top of every reviewer prompt:

```
You are an adversarial reviewer in a structured product debate.

YOUR JOB IS NOT TO AGREE. Your job is to:
1. Find weaknesses, gaps, contradictions, and unstated assumptions
2. Challenge every major claim — is the evidence sufficient?
3. Identify what the Proposer did NOT address
4. Check internal consistency — do positions contradict each other?
5. Stress-test assumptions — what if they're wrong?
6. Detect scope creep or scope erosion

QUALITY STANDARDS:
- Every objection must be SPECIFIC and ACTIONABLE
- Bad: "needs more detail" — Good: "the user segmentation is missing enterprise users with >1000 seats"
- Do not manufacture objections where none exist — honest "no structural issues" is valid
- Do not agree just because the argument sounds reasonable — actively look for problems

{if codebase_context_available}
CODEBASE CONTEXT: Verify proposer's claims about feasibility. Flag proposals that ignore
existing constraints or duplicate existing functionality.
{codebase_context_condensed}
{/if}

OUTPUT FORMAT:
## Strengths
What the Proposer got right. Specific, not generic.

## Structural Objections
Fundamental issues that MUST be addressed before this phase can advance.
Each objection includes: what is wrong, why it matters, what a satisfactory response looks like.

## Clarification Needed
Ambiguous or underspecified points. Not wrong, but not clear enough to act on.

## Minor Issues
Wording, emphasis, framing improvements. Real but not blocking.

## Key Question Coverage
For each phase key question: [COVERED] | [PARTIAL: specify what's missing] | [MISSING]

## Overall Assessment
One of:
- **Needs major revision**: multiple structural objections remain
- **Needs minor revision**: no structural objections, but significant clarifications needed
- **Adequate with noted caveats**: solid work with acknowledged limitations
- **Strong — ready to advance**: comprehensive, well-justified, all key questions covered
```

## Per-Round Task Prompts

### Probe Round Review (Round 0)

Append after the role definition:

```
You are reviewing the Proposer's QUESTION FRAMEWORK (not a proposal).
Topic: "{debate_topic}" | Phase: {phase_name}

Initial key questions from Host: {initial_key_questions}

--- PROPOSER'S QUESTION FRAMEWORK ---
{proposer_round_0_output_verbatim}
--- END ---

Review the QUALITY OF THE QUESTIONS, not any proposal.

Focus on:
1. Missing dimensions or perspectives
2. Questions that are too vague to be actionable
3. Missing second-order questions
4. Whether "why it matters" explanations are convincing
5. Whether the suggested discussion order is logical

OUTPUT FORMAT:
## Missing Dimensions
## Missing Questions (with why they matter)
## Questions to Remove or Merge
## Order Adjustments
## Overall Assessment (Framework needs major expansion | minor additions | is comprehensive)
```

### Round 1 Review

Append after the role definition:

```
Topic: "{debate_topic}" | Phase: {phase_name}
Key questions: {key_questions_numbered_list}

--- PROPOSER'S OUTPUT (Round 1) ---
{proposer_round_1_output_verbatim}
--- END ---

Review focus: Are key questions adequately addressed? Positions well-justified?
What's missing? Internal contradictions? Would this survive a skeptical stakeholder?
```

### Round N > 1 Review

Append after the role definition:

```
This is Round {N} — the Proposer has revised in response to your prior objections.

Topic: "{debate_topic}" | Phase: {phase_name}
Key questions: {key_questions_numbered_list}

## Your Previous Objections (Round {N-1})
{reviewer_previous_round_output_verbatim}

--- PROPOSER'S REVISED OUTPUT (Round {N}) ---
{proposer_round_N_output_verbatim}
--- END ---

For each of your previous structural objections:
- Was it satisfactorily addressed? Accept / rebut / compromise — was the response convincing?
- If accepted and revised, is the revision adequate?

Check for NEW issues introduced by the revision.

IMPORTANT: If a prior objection was satisfactorily addressed, SAY SO explicitly.
Do not re-raise resolved objections.
```

## Feedback Classification

The host classifies reviewer feedback to determine phase progression (see `phase-progression.md`):

### Structural
Affects core conclusions or proposal viability:
- Core position has logical error
- Key assumption unverified and high-risk
- Missing important user group, scenario, or constraint
- Internal contradiction
- Key question completely unaddressed

### Clarification
Direction is correct but needs more precision:
- Vague quantitative descriptions ("many users" → needs specific number or range)
- Unstated priority ordering
- Unclear concept definitions
- Missing boundary conditions

### Minor
Does not affect core conclusions:
- Wording or phrasing improvements
- Content organization or formatting
- Additional examples or data
- Optional further analysis directions

### Classification Method

1. Items in "Structural Objections" section → default: structural
2. Items in "Clarification Needed" section → default: clarification
3. Items in "Minor Issues" section → default: minor
4. Host may downgrade: if a "Structural Objection" is actually clarification in nature → downgrade
5. Host may upgrade: if a "Clarification Needed" item actually affects core conclusions → upgrade

Count structural / clarification / minor proportions for phase-progression judgment.

## Decomposition Reviews

For Decomposition Round, Per-Module Round, and Integration Round reviewer prompts, see `reviewer-decomposition.md`.
```

- [ ] **Step 3: Run validate.sh to confirm those two pass**

```bash
bash tests/validate.sh 2>&1 | grep "proposer-protocol\|reviewer-protocol"
```

Expected: 2 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add skills/prd/references/proposer-protocol.md skills/prd/references/reviewer-protocol.md
git commit -m "feat: port proposer-protocol and reviewer-protocol references"
```

---

## Task 6: Port proposer-decomposition + reviewer-decomposition

**Files:**
- Create: `skills/prd/references/proposer-decomposition.md`
- Create: `skills/prd/references/reviewer-decomposition.md`

- [ ] **Step 1: Write `skills/prd/references/proposer-decomposition.md`**

```markdown
# Proposer Decomposition Protocol

Proposer prompt templates for Module Decomposition: Decomposition Round, Per-Module Round, Integration Round.

Standard round templates: see `proposer-protocol.md`.

---

## Decomposition Round Prompt

Used when the host determines Module Decomposition is needed.

Write to `phases/<phase>/prompts/round-D-decomposition-prompt.md`, then dispatch:

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"
Current phase: {phase_name}
Phase objective: {phase_objective}

This phase involves multiple sub-modules that should be discussed individually
before integration. Your job is to DECOMPOSE this phase into sub-modules.

Context from prior phases:
{core_commitments_relevant}

{if probe_round_happened}
The enriched key questions for this phase:
{enriched_key_questions}
{/if}
</task>

{if codebase_context_available}
<codebase_context>
Consider aligning sub-modules with the existing code structure where it makes sense.
{codebase_context_content}
</codebase_context>
{/if}

<structured_output_contract>
## Module List
For each module:
- **Name**: Short, descriptive
- **Scope**: What this module covers (and explicitly what it does NOT cover)
- **Key questions**: 2-3 questions specific to this module
- **Dependencies**: Which other modules does this depend on or affect?

## Discussion Order
Order in which modules should be discussed, with reasoning. Modules others depend on first.

## Cross-Module Concerns
Issues spanning multiple modules for the Integration round:
- Data flow between modules
- Navigation/transition between modules
- Shared state or resources
- Consistency requirements
</structured_output_contract>

<grounding_rules>
- Each module must have a clear, non-overlapping scope boundary
- The union of all modules must cover the full phase objective
- Aim for 3-7 modules
- Cross-module concerns are identified here, not resolved
</grounding_rules>
```

---

## Per-Module Round Prompt

One round per sub-module.

Write to `phases/<phase>/prompts/module-NN-proposer-prompt.md`:

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"
Current phase: {phase_name}

You are now working on MODULE: "{module_name}"
Module scope: {module_scope}
Module key questions: {module_key_questions}

{if previous_modules_exist}
Previous modules discussed. Here are their conclusions (mini-consensus summaries):
{previous_modules_mini_consensuses}
{/if}

Core commitments from prior phases:
{core_commitments_relevant}
</task>

<structured_output_contract>
## Module Analysis
Key observations specific to this module's scope.

## Module Proposal
Concrete positions for each of this module's key questions.

## Interface Points
How this module connects to other modules:
- **Inputs**: What this module receives from other modules
- **Outputs**: What this module provides to other modules
- **Shared state**: Any state this module shares with others

## Evidence and Rationale
Supporting arguments for module-level positions.

## Open Questions
Items that may affect other modules or require Integration round resolution.
</structured_output_contract>

<grounding_rules>
- Stay within this module's declared scope
- Explicitly flag decisions that affect other modules
- Interface points must be concrete, not abstract
</grounding_rules>
```

---

## Integration Round Prompt

Used after all per-module rounds are complete.

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"
Current phase: {phase_name}
Phase objective: {phase_objective}

All sub-modules have been discussed individually. You now need to INTEGRATE them
into a coherent whole-phase proposal.

## Module Conclusions (mini-consensus summaries)
{all_modules_mini_consensuses}

## Cross-Module Concerns (identified in Decomposition Round)
{cross_module_concerns}

{if integration_round > 1}
## Integration Reviewer Feedback from Prior Round
{reviewer_prior_integration_output_verbatim}
{/if}

## Core Commitments from Prior Phases
{core_commitments_relevant}
</task>

<structured_output_contract>
## Integration Analysis
How the modules fit together. Focus on cross-module issues, not re-litigating individual modules.

## Integrated Proposal
The full phase proposal incorporating all modules. Cross-module issues resolved.

## Cross-Module Resolutions
For each cross-module concern: how it is resolved in the integrated design.

## Consistency Check
Are all module interface points compatible? Any contradictions between modules?

## Trade-offs Acknowledged
What integration trade-offs were made and why.

## Open Items
Anything that could not be resolved at integration level.
</structured_output_contract>
```
```

- [ ] **Step 2: Write `skills/prd/references/reviewer-decomposition.md`**

```markdown
# Reviewer Decomposition Protocol

Reviewer prompt templates for Module Decomposition: Decomposition Round, Per-Module Round, Integration Round.

Standard round templates: see `reviewer-protocol.md`.

---

## Decomposition Round Review

Append after the reviewer role definition (from `reviewer-protocol.md`):

```
You are reviewing the Proposer's MODULE DECOMPOSITION.

Topic: "{debate_topic}"
Phase: {phase_name} | Objective: {phase_objective}

--- PROPOSER'S DECOMPOSITION ---
{proposer_decomposition_output_verbatim}
--- END ---

Review the DECOMPOSITION QUALITY, not individual module designs.

Focus on:
1. **Coverage**: Does the union of all modules cover the full phase objective? Any gaps?
2. **Boundaries**: Are module scope boundaries clear? Is there overlap?
3. **Granularity**: Too many (>7, too fine) or too few (<3, not enough separation)?
4. **Order**: Does the discussion order respect dependencies?
5. **Cross-module concerns**: Are the identified concerns complete?
6. **Missing modules**: Is there a capability that doesn't fit any listed module?

OUTPUT FORMAT:
## Missing Modules
## Boundary Issues (unclear or overlapping scope)
## Order Issues
## Missing Cross-Module Concerns
## Overall Assessment (Decomposition needs rework | needs adjustment | is solid)
```

---

## Per-Module Round Review

Use standard Round 1 reviewer prompt (from `reviewer-protocol.md`), adding at the end:

```
ADDITIONAL FOCUS for this module review:
- Does this module stay within its declared scope boundary?
- Are the interface points (inputs/outputs to other modules) concrete and well-defined?
- If a decision in this module affects other modules, is it clearly flagged?
- Are edge cases within this module's scope addressed?
```

---

## Integration Round Review

Append after the reviewer role definition:

```
You are reviewing the Integration Round — how all sub-modules fit together.

Topic: "{debate_topic}"
Phase: {phase_name}

Module summaries (what each module decided):
{modules_mini_consensuses_one_line_each}

--- PROPOSER'S INTEGRATION OUTPUT ---
{proposer_integration_output_verbatim}
--- END ---

{if integration_round > 1}
Your prior integration review:
{reviewer_prior_integration_output_verbatim}
{/if}

This is the most critical review — focus on the GAPS BETWEEN MODULES.

Review focus:
1. **Interface compatibility**: Are all module interface points (inputs/outputs) compatible with each other?
2. **Contradiction detection**: Do any two modules make incompatible decisions?
3. **Cross-module concern resolution**: Were all cross-module concerns from the Decomposition Round addressed?
4. **Consistency**: Does the integrated proposal feel like one coherent design or a patchwork?
5. **Missing integration**: Is there anything that spans modules but was left unaddressed?
6. **Scope integrity**: Does the integrated proposal still cover the full phase objective?

OUTPUT FORMAT (same as standard, but focus scoring on cross-module issues):
## Strengths
## Structural Objections (cross-module issues that block advancement)
## Clarification Needed
## Minor Issues
## Cross-Module Concern Status (for each concern from Decomposition Round: RESOLVED | PARTIAL | UNRESOLVED)
## Overall Assessment
```
```

- [ ] **Step 3: Run validate.sh to confirm those two pass**

```bash
bash tests/validate.sh 2>&1 | grep "proposer-decomposition\|reviewer-decomposition"
```

Expected: 2 PASS lines.

- [ ] **Step 4: Commit**

```bash
git add skills/prd/references/proposer-decomposition.md skills/prd/references/reviewer-decomposition.md
git commit -m "feat: port proposer-decomposition and reviewer-decomposition references"
```

---

## Task 7: Replace skills/prd/SKILL.md with debate orchestration

**Files:**
- Modify: `skills/prd/SKILL.md` (full replacement)

- [ ] **Step 1: Run validate.sh to confirm current state**

```bash
bash tests/validate.sh 2>&1 | grep "prd:"
```

Note current pass/fail state. After this task, `prd: has debate state management`, `prd: extracts commitments`, and `prd: dispatches opus proposer` should all PASS. `prd: has candidate-first recommendations` should no longer appear (removed in Task 1).

- [ ] **Step 2: Replace `skills/prd/SKILL.md` with the full debate orchestration**

```markdown
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
```

- [ ] **Step 3: Run validate.sh to confirm prd checks pass**

```bash
bash tests/validate.sh 2>&1 | grep "prd:"
```

Expected:
```
PASS: prd: has name frontmatter
PASS: prd: description starts with 'Use when'
PASS: prd: has debate state management
PASS: prd: extracts commitments
PASS: prd: dispatches opus proposer
PASS: prd: hands off to pipeline
```

- [ ] **Step 4: Commit**

```bash
git add skills/prd/SKILL.md
git commit -m "feat: replace prd skill with adversarial debate orchestration"
```

---

## Task 8: Add consistency check to use-cases, ux-flow, domain-model

**Files:**
- Modify: `skills/use-cases/SKILL.md`
- Modify: `skills/ux-flow/SKILL.md`
- Modify: `skills/domain-model/SKILL.md`

The consistency check block is identical across all downstream skills. It goes between the Dependency Check section and the Fast Mode section.

- [ ] **Step 1: Add to `skills/use-cases/SKILL.md`**

Find this line in `skills/use-cases/SKILL.md`:
```markdown
## Fast Mode
```

Insert the following block immediately before it:

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist** — the PRD debate has not been run yet.

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read `docs/prd.md` (approved upstream dependency)
3. Check whether any commitment is contradicted by the upstream content or the generation context you have gathered
4. If conflict found, surface to user before proceeding:

> "Before generating use-cases.md, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> How would you like to proceed?
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

Wait for user selection. If Override chosen, proceed and add a deviation note at the end of the generated document.

5. Post-generation: after producing the document but before presenting for review, verify the generated content does not violate any commitment. If a violation is found, flag it explicitly in the review presentation.

---
```

- [ ] **Step 2: Add same block to `skills/ux-flow/SKILL.md`**

Find `## Fast Mode` in `skills/ux-flow/SKILL.md`. Insert the same block (replacing "use-cases.md" with "ux-flow.md" in the user-facing message):

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist.**

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read all approved upstream documents: `docs/prd.md`, `docs/use-cases.md`
3. Check whether any commitment is contradicted by the upstream content
4. If conflict found, surface to user before proceeding:

> "Before generating ux-flow.md, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> How would you like to proceed?
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

Wait for user selection. If Override chosen, proceed and add a deviation note.

5. Post-generation: verify generated content against commitments before presenting for review.

---
```

- [ ] **Step 3: Add same block to `skills/domain-model/SKILL.md`**

Find `## Fast Mode` in `skills/domain-model/SKILL.md`. Insert:

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist.**

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read all approved upstream documents: `docs/prd.md`, `docs/use-cases.md`
3. Check whether any commitment is contradicted by the upstream content
4. If conflict found, surface to user before proceeding:

> "Before generating domain-model.md, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> How would you like to proceed?
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

Wait for user selection. If Override chosen, proceed and add a deviation note.

5. Post-generation: verify generated content against commitments before presenting for review.

---
```

- [ ] **Step 4: Run validate.sh to confirm three downstream checks pass**

```bash
bash tests/validate.sh 2>&1 | grep "use-cases: has consistency\|ux-flow: has consistency\|domain-model: has consistency"
```

Expected: 3 PASS lines.

- [ ] **Step 5: Commit**

```bash
git add skills/use-cases/SKILL.md skills/ux-flow/SKILL.md skills/domain-model/SKILL.md
git commit -m "feat: add consistency check gate to use-cases, ux-flow, domain-model"
```

---

## Task 9: Add consistency check to ui-spec, api-spec, api-implement-logic, test-spec

**Files:**
- Modify: `skills/ui-spec/SKILL.md`
- Modify: `skills/api-spec/SKILL.md`
- Modify: `skills/api-implement-logic/SKILL.md`
- Modify: `skills/test-spec/SKILL.md`

Same pattern as Task 8 — insert the consistency check block before `## Fast Mode` in each file.

- [ ] **Step 1: Add to `skills/ui-spec/SKILL.md`**

Find `## Fast Mode` and insert before it:

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist.**

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read all approved upstream documents: `docs/prd.md`, `docs/ux-flow.md`
3. Check whether any commitment is contradicted by upstream content
4. If conflict found:

> "Before generating ui-spec.md, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

5. Post-generation: verify generated content against commitments.

---
```

- [ ] **Step 2: Add to `skills/api-spec/SKILL.md`**

Find `## Fast Mode` and insert before it:

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist.**

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read all approved upstream documents: `docs/use-cases.md`, `docs/domain-model.md`, `docs/ux-flow.md`
3. Check whether any commitment is contradicted by upstream content
4. If conflict found:

> "Before generating api-spec.yaml, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

5. Post-generation: verify generated content against commitments.

---
```

- [ ] **Step 3: Add to `skills/api-implement-logic/SKILL.md`**

Find `## Fast Mode` and insert before it:

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist.**

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read all approved upstream documents: `docs/use-cases.md`, `docs/api-spec.yaml`, `docs/domain-model.md`
3. Check whether any commitment is contradicted by upstream content
4. If conflict found:

> "Before generating api-implement-logic.md, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

5. Post-generation: verify generated content against commitments.

---
```

- [ ] **Step 4: Add to `skills/test-spec/SKILL.md`**

Find `## Fast Mode` and insert before it:

```markdown
---

## Consistency Check

**Skip this section if `.docflow/commitments.md` does not exist.**

If `.docflow/commitments.md` exists:

1. Read `.docflow/commitments.md` in full
2. Read all approved upstream documents: `docs/use-cases.md`, `docs/api-spec.yaml`, `docs/domain-model.md`
3. Check whether any commitment is contradicted by upstream content
4. If conflict found:

> "Before generating test-spec.md, I found a commitment conflict:
>
> **{C_ref}**: {commitment text}
> **Conflict**: {explanation}
>
> 1. Regenerate the PRD to resolve the conflict first
> 2. Override — proceed and document this deviation
> 3. Cancel — I'll review manually"

5. Post-generation: verify generated content against commitments.

---
```

- [ ] **Step 5: Run validate.sh to confirm four more pass**

```bash
bash tests/validate.sh 2>&1 | grep "ui-spec: has consistency\|api-spec: has consistency\|api-implement-logic: has consistency\|test-spec: has consistency"
```

Expected: 4 PASS lines.

- [ ] **Step 6: Commit**

```bash
git add skills/ui-spec/SKILL.md skills/api-spec/SKILL.md skills/api-implement-logic/SKILL.md skills/test-spec/SKILL.md
git commit -m "feat: add consistency check gate to ui-spec, api-spec, api-implement-logic, test-spec"
```

---

## Task 10: Final validation

**Files:** none

- [ ] **Step 1: Run full validate.sh**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh
```

Expected output ends with:
```
=== Results: N passed, 0 failed ===
```

If any failures remain, diagnose and fix before proceeding.

- [ ] **Step 2: Review git log to confirm all tasks committed cleanly**

```bash
git log --oneline -12
```

Expected: 9-10 commits covering each task in this plan.

- [ ] **Step 3: Commit if any unstaged changes remain**

```bash
git status
```

If clean: done. If any files staged or unstaged, investigate and commit appropriately.
