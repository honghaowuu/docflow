---
name: docflow:api-implement-logic
description: Use when the user wants to generate or regenerate the API Implementation Logic document (api-implement-logic.md) for a DocFlow project
---

# Generate API Implementation Logic

**Announce at start:** "I'm using docflow:api-implement-logic to generate the API Implementation Logic document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `use-cases.md`, `api-spec.yaml`, and `domain-model.md` all have `status: approved`.

If any is not approved, identify which document is missing and tell the user:
> "Cannot generate api-implement-logic.md — [name the specific missing document] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

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

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected for every endpoint in api-spec.yaml before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Business rules | Per-endpoint logic that the schema alone does not express | At least one business rule per endpoint |
| Data transformations | How input data is mapped, validated, or enriched before persistence | Required for any endpoint that stores or modifies data |
| Side effects | Non-obvious actions triggered by the endpoint (emails, events, background jobs) | Must be explicit — omitted side effects become bugs |
| Sequencing | Order-dependent operations within an endpoint | Required whenever multiple writes or external calls occur |
| Invariant checks | Which domain model invariants this endpoint must enforce | Every domain invariant relevant to the endpoint's entities must appear |

---

## Candidate-First Questioning

Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` before asking any question.

Ask one question per message. Iterate through each endpoint in api-spec.yaml. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**For each endpoint — derive candidate business rules from domain model invariants and use-case pre/postconditions:**
> "For **[Method] [Path]**, the domain model and use cases suggest these business rules:
>
> 1. **[Rule derived from domain invariant or use-case precondition]** *(recommended)*
> 2. **[Second rule]**
> N. Other — describe your own
>
> Which rules must this endpoint enforce? At least one is required."

**For data transformations — derive from domain model attribute types and use-case input descriptions:**
> "For **[Method] [Path]**, the following data transformations are likely needed before persistence:
>
> 1. **Validate [field] is [type/constraint from domain model]** *(recommended)*
> 2. **Enrich [field] with [derived value]**
> 3. None — data is stored as-is
> N. Other — describe your own"

**For side effects — derive from use-case postconditions and PRD goals:**
> "After **[Method] [Path]** succeeds, these side effects may occur based on the use cases:
>
> 1. **[Side effect derived from use-case postcondition, e.g. send confirmation email]** *(recommended)*
> 2. **[Second side effect, e.g. emit domain event]**
> 3. None
> N. Other — describe your own
>
> Which side effects apply? Unwritten side effects become missing features."

**For sequencing — derive from use-case step ordering and domain constraints:**
> "For **[Method] [Path]**, operations must happen in this order:
>
> 1. **[Step order derived from domain invariants and use-case flow]** *(recommended)*
> 2. [Alternative ordering]
> 3. No ordering constraint — operations are independent
> N. Other — describe your own"

**For invariant checks — derive directly from domain model invariants for this endpoint's entities:**
> "The domain model defines these invariants relevant to **[Method] [Path]**:
>
> 1. **[Invariant from domain model for affected entity]** *(recommended — must be enforced)*
> 2. **[Second invariant]**
> N. Other — describe your own
>
> Which invariants must this endpoint check before writing?"

**Coverage check before proceeding:**
- Every endpoint in api-spec.yaml has at least one business rule
- Every endpoint that writes data has explicit data transformation steps
- Every endpoint has explicit side effects (or explicitly "none")
- Every domain invariant for the affected entities appears in at least one endpoint's invariant check list

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The business rules are just the schema validation" | Schema validation is not a business rule. Business rules are the constraints the schema cannot express. |
| "There are no side effects for this endpoint" | Ask again: does success trigger an email? An event? A job? A cache invalidation? Default to "none" only after explicitly checking each. |
| "The sequencing is obvious" | Unwritten operation order becomes a race condition or data integrity bug under load. Write it. |
| "The invariant checks happen in the database" | Document them here regardless. The implementation logic document is for humans, not the database. |

---

## Template

Use `templates/api-implement-logic.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/use-cases.md` content as dependency
- `docs/api-spec.yaml` content as dependency
- `docs/domain-model.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
