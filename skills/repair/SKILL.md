---
name: docflow:repair
description: Use when a DocFlow document is outdated and you want to fix only the sections affected by dependency changes without full regeneration
---

# DocFlow Repair

**Announce at start:** "I'm using docflow:repair to patch [doc] against updated dependencies."

---

## Step 1: Load Context

Read the outdated document: `docs/<doc>`

Read `.docflow/status.yaml` to get `approved_at` for this document.

---

## Step 2: Diff Changed Dependencies

For each dependency listed in `outdated_because` in `status.yaml`, run:

```bash
git diff <approved_at>..HEAD -- docs/<dependency>
```

Collect all diffs. If `outdated_because` is empty, diff all declared dependencies against `approved_at`.

Dependency graph for reference:
- `use-cases.md` → `prd.md`
- `ux-flow.md` → `prd.md`, `use-cases.md`
- `domain-model.md` → `prd.md`, `use-cases.md`
- `ui-spec.md` → `prd.md`, `ux-flow.md`
- `api-spec.yaml` → `use-cases.md`, `domain-model.md`, `ux-flow.md`
- `api-implement-logic.md` → `use-cases.md`, `api-spec.yaml`, `domain-model.md`
- `test-spec.md` → `use-cases.md`, `api-spec.yaml`, `domain-model.md`

---

## Step 3: Identify Affected Sections

Analyse the outdated document section by section against the collected diffs. For each section, determine whether it references concepts, entities, endpoints, or flows touched by the diffs.

Output a list before making any changes:

```
Affected sections:
- [Section heading]: [reason — e.g. "references UserProfile entity renamed to Account in domain-model diff"]
- [Section heading]: [reason]

Unaffected sections (will not be modified):
- [Section heading]
- [Section heading]
```

If no sections are affected, tell the user:
> "No sections appear to be affected by the dependency changes. The document may already be consistent — review the diffs below and confirm whether to re-approve manually."
Then show the diffs and stop.

---

## Step 4: Candidate Rewrites

For each affected section, present candidate rewrites using the candidate-first pattern:

```
[Framing sentence — what changed in the dependency and how it affects this section]

1. **[Candidate A — derived from new dependency content]** *(recommended)*
2. **[Candidate B — alternative interpretation]**
3. Other — describe your own
```

Wait for the human to pick a number, adjust, or describe their own before moving to the next section.

Apply each approved rewrite immediately. Leave all unaffected sections exactly as-is.

---

## Step 5: Hand Off to Pipeline

Pass the patched document to the pipeline. The pipeline will annotate, present for human review, strip on approval, and commit.

**REQUIRED SUB-SKILL:** `docflow:pipeline`

Pass:
- document type: `<doc>`
- template path: `templates/<doc>`
- intake answers: the set of approved section rewrites from Step 4
- dependency file contents: full content of all dependency documents
