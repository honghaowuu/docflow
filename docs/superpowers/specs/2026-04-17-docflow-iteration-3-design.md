# DocFlow Iteration 3 — Design Spec

**Date:** 2026-04-17
**Scope:** Iteration 3 — Repair mode, skill composition (`docflow:generate-all`), CI integration
**Platform:** Claude Code only
**Prior spec:** `2026-04-16-docflow-full-plugin-design.md` (Iteration 2 — 8-document pipeline)

---

## 1. Overview

This spec implements the three features deferred from Iteration 2 (Section 8: Out of Scope):

1. **Repair mode** — fix inconsistencies in existing documents without full regeneration, using targeted diff-and-patch
2. **Skill composition** — `docflow:generate-all` chains all 8 skills in dependency order with explicit human checkpoints
3. **CI integration** — `validate.sh` extended with status file consistency and dependency order integrity checks

---

## 2. Repair Mode (`docflow:repair`)

### Trigger

`docflow:start` adds a "Repair" option to the menu whenever a document has `status: outdated`. This sits alongside the existing Regenerate options:

```
3. Regenerate [outdated doc] — guided
4. Regenerate [outdated doc] — fast
5. Repair [outdated doc] — patch only the sections affected by dependency changes
```

Repair is distinct from Regenerate: Regenerate discards existing content and starts over; Repair preserves all unaffected sections and patches only what changed.

### Behaviour

1. Read the outdated document in full
2. For each dependency that changed since `approved_at`, run:
   ```bash
   git diff <approved_at>..HEAD -- docs/<dependency>
   ```
3. AI analyses the diff and identifies which sections of the outdated document reference concepts touched by the changes. Outputs a list:
   ```
   Section X: [reason it's affected by the diff]
   Section Y: [reason it's affected by the diff]
   ```
4. For each affected section, present candidate rewrites using the candidate-first pattern — derive 2–5 options from the diff content, mark one `(recommended)`, include "Other — describe your own"
5. Human picks or adjusts each candidate
6. Unaffected sections are left exactly as-is — not rewritten, not re-reviewed
7. Hand off to `docflow:pipeline` for annotation → human review → strip → commit

### Status update

After a successful repair, `status.yaml` is updated:
```yaml
status: approved
approved_at: <new timestamp>
content_hash: <new hash>
```

### New file

- `skills/repair/SKILL.md`

### `docflow:start` routing addition

```
- Repair [outdated doc] → REQUIRED SUB-SKILL: docflow:repair
```

---

## 3. Skill Composition (`docflow:generate-all`)

### Invocation

Available as a direct skill call (`docflow:generate-all`). Also offered by `docflow:start` as a menu option when `prd.md` is `approved` and at least one downstream document is `missing` or `outdated`.

`docflow:start` menu addition:
```
6. Generate all remaining documents — guided, with checkpoints
```

### Entry condition

`prd.md` must be `approved` before `generate-all` can proceed. If it isn't, `generate-all` begins with `docflow:prd` first.

### Behaviour

1. Read `status.yaml` and determine the next document to generate — lowest dependency level with `status: missing` or `outdated`
2. Announce: `"Generating [doc] ([N] of [total remaining]) — guided mode"`
3. Invoke the appropriate document skill in guided mode (full intake + pipeline review)
4. After the document is approved and committed, pause:
   ```
   ✓ [doc] approved.

   Ready to continue?
   1. Yes — proceed to [next doc]
   2. No — stop here (resume later with docflow:generate-all)
   ```
5. If yes: repeat from step 1. If no: exit — `status.yaml` reflects current progress, a future invocation resumes from the same point

### Ordering

Follows the dependency graph level order (Level 0 → Level 4). When two documents share a level (e.g. `ux-flow.md` and `domain-model.md` at Level 2), generate-all uses canonical alphabetical order and generates them one at a time.

### Mode

`generate-all` always uses guided mode. Fast mode is not offered — full human review at every step is required.

### New file

- `skills/generate-all/SKILL.md`

### `docflow:start` routing addition

```
- Generate all remaining documents → REQUIRED SUB-SKILL: docflow:generate-all
```

---

## 4. CI Integration (`tests/validate.sh` extension)

### Approach

Extend the existing `validate.sh` with two new check sections appended after the Templates section and before the Hook section. No new script file.

### New section: Status File Consistency

When `.docflow/status.yaml` exists:

- All 8 documents are listed in `status.yaml`
- Every document with `status: approved`, `draft`, or `outdated` has a corresponding file at `docs/<doc>`
- Any document file present at `docs/<doc>` while `status.yaml` lists it as `missing` is flagged as a warning (not a hard fail)

When `.docflow/status.yaml` does not exist: skip this section silently (project not initialised — not an error).

### New section: Dependency Order Integrity

When `.docflow/status.yaml` exists:

For every document with `status: approved`, verify all declared dependencies also have `status: approved`. If any dependency is `missing`, `draft`, or `outdated`, fail with a clear message:

```
FAIL: api-spec.yaml is approved but domain-model.md is draft — dependency chain is broken
```

Dependency graph used for checks (mirrors `docflow:start`):
- `prd.md` → no dependencies
- `use-cases.md` → `prd.md`
- `ux-flow.md` → `prd.md`, `use-cases.md`
- `domain-model.md` → `prd.md`, `use-cases.md`
- `ui-spec.md` → `prd.md`, `ux-flow.md`
- `api-spec.yaml` → `use-cases.md`, `domain-model.md`, `ux-flow.md`
- `api-implement-logic.md` → `use-cases.md`, `api-spec.yaml`, `domain-model.md`
- `test-spec.md` → `use-cases.md`, `api-spec.yaml`, `domain-model.md`

When `.docflow/status.yaml` does not exist: skip this section silently.

### Placement in validate.sh

```
--- Templates ---          (existing)
--- Status File Consistency ---   (new)
--- Dependency Order Integrity ---  (new)
--- Hook ---               (existing)
```

---

## 5. File Changes Summary

**New files:**
- `skills/repair/SKILL.md`
- `skills/generate-all/SKILL.md`

**Modified files:**
- `skills/start/SKILL.md` — add Repair and Generate-All menu options and routing
- `tests/validate.sh` — add Status File Consistency and Dependency Order Integrity sections

---

## 6. Out of Scope

- Parallel document generation (two Level-2 docs generated simultaneously)
- Partial repair (repairing only one specific section manually selected by the user)
- Repair mode for documents not marked `outdated` (manual consistency check on demand)
