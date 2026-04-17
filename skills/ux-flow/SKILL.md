---
name: docflow:ux-flow
description: Use when the user wants to generate or regenerate the UX Flow document (ux-flow.md) for a DocFlow project
---

# Generate UX Flow

**Announce at start:** "I'm using docflow:ux-flow to generate the UX Flow document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify both `prd.md` and `use-cases.md` have `status: approved`.

If either is not approved:
> "Cannot generate ux-flow.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/prd.md` and `docs/use-cases.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| User journeys | One journey per actor + primary goal pair | Every use-case main flow must map to a journey |
| Entry points | Where each journey begins (screen, event, or trigger) | Must be specific — "app opens" is not sufficient |
| Transitions | State-to-state movements within each journey | Every use-case main flow step must map to a transition |
| Error states | What happens when a transition fails | At least one error state per journey |
| Exit points | How each journey ends | Must cover both success and failure exits |

---

## Candidate-First Questioning

Read `docs/use-cases.md` and `docs/prd.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate journeys from use-case actor+goal pairs:**
> "I've identified these candidate user journeys from the use cases:
>
> 1. **[Actor A] — [Goal from UC-1]** *(recommended — highest priority use case)*
> 2. **[Actor B] — [Goal from UC-2]**
> 3. [Additional journey if multiple actors/goals]
> N. Other — describe your own
>
> Which of these should be included? You can select multiple."

**For each confirmed journey — derive candidate entry points from use-case preconditions:**
> "For the **[Actor] — [Goal]** journey, the use case preconditions suggest it could begin at:
>
> 1. **[Entry derived from preconditions or problem context]** *(recommended)*
> 2. **[Alternative entry point]**
> 3. Other — describe your own
>
> Which is correct?"

**For transitions — derive candidate steps from the use-case main flow:**
> "Based on the use-case main flow for [goal], I've mapped these transitions:
>
> 1. [Use-case step 1] → [resulting state]: **[Transition description]** *(recommended)*
> 2. [Alternative sequencing]
> 3. Adjust / add steps
>
> Does this match the intended flow? What should change? Every use-case step needs a mapped transition."

**For each transition — derive candidate error states from use-case alternative flows:**
> "The use case lists these alternative flows that could create error states here:
>
> 1. **[Alt flow 1 mapped to an error state]** *(recommended)*
> 2. **[Alt flow 2 mapped to an error state]**
> 3. Other — describe your own
>
> Which error states apply? At least one is required per journey."

**For exit points — derive from use-case postconditions and alternative flow endings:**
> "This journey could exit at:
>
> 1. **[Success exit derived from use-case postcondition]** *(recommended)*
> 2. **[Failure exit from a terminal alternative flow]**
> 3. Other — describe your own"

**Coverage check before proceeding:**
- Every use-case main flow maps to a journey
- Every journey has at least one error state
- Every journey has explicit success and failure exit points

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The entry point is obvious" | Unstated entry points become inconsistent implementations across screens. Write them. |
| "We don't need error states for this journey" | Every journey has failure modes. Derive them from the use-case alternative flows. |
| "The transitions are just the use-case steps" | UX transitions capture system state changes, not just actions. Map each step to a state. |

---

## Template

Use `templates/ux-flow.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency
- `docs/use-cases.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
