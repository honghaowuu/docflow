# DocFlow Full Plugin — Design Spec

**Date:** 2026-04-16
**Scope:** Iteration 2 — 5 remaining document skills, candidate-first questioning, fast mode
**Platform:** Claude Code only
**Prior spec:** `2026-04-16-docflow-plugin-design.md` (MVP — 3 foundational skills)

---

## 1. Overview

This spec extends the DocFlow MVP to a full 8-document pipeline. Three changes are introduced:

1. **Candidate-first questioning** — all document skills replace open-ended questions with AI-derived numbered options and a recommended choice
2. **Fast mode** — generate any non-root document directly from its approved dependencies without guided intake
3. **5 new document skills** — ux-flow, ui-spec, api-spec, api-implement-logic, test-spec

The pipeline skill, hook, and templates system are unchanged. The orchestrator (`docflow:start`) and validation script are extended.

---

## 2. Candidate-First Questioning Pattern

### Rule

Before asking any intake question, the skill MUST:

1. Read all available dependency documents
2. Derive 2–5 candidate answers from their content
3. Present candidates as numbered options, marking one `(recommended)`
4. Include a final option: `[N]. Other — describe your own`
5. Wait for the human to pick a number, adjust an option, or describe their own

### Format

```
[Framing sentence — what you derived this from]

1. **[Candidate A]** *(recommended)*
2. **[Candidate B]**
3. **[Candidate C]**
4. Other — describe your own

Which apply? You can pick multiple, edit any, or add your own.
```

### Exception

The **opening question of `docflow:prd`** must remain open-ended — there are no prior documents to derive candidates from. All questions in `docflow:prd` after the first answer, and all questions in all other document skills, use candidate-first.

### Updates to existing skills

The three existing document skills (`docflow:prd`, `docflow:use-cases`, `docflow:domain-model`) must replace their current "decision tree" / "dynamic questioning" sections with candidate-first questioning following this pattern.

---

## 3. Fast Mode

### Trigger

Offered by `docflow:start` as an alternative option when a document's dependencies are all `approved`:

```
What would you like to do?
1. Generate domain-model.md (guided — recommended for first time)
2. Generate domain-model.md (fast — derive from dependencies)
```

Fast mode is never offered for `prd.md` — it has no dependencies to derive from.

### Behaviour

1. Document skill detects fast mode (passed from orchestrator)
2. Skip all intake questioning
3. Read all dependency documents in full
4. Pass dependency contents directly to `docflow:pipeline` as the sole generation input
5. Pipeline runs normally: generate → annotate → human review → strip → commit

The human review step is still mandatory in fast mode. The human can still request changes before approval.

---

## 4. New Document Skills

### Full Dependency Graph (all 8 documents)

```
prd.md:                 requires: []
use-cases.md:           requires: [prd.md]
ux-flow.md:             requires: [prd.md, use-cases.md]
domain-model.md:        requires: [prd.md, use-cases.md]
ui-spec.md:             requires: [prd.md, ux-flow.md]
api-spec.yaml:          requires: [use-cases.md, domain-model.md, ux-flow.md]
api-implement-logic.md: requires: [use-cases.md, api-spec.yaml, domain-model.md]
test-spec.md:           requires: [use-cases.md, api-spec.yaml, domain-model.md]
```

### Execution order (dependency levels)

```
Level 0: prd.md
Level 1: use-cases.md
Level 2: ux-flow.md, domain-model.md
Level 3: ui-spec.md, api-spec.yaml
Level 4: api-implement-logic.md, test-spec.md
```

---

### 4.1 `docflow:ux-flow`

**Dependencies:** `prd.md`, `use-cases.md`

**Required information:**

| Field | Description | Validation |
|---|---|---|
| User journeys | One journey per actor + primary goal pair from use-cases | Every use case main flow must map to a journey |
| Entry points | Where each journey begins (screen, event, or trigger) | Must be explicit — "app opens" is not sufficient |
| Transitions | State-to-state movements within each journey | Every step in the use case main flow must have a transition |
| Error states | What happens when a transition fails | At least one error state per journey |
| Exit points | How and where each journey ends | Must cover both success and failure exits |

**Candidate-first questioning strategy:**
- Derive candidate journeys from use-case main flows
- For transitions: derive from use-case steps, present as a flow sequence and ask what's missing
- For error states: derive from use-case alternative flows, present as candidates

**Template sections:** User Journeys (one repeating block per journey: Entry Point, Steps & Transitions, Error States, Exit Points)

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

### 4.2 `docflow:ui-spec`

**Dependencies:** `prd.md`, `ux-flow.md`

**Required information:**

| Field | Description | Validation |
|---|---|---|
| Screens | One screen per distinct UX state | Every UX flow step must map to a screen or shared component |
| Components | UI elements on each screen | Each component must have: name, purpose, interaction behaviour |
| State variations | How each screen or component changes based on data/user state | At least one state variation per interactive component |
| Interaction patterns | User actions and system responses | Every component with user interaction must define the response |

**Candidate-first questioning strategy:**
- Derive candidate screens from UX flow steps
- Derive candidate components from screen names and interactions described in UX flow
- For state variations: present common states (empty, loading, error, populated) as candidates

**Template sections:** Screens (repeating block per screen: Purpose, Components, State Variations, Interaction Patterns)

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

### 4.3 `docflow:api-spec`

**Dependencies:** `use-cases.md`, `domain-model.md`, `ux-flow.md`

**Required information:**

| Field | Description | Validation |
|---|---|---|
| Endpoints | One endpoint per use case action that requires a system call | Every use case main flow step that mutates state must map to an endpoint |
| Request schemas | Input fields per endpoint | Derived from domain model entity attributes |
| Response schemas | Output structure per endpoint | Must include both success and error shapes |
| Error codes | HTTP status codes and error identifiers per endpoint | At least one error response per endpoint |
| Authentication | Which endpoints require auth and what mechanism | Must be explicitly stated — "standard auth" is not acceptable |

**Candidate-first questioning strategy:**
- Derive candidate endpoints from use-case main flow action verbs (create, update, delete, fetch)
- Derive candidate request/response fields from domain model entity attributes
- For error codes: present standard HTTP error codes as candidates, ask which apply

**Template sections:** Endpoints (repeating block per endpoint: Method + Path, Request Schema, Response Schema, Error Codes, Auth Requirement)

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

### 4.4 `docflow:api-implement-logic`

**Dependencies:** `use-cases.md`, `api-spec.yaml`, `domain-model.md`

**Required information:**

| Field | Description | Validation |
|---|---|---|
| Business rules | Per-endpoint logic that cannot be derived from the schema alone | At least one business rule per endpoint |
| Data transformations | How input data is mapped, validated, or enriched before persistence | Required for any endpoint that stores or modifies data |
| Side effects | Non-obvious system actions triggered by an endpoint (emails, events, jobs) | Must be explicit — omitted side effects become bugs |
| Sequencing | Order-dependent operations within an endpoint | Required whenever multiple writes or external calls occur |
| Invariant enforcement | Which domain model invariants this endpoint must check | Every domain invariant relevant to the endpoint's entities must be listed |

**Candidate-first questioning strategy:**
- Derive candidate business rules from domain model invariants and use-case preconditions/postconditions
- Derive candidate side effects from use-case alternative flows and postconditions
- For sequencing: derive from use-case step order and present as an ordered list to confirm/adjust

**Template sections:** Endpoints (repeating block per endpoint: Business Rules, Data Transformations, Side Effects, Sequencing, Invariant Checks)

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

### 4.5 `docflow:test-spec`

**Dependencies:** `use-cases.md`, `api-spec.yaml`, `domain-model.md`

**Required information:**

| Field | Description | Validation |
|---|---|---|
| Happy path scenarios | One scenario per use case main flow | Every use case must have at least one happy path test |
| Negative path scenarios | Tests for invalid inputs, missing auth, constraint violations | At least one negative path per endpoint |
| Edge cases | Boundary conditions from domain model invariants | Every invariant must have a corresponding edge case test |
| Acceptance criteria | Explicit pass/fail conditions per scenario | Every scenario must have measurable acceptance criteria |

**Candidate-first questioning strategy:**
- Derive happy path scenarios from use-case main flows
- Derive negative paths from use-case alternative flows and domain model invariants
- For edge cases: derive from invariants (e.g., "Order must have at least one item" → test: empty order)
- For acceptance criteria: derive from use-case postconditions and api-spec response schemas

**Template sections:** Test Scenarios (repeating block per scenario: Type, Steps, Input, Expected Output, Acceptance Criteria)

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

## 5. Orchestrator Updates (`docflow:start`)

### `status.yaml` initialization

Add all 8 documents to the init block:

```yaml
version: 1
documents:
  prd.md:                 status: missing
  use-cases.md:           status: missing
  ux-flow.md:             status: missing
  domain-model.md:        status: missing
  ui-spec.md:             status: missing
  api-spec.yaml:          status: missing
  api-implement-logic.md: status: missing
  test-spec.md:           status: missing
```

### Status table

Show all 8 documents in dependency order (Level 0 → Level 4).

### Dependency graph

Update to the full 8-document graph from Section 4.

### Menu options

When a document's dependencies are approved, offer both guided and fast mode:

```
What would you like to do?
1. Generate [doc] — guided (recommended for first time)
2. Generate [doc] — fast (derive from dependencies)
3. Regenerate [outdated doc] — guided
4. Regenerate [outdated doc] — fast
```

### Routing

Add 5 new routes:

- Generate / regenerate `ux-flow.md` → **REQUIRED SUB-SKILL:** `docflow:ux-flow`
- Generate / regenerate `ui-spec.md` → **REQUIRED SUB-SKILL:** `docflow:ui-spec`
- Generate / regenerate `api-spec.yaml` → **REQUIRED SUB-SKILL:** `docflow:api-spec`
- Generate / regenerate `api-implement-logic.md` → **REQUIRED SUB-SKILL:** `docflow:api-implement-logic`
- Generate / regenerate `test-spec.md` → **REQUIRED SUB-SKILL:** `docflow:test-spec`

---

## 6. New Templates

Five new template files following the existing `<!-- AI Generated -->` / `<!-- Human Review Required -->` pattern:

- `templates/ux-flow.md` — sections: User Journeys (repeating: Entry Point, Steps & Transitions, Error States, Exit Points)
- `templates/ui-spec.md` — sections: Screens (repeating: Purpose, Components, State Variations, Interaction Patterns)
- `templates/api-spec.yaml` — sections: Endpoints (repeating: Method/Path, Request Schema, Response Schema, Error Codes, Auth). **Marker exception:** uses `# AI Generated` and `# Human Review Required` YAML comment markers instead of HTML comment markers — YAML does not support HTML comments.
- `templates/api-implement-logic.md` — sections: Endpoints (repeating: Business Rules, Data Transformations, Side Effects, Sequencing, Invariant Checks)
- `templates/test-spec.md` — sections: Test Scenarios (repeating: Type, Steps, Input, Expected Output, Acceptance Criteria)

---

## 7. Validation Script Updates (`tests/validate.sh`)

Add checks for:

- File existence: 5 new skills + 5 new templates
- Frontmatter: `name:` and `description: Use when` for all 5 new skills
- REQUIRED SUB-SKILL handoffs: all 5 new skills hand off to `docflow:pipeline`
- Template markers: `<!-- AI Generated -->` and `<!-- Human Review Required -->` in the 4 new `.md` templates; `# AI Generated` and `# Human Review Required` in `templates/api-spec.yaml`

---

## 8. Out of Scope (Next Iteration)

The following are explicitly deferred:

- **Repair mode** — fix inconsistencies in existing documents without full regeneration
- **Skill composition** — `docflow:generate-all` that chains all 8 skills in dependency order
- **CI integration** — doc validation pipeline as a CI check

---

## 9. File Changes Summary

**New files:**
- `skills/ux-flow/SKILL.md`
- `skills/ui-spec/SKILL.md`
- `skills/api-spec/SKILL.md`
- `skills/api-implement-logic/SKILL.md`
- `skills/test-spec/SKILL.md`
- `templates/ux-flow.md`
- `templates/ui-spec.md`
- `templates/api-spec.yaml`
- `templates/api-implement-logic.md`
- `templates/test-spec.md`

**Modified files:**
- `skills/start/SKILL.md` — full dependency graph, all 8 documents, guided/fast menu, 5 new routes
- `skills/prd/SKILL.md` — replace decision-tree questioning with candidate-first pattern
- `skills/use-cases/SKILL.md` — replace decision-tree questioning with candidate-first pattern
- `skills/domain-model/SKILL.md` — replace decision-tree questioning with candidate-first pattern
- `tests/validate.sh` — add checks for all new files and handoffs
