---
name: docflow:use-cases
description: Use when the user wants to generate or regenerate the Use Cases document (use-cases.md) for a DocFlow project
---

# Generate Use Cases

**Announce at start:** "I'm using docflow:use-cases to generate the Use Cases document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `prd.md` has `status: approved`.

If not approved:
> "Cannot generate use-cases.md — prd.md must be approved first. Would you like to generate prd.md instead?"

Stop here. Do not proceed without an approved prd.md.

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|-------|-------------|------------|
| Actors | All people and systems that interact with the product | Derived from prd.md target users — confirm and extend |
| Use cases | One use case per actor goal | Each must have: goal, preconditions, main flow, alternative flows, postconditions |

**Minimum:** Every goal from prd.md Goals section must map to at least one use case.

---

## Candidate-First Questioning

Read `docs/prd.md` before asking any question. Derive candidates from the PRD throughout.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate actors from prd.md target users:**
> "Based on the PRD, I've identified these actors:
>
> 1. **[Primary user from prd.md]** *(recommended)*
> 2. **[Secondary user from prd.md]**
> 3. Other — describe your own
>
> Which actors should be included? You can select multiple, rename, or split any into more specific roles."

**For each confirmed actor — derive candidate goals from PRD goals section:**
> "The PRD goals most relevant to [actor] suggest these use case goals:
>
> 1. **[Goal derived from PRD for this actor]** *(recommended)*
> 2. **[Second derived goal]**
> 3. Other — describe your own
>
> What is the most critical thing [actor] needs to accomplish?"

**For each confirmed goal — derive candidate main flow steps from the PRD problem and goal descriptions:**
> "For [actor] accomplishing [goal], a likely main flow would be:
>
> 1. [Step derived from PRD or domain context]
> 2. [Step 2]
> 3. [Step 3]
>
> Does this match? What steps are wrong or missing? The main flow needs at least 3 concrete steps."

**For alternative flows — derive candidates from PRD risks and problem description:**
> "For the step '[step]' in this flow, likely failure modes are:
>
> 1. **[Failure derived from PRD risks or problem domain]** *(recommended)*
> 2. **[Second failure mode]**
> 3. Other — describe your own
>
> What does [actor] do when this step fails? At least one alternative flow is required per use case."

**For preconditions — derive candidates from the goal and system context:**
> "Before [actor] can start this use case, the following must be true:
>
> 1. **[Precondition derived from use case context or PRD]** *(recommended)*
> 2. **[Second precondition]**
> 3. Other — describe your own"

**For postconditions — derive from the goal statement and PRD success metrics:**
> "When this use case completes successfully, the system state will be:
>
> 1. **[Postcondition derived from goal and PRD]** *(recommended)*
> 2. **[Second postcondition]**
> 3. Other — describe your own"

**Coverage check before proceeding:**
- Every PRD goal maps to at least one use case → if not, ask in candidate-first format: "The PRD lists '[goal]' — which use case covers this, or should we add one?"
- Every use case has at least one alternative flow → if not, ask for it in candidate-first format
- Every use case has explicit preconditions → if not, ask in candidate-first format

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The alternative flows are obvious" | Alternative flows that aren't written don't get implemented. Write them. |
| "This PRD goal is covered implicitly by another use case" | Implicit coverage is invisible coverage. Map it explicitly or explain why the goal is no longer valid. |
| "Preconditions are just common sense" | Engineers implement what is written. Common sense preconditions become bugs. |

---

## Template

Use `templates/use-cases.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
