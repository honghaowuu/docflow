# DocFlow AI Plugin — Design Spec

**Date:** 2026-04-16
**Scope:** MVP — 3 foundational document skills (prd, use-cases, domain-model)
**Platform:** Claude Code only

---

## 1. Overview

DocFlow is a Claude Code plugin that transforms business intent into structured engineering artifacts through AI-assisted generation and human validation. It behaves like a documentation compiler: documents are source artifacts, skills are compiler passes, the dependency graph is the build system, and review is the validation layer.

---

## 2. Architecture

### Plugin File Structure

```
docflow/
├── package.json                    # Plugin manifest
├── hooks/
│   ├── hooks.json                  # Claude Code hook registration
│   └── session-start               # Injects docflow:start into session context
├── skills/
│   ├── start/
│   │   └── SKILL.md                # Orchestrator — project status + next action
│   ├── pipeline/
│   │   └── SKILL.md                # Shared pipeline: intake→generate→review→commit
│   ├── prd/
│   │   └── SKILL.md                # PRD-specific: questions, template, validation
│   ├── use-cases/
│   │   └── SKILL.md                # Use-cases-specific
│   └── domain-model/
│       └── SKILL.md                # Domain-model-specific
└── templates/
    ├── prd.md
    ├── use-cases.md
    └── domain-model.md
```

### Project Directory (in each DocFlow-managed project)

```
<project>/
├── docs/
│   ├── prd.md
│   ├── use-cases.md
│   └── domain-model.md
└── .docflow/
    └── status.yaml                 # Committed to git — approval states
```

### Component Relationships

```
SessionStart hook
  → injects docflow:start content
    → agent reads status.yaml + git log
      → presents project state, suggests next step
        → user picks a document
          → agent invokes docflow:<doc> skill
            → docflow:<doc> hands off to docflow:pipeline
              → pipeline runs: intake → generate → review → commit
                → status.yaml updated, changes committed
```

---

## 3. State Model

### `.docflow/status.yaml`

```yaml
version: 1
documents:
  prd.md:
    status: approved          # draft | approved | outdated | missing
    generated_at: 2026-04-16T10:23:00Z
    approved_at: 2026-04-16T10:45:00Z
    content_hash: sha256:abc123   # hash of file at approval time

  use-cases.md:
    status: outdated
    generated_at: 2026-04-16T11:00:00Z
    approved_at: 2026-04-16T11:15:00Z
    content_hash: sha256:def456
    outdated_because:
      - prd.md changed after approval

  domain-model.md:
    status: missing
```

### Change Detection Logic

Run by `docflow:start` at every session start:

1. Read `status.yaml` — get `approved_at` timestamp for each document
2. For each approved document, run `git log --since="<approved_at>" -- <dependency_file>` for each of its dependencies
3. If any dependency has commits after the document's `approved_at` → mark document `outdated`, record which dependency caused it in `outdated_because`
4. If `sha256(current file) != content_hash` → warn user that the file was manually edited; ask whether to preserve edits or regenerate cleanly
5. Write updated status.yaml if anything changed, commit with `docflow: update impact status`

### Dependency Graph (MVP)

```
prd.md:          requires: []
use-cases.md:    requires: [prd.md]
domain-model.md: requires: [prd.md, use-cases.md]
```

---

## 4. Skills

### `docflow:start` — Orchestrator

**Triggered by:** SessionStart hook (injected into every session)

**Behaviour:**
1. Check for `.docflow/status.yaml` — if missing, emit: *"No DocFlow project found. Say 'init docflow' to initialize."* and stop
2. Run change detection (see Section 3)
3. Present status table:

```
DocFlow Project Status

  prd.md          ✓ approved
  use-cases.md    ⚠ outdated (prd.md changed)
  domain-model.md   missing

What would you like to do?
1. Generate domain-model.md (dependencies met)
2. Regenerate use-cases.md (outdated)
3. Review prd.md again
4. Show full dependency graph
```

4. Block generation if dependencies are not `approved`. This is an Iron Law — no exceptions.

**REQUIRED SUB-SKILL:** `docflow:pipeline` (via document skills)

---

### `docflow:pipeline` — Shared Pipeline

**Triggered by:** document skills via `REQUIRED SUB-SKILL`

**Receives:** document type, template path, collected intake answers, dependency file contents

**Pipeline steps:**

1. **Generate** — fill all `<!-- AI Generated -->` template sections using intake answers and dependency content. Iron Law: every section must be filled. A document with any unfilled template markers must not proceed.
2. **Annotate** — add three instructive annotations to every generated section:
   - `> **AI Reasoning:**` — what inputs and logic produced this content
   - `> **Assumption:**` — any inference made that the human should explicitly validate
   - `> **Review focus:**` — the specific question the reviewer should answer before confirming
3. **LLM self-review** — check for missing sections, logical inconsistencies, dependency alignment; fix inline before writing
4. **Write annotated draft** — save to `docs/<doc>`
5. **Offer path for review** — tell user: *"Generated `docs/<doc>` — please open and review it. Let me know if you'd like changes or are ready to approve."*
6. **Wait for user response:**
   - If changes requested → apply edits, rewrite annotated draft, return to step 5
   - If approved → proceed to step 7
7. **Strip annotations** — remove all `> **AI Reasoning:**`, `> **Assumption:**`, `> **Review focus:**` blocks and `<!-- Human Review Required -->` / `[ ] Confirmed` markers
8. **Write clean doc** — overwrite `docs/<doc>` with annotation-free content
9. **Update status.yaml** — set `status: approved`, record `content_hash` of clean file, set `approved_at` timestamp
10. **Commit** — `git add docs/<doc> .docflow/status.yaml` + `git commit -m "docflow: generate <doc>"`

---

### `docflow:prd` — PRD Document Skill

**Required information to collect:**
- Problem being solved
- Target users (primary and secondary)
- Goals (must be measurable)
- Non-goals (must be explicit)
- Success metrics
- Risks and mitigations

**Dynamic questioning strategy:**
- Start: *"What problem does this product solve?"*
- If answer is vague → probe domain: *"Who experiences this problem most acutely, and what does it cost them?"*
- If answer is specific → move to users: *"Who are the primary users?"*
- Continue until all required information has sufficient coverage
- Never ask more than one question per turn

**Validation rules:**
- Goals must be measurable (reject vague goals like "improve experience")
- Non-goals section must be explicitly present
- Every risk must have a mitigation

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

### `docflow:use-cases` — Use-Cases Document Skill

**Dependency check:** `prd.md` must be `approved` before proceeding.

**Required information to collect:**
- Actors (from prd.md target users — confirm and extend)
- Use cases: for each — goal, preconditions, main flow, alternative flows, postconditions

**Dynamic questioning strategy:**
- Start by reading `prd.md` to derive initial actors and goals
- Start: *"Based on the PRD, I've identified these actors: [X, Y]. Are there others?"*
- For each actor: *"What is the most critical thing [actor] needs to accomplish?"*
- For each goal: walk through main flow, then ask about failure/alternative paths

**Validation rules:**
- Every PRD goal must map to at least one use case
- Every use case must have at least one alternative flow
- No use case without explicit preconditions

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

### `docflow:domain-model` — Domain Model Document Skill

**Dependency check:** `prd.md` and `use-cases.md` must both be `approved` before proceeding.

**Required information to collect:**
- Entities (nouns from use-cases) and their attributes
- Invariants per entity (rules that must always hold)
- Relationships between entities
- Glossary of domain terms

**Dynamic questioning strategy:**
- Start by extracting candidate entities from `use-cases.md` nouns
- Start: *"I've identified these candidate entities: [X, Y, Z]. Which of these are core domain concepts vs. UI/infrastructure concerns?"*
- For each confirmed entity: *"What are the essential attributes of [entity]? What rules must always be true about it?"*
- For relationships: *"How does [entity A] relate to [entity B]?"*

**Validation rules:**
- Every entity from use-cases must be accounted for (included or explicitly excluded with reason)
- Every relationship must have cardinality defined
- Glossary must cover all domain-specific terms used in the document

**REQUIRED SUB-SKILL:** `docflow:pipeline`

---

## 5. Templates

Each template uses `<!-- AI Generated -->` and `<!-- Human Review Required -->` markers. The agent fills all `<!-- AI Generated -->` blocks and adds annotations before the `<!-- Human Review Required -->` marker. After approval, all markers and annotations are stripped.

### Pattern

```markdown
## Section Name
<!-- AI Generated -->

> **AI Reasoning:** ...
> **Assumption:** ...
> **Review focus:** ...

<!-- Human Review Required -->
[ ] Confirmed
```

### `templates/prd.md` sections
- Problem Statement
- Target Users
- Goals
- Non-Goals
- Success Metrics
- Risks & Mitigations

### `templates/use-cases.md` sections
- Actors
- Use Cases (repeating block per use case: Goal, Preconditions, Main Flow, Alternative Flows, Postconditions)

### `templates/domain-model.md` sections
- Entities (repeating block per entity: Attributes, Invariants)
- Relationships
- Glossary

---

## 6. Hook Architecture

### `hooks/hooks.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/session-start\"",
            "async": false
          }
        ]
      }
    ]
  }
}
```

### `hooks/session-start` behaviour

1. Check if `.docflow/status.yaml` exists in the current working directory
2. If not found → emit minimal prompt: *"No DocFlow project found. Say 'init docflow' to initialize."*
3. If found → read `skills/start/SKILL.md`, wrap in `<EXTREMELY_IMPORTANT>` tags, emit as `hookSpecificOutput.additionalContext`

---

## 7. Iron Laws

```
NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED FIRST
```

```
NO DOCUMENT WRITTEN TO DISK WITH UNFILLED TEMPLATE SECTIONS
```

```
NO DOCUMENT WRITTEN TO DISK WITHOUT ALL THREE ANNOTATION TYPES PER SECTION
```

```
NO CLEAN DOCUMENT COMMITTED WITHOUT HUMAN APPROVAL FIRST
```

---

## 8. Out of Scope (MVP)

The following are deferred to iteration 2:

- `ux-flow.md`, `ui-spec.md`, `api-spec.yaml`, `api-implement-logic.md`, `test-spec.md` skills
- Fast mode (generate from existing docs without guided intake)
- Repair mode (fix inconsistencies in existing documents)
- Skill composition (`generate-full-system`)
- CI integration

---

## 9. Iteration 2 Expansion Path

Adding a new document skill requires:
1. Create `skills/<doc>/SKILL.md` with required information, questioning strategy, validation rules, and `REQUIRED SUB-SKILL: docflow:pipeline`
2. Add template to `templates/<doc>`
3. Add dependency entry to `docflow:start` dependency graph
4. No changes to `docflow:pipeline` or hooks

The pipeline and orchestrator are designed to be extended without modification.
