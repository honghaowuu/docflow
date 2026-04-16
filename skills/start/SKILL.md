---
name: docflow:start
description: Use when starting any session in a DocFlow project — checks document status, detects change impact from git history, and presents the next available generation actions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

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
  domain-model.md:
    status: missing
```

3. Run:
```bash
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

Show a status table:

```
DocFlow Project Status

  prd.md          [icon] [status]   [reason if outdated]
  use-cases.md    [icon] [status]   [reason if outdated]
  domain-model.md [icon] [status]   [reason if outdated]

Icons: ✓ approved   ⚠ outdated   · missing   ~ draft
```

Then offer numbered options — only list actions whose preconditions are currently met:

```
What would you like to do?
1. [Generate next missing doc with dependencies met]
2. [Regenerate outdated docs]
3. [Other valid actions]
```

---

## Step 4: Dependency Enforcement

**Iron Law: NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED FIRST**

Dependency graph:
- `prd.md` → no dependencies
- `use-cases.md` → requires `prd.md: approved`
- `domain-model.md` → requires `prd.md: approved` AND `use-cases.md: approved`

If a user requests generation of a document whose dependencies are not `approved`:
> "Cannot generate [doc] — [dependency] must be approved first. Would you like to generate [dependency] instead?"

Do not offer to bypass this. No exceptions.

---

## Routing

Based on user's choice, invoke the appropriate skill:

- Generate / regenerate `prd.md` → **REQUIRED SUB-SKILL:** `docflow:prd`
- Generate / regenerate `use-cases.md` → **REQUIRED SUB-SKILL:** `docflow:use-cases`
- Generate / regenerate `domain-model.md` → **REQUIRED SUB-SKILL:** `docflow:domain-model`
