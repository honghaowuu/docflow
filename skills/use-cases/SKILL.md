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

## Dynamic Questioning

Ask one question at a time. Never ask more than one question per message.

**Start by reading `docs/prd.md`** — extract target users as candidate actors and goals as candidate use case goals.

**Opening question:**
> "Based on the PRD, I've identified these actors: [list from prd.md target users]. Are there others, or should any of these be renamed or split into more specific roles?"

**For each confirmed actor:**
> "What is the most critical thing [actor] needs to accomplish with this product?"

**For each goal identified per actor, walk through the use case:**

1. > "Walk me through the steps [actor] takes to accomplish [goal]. What do they do first?"
   Continue prompting until the main flow has at least 3 concrete steps.

2. > "What could go wrong at any step in that flow? What does [actor] do when it fails?"
   Capture at least one alternative flow per use case.

3. > "What must be true before [actor] can start this use case? Any system state or prerequisites?"

4. > "What is the exact state of the system when this use case completes successfully?"

**Coverage check before proceeding:**
- Every PRD goal maps to at least one use case → if not, ask: "The PRD lists '[goal]' — which use case covers this?"
- Every use case has at least one alternative flow → if not, ask: "What happens if [step] fails in UC-[N]?"
- Every use case has explicit preconditions → if not, ask: "What must be true before [actor] can start UC-[N]?"

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
