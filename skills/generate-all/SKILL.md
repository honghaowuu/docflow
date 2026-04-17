---
name: docflow:generate-all
description: Use when you want to generate all remaining DocFlow documents in dependency order with guided intake and an explicit checkpoint between each document
---

# DocFlow Generate All

**Announce at start:** "I'm using docflow:generate-all to generate all remaining documents in dependency order."

---

## Step 1: Check Entry Condition

Read `.docflow/status.yaml`.

If `prd.md` status is not `approved`:
> "prd.md must be approved before generate-all can proceed. Starting with prd.md."
Invoke **REQUIRED SUB-SKILL:** `docflow:prd` (guided mode). After it is approved, continue to Step 2.

---

## Step 2: Determine Next Document

Find the document at the lowest dependency level whose `status` is `missing` or `outdated` and whose all dependencies have `status: approved`.

Dependency levels and canonical order within each level:
- Level 1: `use-cases.md`
- Level 2: `domain-model.md`, `ux-flow.md` (alphabetical)
- Level 3: `api-spec.yaml`, `ui-spec.md` (alphabetical)
- Level 4: `api-implement-logic.md`, `test-spec.md` (alphabetical)

Count all documents with `status: missing` or `outdated` (excluding `prd.md`) — this is **total remaining**.

If no documents remain:
> "All documents are approved. Nothing left to generate."
Exit.

---

## Step 3: Generate Document

Announce: `"Generating [doc] ([N] of [total remaining]) — guided mode"`

Invoke the appropriate skill in guided mode:

- `use-cases.md` → **REQUIRED SUB-SKILL:** `docflow:use-cases` — tell it: guided mode
- `ux-flow.md` → **REQUIRED SUB-SKILL:** `docflow:ux-flow` — tell it: guided mode
- `domain-model.md` → **REQUIRED SUB-SKILL:** `docflow:domain-model` — tell it: guided mode
- `ui-spec.md` → **REQUIRED SUB-SKILL:** `docflow:ui-spec` — tell it: guided mode
- `api-spec.yaml` → **REQUIRED SUB-SKILL:** `docflow:api-spec` — tell it: guided mode
- `api-implement-logic.md` → **REQUIRED SUB-SKILL:** `docflow:api-implement-logic` — tell it: guided mode
- `test-spec.md` → **REQUIRED SUB-SKILL:** `docflow:test-spec` — tell it: guided mode

---

## Step 4: Checkpoint

After the document is approved and committed by `docflow:pipeline`, present:

```
✓ [doc] approved.

Ready to continue?
1. Yes — proceed to [next doc name]
2. No — stop here (resume later with docflow:generate-all)
```

If 1: return to Step 2.
If 2: exit. `.docflow/status.yaml` reflects current progress. A future invocation of `docflow:generate-all` resumes from the same point.
