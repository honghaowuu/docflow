# DocFlow

AI-assisted documentation pipeline for Claude Code. DocFlow guides you through generating 8 software design documents in dependency order — from product requirements to test specifications — with structured AI debate, human review annotations, and git-tracked approval.

---

## How It Works

DocFlow uses a layered architecture:

1. **SessionStart hook** — Auto-loads the orchestrator context whenever a DocFlow project is detected in the working directory
2. **`/docflow:start`** — The entry skill. Triggers status check, change detection, and presents available actions. The hook has already loaded all instructions, so the skill body is a one-line trigger.
3. **`docflow:<doc>`** — Runs guided or fast intake for a specific document, then hands off to the pipeline
4. **`docflow:pipeline`** — Generates, annotates, collects human review, strips annotations, and commits the clean document

Every document is generated with three annotation types per section (AI Reasoning, Assumption, Review focus), reviewed by a human, then committed clean. No document is committed without explicit approval.

---

## The Document Pipeline

Documents are generated in dependency order:

```
Level 0   prd.md                   Product Requirements
Level 1   use-cases.md             Use Cases
Level 2   ux-flow.md               UX Flow
          domain-model.md          Domain Model
Level 3   ui-spec.md               UI Specification
          api-spec.yaml            API Specification
Level 4   api-implement-logic.md   API Implementation Logic
          test-spec.md             Test Specification
```

A document cannot be generated until all its dependencies are approved.

---

## Getting Started

### 1. Install the plugin

```bash
# Add the DocFlow marketplace (once per machine)
claude plugin marketplace add github:honghaowu/docflow

# Install in your project
claude plugin install docflow --scope local

# Or install globally for all projects
claude plugin install docflow --scope user
```

### 2. Initialize DocFlow

```
init docflow
```

This creates `.docflow/status.yaml` tracking the approval state of all 8 documents.

### 3. Start a session

```
/docflow:start
```

Claude will show a status table and offer the next available actions.

---

## Generating Documents

### PRD — Adversarial Debate

`docflow:prd` runs a multi-phase adversarial debate to produce the PRD:

1. **Intent clarification** — structured dialogue to pin down scope, users, constraints, and success criteria
2. **Framework design** — custom 4-7 phase debate framework tailored to your topic
3. **Debate loop** — an Opus proposer and Sonnet reviewer run 2-5 rounds per phase; the host judges convergence using 3-of-5 criteria
4. **Backtracking validation** — after each phase, prior commitments are checked for contradictions, scope loss, or priority drift
5. **Synthesis** — all phase consensus documents are combined into `docs/prd.md` and core commitments are extracted to `.docflow/commitments.md`

Session state is persisted to `.docflow/debate/<slug>/` so debates can be paused and resumed.

### Downstream Documents — Two Modes

**Guided mode** — Claude asks candidate-first questions, deriving options from your prior answers and upstream documents. Each question presents a numbered list with one option marked `*(recommended)*`. You confirm, adjust, or pick "Other".

**Fast mode** — Claude reads all approved dependency documents and generates the new document directly, skipping intake. Only available when all dependencies are approved.

Both modes run a **Consistency Check** before generation: if `.docflow/commitments.md` exists, Claude verifies the upstream documents do not contradict any PRD commitment before proceeding.

---

## Document Skills

| Skill | Document | Dependencies |
|---|---|---|
| `docflow:prd` | `docs/prd.md` | none |
| `docflow:use-cases` | `docs/use-cases.md` | prd.md |
| `docflow:ux-flow` | `docs/ux-flow.md` | prd.md, use-cases.md |
| `docflow:domain-model` | `docs/domain-model.md` | prd.md, use-cases.md |
| `docflow:ui-spec` | `docs/ui-spec.md` | prd.md, ux-flow.md |
| `docflow:api-spec` | `docs/api-spec.yaml` | use-cases.md, domain-model.md, ux-flow.md |
| `docflow:api-implement-logic` | `docs/api-implement-logic.md` | use-cases.md, api-spec.yaml, domain-model.md |
| `docflow:test-spec` | `docs/test-spec.md` | use-cases.md, api-spec.yaml, domain-model.md |

---

## The Review Cycle

Each generated document is written to `docs/` as an annotated draft. Every section includes:

```markdown
<!-- AI Generated -->
[generated content]

> **AI Reasoning:** what inputs produced this content
> **Assumption:** any inference you must validate (or "None")
> **Review focus:** the single most important question to answer

<!-- Human Review Required -->
[ ] Confirmed
```

You review in your editor, request changes if needed, then tell Claude you approve. Claude strips all annotations and commits the clean document.

---

## Iron Laws

The pipeline enforces three non-negotiable constraints:

```
NO DOCUMENT WRITTEN TO DISK WITH UNFILLED TEMPLATE SECTIONS
NO DOCUMENT WRITTEN TO DISK WITHOUT ALL THREE ANNOTATION TYPES
NO CLEAN DOCUMENT COMMITTED WITHOUT HUMAN APPROVAL
```

And the orchestrator enforces a fourth:

```
NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED
```

---

## Project Structure

```
.
├── .claude-plugin/
│   ├── plugin.json         # Plugin manifest
│   └── marketplace.json    # Marketplace descriptor (enables github install)
├── settings.json           # Default permissions granted when plugin is enabled
├── skills/
│   ├── start/              # Entrypoint — triggers the session-start orchestrator
│   ├── pipeline/           # Shared generate → review → commit pipeline
│   ├── prd/
│   │   ├── SKILL.md        # Debate orchestration (Opus proposer + Sonnet reviewer)
│   │   └── references/     # 11 protocol docs (intent-clarification, framework-design,
│   │                       #   phase-progression, backtracking-algorithm, proposer-protocol,
│   │                       #   reviewer-protocol, context-management, session-recovery,
│   │                       #   prd-template, proposer-decomposition, reviewer-decomposition)
│   ├── use-cases/
│   ├── ux-flow/
│   ├── domain-model/
│   ├── ui-spec/
│   ├── api-spec/
│   ├── api-implement-logic/
│   └── test-spec/
├── templates/              # Document templates with annotation markers
├── hooks/
│   ├── session-start       # SessionStart hook (detects project, injects context)
│   └── start-context.md    # Orchestrator instructions injected by the hook
├── tests/
│   └── validate.sh         # Structural validation (120 checks)
└── .docflow/
    ├── status.yaml         # Per-document approval state (created on init)
    ├── commitments.md      # Core commitments extracted from PRD debate
    ├── intent-brief.md     # Clarified intent from debate Phase 2
    └── debate/
        └── <slug>/         # Per-debate workspace (state, phases, output)
```

---

## Running Validation

```bash
bash tests/validate.sh
```

Checks all 120 structural requirements: file existence, skill frontmatter, Iron Laws, candidate-first pattern, pipeline handoffs, routing, template markers, hook configuration, PRD debate patterns, reference file existence, and downstream consistency check gates.
