# DocFlow Project Orchestrator

**Announce at start:** "I'm using docflow:start to check project status."

---

## Step 1: Handle Init Request

If the user said "init docflow":

1. Create `.docflow/` directory if it doesn't exist
2. Create `.docflow/status.yaml`:

```yaml
version: 1
documents:
  prd.md:
    status: missing
  use-cases.md:
    status: missing
  ux-flow.md:
    status: missing
  domain-model.md:
    status: missing
  ui-spec.md:
    status: missing
  api-spec.yaml:
    status: missing
  api-implement-logic.md:
    status: missing
  test-spec.md:
    status: missing
```

3. Run:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || git init
git add .docflow/status.yaml
git commit -m "docflow: initialize project"
```

4. Tell the user: "DocFlow project initialized. Ready to generate your first document."
5. Proceed to Step 3.

---

## Step 2: Run Change Detection

If `.docflow/status.yaml` does not exist, skip to Step 3.

Read `.docflow/status.yaml`. For each document with `status: approved`:

**2a. Check for upstream changes:**

For each dependency of the document, run:
```bash
git log --since="<approved_at>" --oneline -- docs/<dependency>
```

If output is non-empty → the dependency changed after the document was approved. Mark the document `outdated` and record the cause:
```yaml
status: outdated
outdated_because:
  - <dependency> changed after approval
```

**2b. Check for manual edits:**

Compute the current file hash:
```bash
shasum -a 256 docs/<doc> | cut -d' ' -f1
```

If it differs from `content_hash` in status.yaml → warn the user:
> "⚠ `docs/<doc>` was manually edited after its last approval. Changes may be lost if regenerated. Would you like to preserve edits or treat this as a new draft?"

If the user chooses 'preserve edits': leave the file untouched and mark status as `draft` in status.yaml. If the user chooses 'new draft': proceed normally (the file will be overwritten during generation).

**2c. Commit updated status if anything changed:**
```bash
git add .docflow/status.yaml
git commit -m "docflow: update impact status"
```

---

## Step 3: Present Project Status

Show a status table in dependency level order:

```
DocFlow Project Status

  Level 0:
    prd.md                  [icon] [status]   [reason if outdated]

  Level 1:
    use-cases.md            [icon] [status]   [reason if outdated]

  Level 2:
    ux-flow.md              [icon] [status]   [reason if outdated]
    domain-model.md         [icon] [status]   [reason if outdated]

  Level 3:
    ui-spec.md              [icon] [status]   [reason if outdated]
    api-spec.yaml           [icon] [status]   [reason if outdated]

  Level 4:
    api-implement-logic.md  [icon] [status]   [reason if outdated]
    test-spec.md            [icon] [status]   [reason if outdated]

Icons: ✓ approved   ⚠ outdated   · missing   ~ draft
```

Then offer numbered options — only list actions whose preconditions are met. For each available document, offer both guided and fast mode. Fast mode is only offered when all dependencies are approved. Fast mode is never offered for `prd.md`.

```
What would you like to do?
1. Generate [doc] — guided (recommended for first generation)
2. Generate [doc] — fast (derive directly from approved dependencies)
3. Regenerate [outdated doc] — guided
4. Regenerate [outdated doc] — fast
5. Repair [outdated doc] — patch only the sections affected by dependency changes
6. Generate all remaining documents — guided, with checkpoints between each document
   (offered when prd.md is approved and at least one downstream document is missing or outdated)
```

---

## Step 4: Dependency Enforcement

**Iron Law: NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED FIRST**

Dependency graph:
- `prd.md` → no dependencies
- `use-cases.md` → requires `prd.md: approved`
- `ux-flow.md` → requires `prd.md: approved` AND `use-cases.md: approved`
- `domain-model.md` → requires `prd.md: approved` AND `use-cases.md: approved`
- `ui-spec.md` → requires `prd.md: approved` AND `ux-flow.md: approved`
- `api-spec.yaml` → requires `use-cases.md: approved` AND `domain-model.md: approved` AND `ux-flow.md: approved`
- `api-implement-logic.md` → requires `use-cases.md: approved` AND `api-spec.yaml: approved` AND `domain-model.md: approved`
- `test-spec.md` → requires `use-cases.md: approved` AND `api-spec.yaml: approved` AND `domain-model.md: approved`

If a user requests generation of a document whose dependencies are not `approved`:
> "Cannot generate [doc] — [dependency] must be approved first. Would you like to generate [dependency] instead?"

Do not offer to bypass this. No exceptions.

---

## Routing

Based on user's choice, invoke the document skill and communicate the mode (guided or fast):

- Generate / regenerate `prd.md` → **REQUIRED SUB-SKILL:** `docflow:prd` (guided only — no dependencies)
- Generate / regenerate `use-cases.md` guided → **REQUIRED SUB-SKILL:** `docflow:use-cases` — tell it: guided mode
- Generate / regenerate `use-cases.md` fast → **REQUIRED SUB-SKILL:** `docflow:use-cases` — tell it: fast mode, skip intake
- Generate / regenerate `ux-flow.md` guided → **REQUIRED SUB-SKILL:** `docflow:ux-flow` — tell it: guided mode
- Generate / regenerate `ux-flow.md` fast → **REQUIRED SUB-SKILL:** `docflow:ux-flow` — tell it: fast mode, skip intake
- Generate / regenerate `domain-model.md` guided → **REQUIRED SUB-SKILL:** `docflow:domain-model` — tell it: guided mode
- Generate / regenerate `domain-model.md` fast → **REQUIRED SUB-SKILL:** `docflow:domain-model` — tell it: fast mode, skip intake
- Generate / regenerate `ui-spec.md` guided → **REQUIRED SUB-SKILL:** `docflow:ui-spec` — tell it: guided mode
- Generate / regenerate `ui-spec.md` fast → **REQUIRED SUB-SKILL:** `docflow:ui-spec` — tell it: fast mode, skip intake
- Generate / regenerate `api-spec.yaml` guided → **REQUIRED SUB-SKILL:** `docflow:api-spec` — tell it: guided mode
- Generate / regenerate `api-spec.yaml` fast → **REQUIRED SUB-SKILL:** `docflow:api-spec` — tell it: fast mode, skip intake
- Generate / regenerate `api-implement-logic.md` guided → **REQUIRED SUB-SKILL:** `docflow:api-implement-logic` — tell it: guided mode
- Generate / regenerate `api-implement-logic.md` fast → **REQUIRED SUB-SKILL:** `docflow:api-implement-logic` — tell it: fast mode, skip intake
- Generate / regenerate `test-spec.md` guided → **REQUIRED SUB-SKILL:** `docflow:test-spec` — tell it: guided mode
- Generate / regenerate `test-spec.md` fast → **REQUIRED SUB-SKILL:** `docflow:test-spec` — tell it: fast mode, skip intake
- Repair any outdated doc → **REQUIRED SUB-SKILL:** `docflow:repair` — pass the document name and its outdated_because list
- Generate all remaining documents → **REQUIRED SUB-SKILL:** `docflow:generate-all`
