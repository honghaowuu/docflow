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
