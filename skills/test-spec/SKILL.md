---
name: docflow:test-spec
description: Use when the user wants to generate or regenerate the Test Specification document (test-spec.md) for a DocFlow project
---

# Generate Test Specification

**Announce at start:** "I'm using docflow:test-spec to generate the Test Specification document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `use-cases.md`, `api-spec.yaml`, and `domain-model.md` all have `status: approved`.

If any is not approved, identify which document is missing and tell the user:
> "Cannot generate test-spec.md — [name the specific missing document] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Happy path scenarios | One scenario per use-case main flow | Every use case must have at least one happy path test |
| Negative path scenarios | Tests for invalid inputs, missing auth, constraint violations | At least one negative path per endpoint in api-spec.yaml |
| Edge cases | Boundary conditions from domain model invariants | Every invariant must have a corresponding edge case test |
| Acceptance criteria | Explicit pass/fail conditions per scenario | Every scenario must have measurable acceptance criteria |

---

## Candidate-First Questioning

Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate happy path scenarios from use-case main flows:**
> "Based on the use cases, I've identified these candidate happy path test scenarios:
>
> 1. **[UC-1 main flow as a test scenario]** *(recommended)*
> 2. **[UC-2 main flow as a test scenario]**
> 3. [Additional use case]
> N. Other — describe your own
>
> Which scenarios should be included? Every use case must have at least one."

**For each happy path scenario — derive candidate steps and inputs from the use-case main flow:**
> "For the **[Scenario Name]** scenario, the use-case main flow maps to these test steps:
>
> 1. [Step 1 from main flow with test input]
> 2. [Step 2]
> 3. [Step 3]
>
> Does this match? What steps or inputs need adjustment?"

**For acceptance criteria — derive from use-case postconditions and api-spec response schemas:**
> "For **[Scenario Name]**, the test passes when:
>
> 1. **[Postcondition from use case as a measurable assertion]** *(recommended)*
> 2. **[API response check from api-spec success shape]**
> N. Other — describe your own
>
> Which criteria must pass for this scenario to be considered successful?"

**For negative path scenarios — derive from use-case alternative flows and api-spec error codes:**
> "Based on the use-case alternative flows and api-spec error codes, these negative path scenarios are needed:
>
> 1. **[Alt flow 1 as a test: invalid input → 400]** *(recommended)*
> 2. **[Missing auth → 401]** (if endpoint requires auth)
> 3. **[Resource not found → 404]**
> 4. **[Invariant violation → 409]** (if domain model has a relevant invariant)
> N. Other — describe your own
>
> Which negative paths must be tested? At least one per endpoint."

**For edge cases — derive directly from domain model invariants:**
> "The domain model defines these invariants that need edge case tests:
>
> 1. **[Invariant A] → test: [boundary condition that would violate it]** *(recommended)*
> 2. **[Invariant B] → test: [its boundary condition]**
> N. Other — describe your own
>
> Which edge cases should be included? Every invariant needs a test."

**Coverage check before proceeding:**
- Every use case has at least one happy path scenario
- Every endpoint in api-spec.yaml has at least one negative path scenario
- Every domain model invariant has at least one edge case test
- Every scenario has explicit, measurable acceptance criteria

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The negative paths are obvious from the error codes" | Obvious tests that aren't written don't get run. Write the scenario. |
| "This invariant doesn't need its own test" | Invariants without tests get violated in production. One test per invariant, no exceptions. |
| "The acceptance criteria is just 'it works'" | Untestable acceptance criteria means the test cannot be automated or reviewed. Define what observable state proves success. |
| "Happy path tests are enough" | Use-case alternative flows document the failure modes your users will encounter. Test them. |

---

## Template

Use `templates/test-spec.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/use-cases.md` content as dependency
- `docs/api-spec.yaml` content as dependency
- `docs/domain-model.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
