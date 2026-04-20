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
