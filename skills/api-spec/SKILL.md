---
name: docflow:api-spec
description: Use when the user wants to generate or regenerate the API Specification document (api-spec.yaml) for a DocFlow project
---

# Generate API Specification

**Announce at start:** "I'm using docflow:api-spec to generate the API Specification."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `use-cases.md`, `domain-model.md`, and `ux-flow.md` all have `status: approved`.

If any is not approved, identify which document is missing and tell the user:
> "Cannot generate api-spec.yaml — [name the specific missing document] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

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

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/use-cases.md`, `docs/domain-model.md`, and `docs/ux-flow.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Endpoints | One endpoint per use-case action that requires a system call | Every use-case step that mutates state or fetches data must map to an endpoint |
| Request schemas | Input fields per endpoint | Field names and types derived from domain model entity attributes |
| Response schemas | Output structure per endpoint | Must include both success shape and error shape |
| Error codes | HTTP status codes per endpoint | At least one error response per endpoint |
| Authentication | Which endpoints require auth and what mechanism | Must be explicit — "standard auth" is not acceptable |

---

## Candidate-First Questioning

Read `docs/use-cases.md`, `docs/domain-model.md`, and `docs/ux-flow.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Note:** `api-spec.yaml` is a YAML document. When calling `docflow:pipeline`, specify that annotations should use YAML comment format (`# AI Reasoning:`, `# Assumption:`, `# Review focus:`).

**Opening question — derive candidate endpoints from use-case main flow action verbs:**
> "Based on the use cases, I've identified these candidate API endpoints (one per state-mutating or data-fetching action):
>
> 1. **POST /[resource]** — [use-case action, e.g. create order] *(recommended)*
> 2. **GET /[resource]/{id}** — [fetch action]
> 3. **PUT /[resource]/{id}** — [update action]
> 4. **DELETE /[resource]/{id}** — [delete action if applicable]
> N. Other — describe your own
>
> Which endpoints are needed? You can rename paths, adjust methods, or add your own."

**For each confirmed endpoint — derive candidate request fields from domain model attributes:**
> "For **[Method] [Path]**, the domain model suggests these request body fields:
>
> 1. **[Attribute from domain entity]** (type: [type], required: true) *(recommended)*
> 2. **[Second attribute]** (type: [type], required: [true/false])
> N. Other — describe your own
>
> Which fields are correct? Add type and required status for each."

**For each endpoint — derive candidate response shapes from domain model entities:**
> "For the success response of **[Method] [Path]**:
>
> 1. **HTTP [status] with [entity] object** *(recommended — matches domain model shape)*
> 2. **HTTP [status] with [minimal/id-only] shape**
> N. Other — describe your own"

**For error codes — derive candidates from use-case alternative flows and domain model invariants:**
> "For **[Method] [Path]**, likely error responses based on the use cases and invariants:
>
> 1. **400 Bad Request** — invalid input *(recommended — always required for mutating endpoints)*
> 2. **401 Unauthorized** — missing or invalid auth (if auth required)
> 3. **404 Not Found** — [resource] does not exist
> 4. **409 Conflict** — [invariant violation from domain model]
> N. Other — describe your own
>
> Which error codes apply?"

**For authentication — derive from the PRD target users and security context:**
> "Which endpoints require authentication?
>
> 1. **All endpoints** *(recommended — default for most products)*
> 2. All except: [specific public endpoints, e.g. GET /products]
> 3. None — this API is fully public
> N. Other — describe your own"

**Coverage check before proceeding:**
- Every use-case step that mutates state maps to an endpoint
- Every use-case step that fetches data for display maps to an endpoint
- Every endpoint has at least one error response
- Authentication requirement is explicit for every endpoint

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The request fields are obvious from the entity name" | Undefined fields become inconsistent API contracts. List every field with its type. |
| "We only need the happy path response" | API consumers must handle errors. Every endpoint needs at least one error response defined. |
| "Auth requirement is obvious" | Unstated auth requirements become security gaps. State it explicitly for every endpoint. |
| "This use-case action doesn't need its own endpoint" | If the use case mutates state, it needs an endpoint. If it fetches data, it needs an endpoint. |

---

## Template

Use `templates/api-spec.yaml`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/use-cases.md` content as dependency
- `docs/domain-model.md` content as dependency
- `docs/ux-flow.md` content as dependency
- Specify: this is a YAML document — use YAML comment annotation format

**REQUIRED SUB-SKILL:** `docflow:pipeline`
