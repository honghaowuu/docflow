# DocFlow

AI-assisted documentation pipeline for Claude Code. DocFlow guides you through generating 8 software design documents in dependency order — from product requirements to test specifications — with structured AI questioning, human review annotations, and git-tracked approval.

---

## How It Works

DocFlow uses a layered skill architecture:

1. **`docflow:start`** — Checks project status, detects upstream changes, and presents what you can generate next
2. **`docflow:<doc>`** — Runs guided or fast intake for a specific document, then hands off to the pipeline
3. **`docflow:pipeline`** — Generates, annotates, collects human review, strips annotations, and commits the clean document

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
docflow start
```

Claude will show a status table and offer the next available actions.

---

## Generating Documents

DocFlow offers two modes for every document (except `prd.md`, which is always guided):

**Guided mode** — Claude asks candidate-first questions, deriving options from your prior answers and upstream documents. Each question presents a numbered list with one option marked `*(recommended)*`. You confirm, adjust, or pick "Other".

**Fast mode** — Claude reads all approved dependency documents and generates the new document directly, skipping intake. Only available when all dependencies are approved.

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
│   ├── start/              # Orchestrator
│   ├── pipeline/           # Shared generate → review → commit pipeline
│   ├── prd/
│   ├── use-cases/
│   ├── ux-flow/
│   ├── domain-model/
│   ├── ui-spec/
│   ├── api-spec/
│   ├── api-implement-logic/
│   └── test-spec/
├── templates/              # Document templates with annotation markers
├── hooks/                  # SessionStart hook
├── tests/
│   └── validate.sh         # Structural validation (97 checks)
└── .docflow/
    └── status.yaml         # Per-document approval state (created on init)
```

---

## Running Validation

```bash
bash tests/validate.sh
```

Checks all 97 structural requirements: file existence, skill frontmatter, Iron Laws, candidate-first pattern, pipeline handoffs, routing, template markers, and hook configuration.
