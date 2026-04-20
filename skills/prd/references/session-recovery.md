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
