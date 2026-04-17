# DocFlow Iteration 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add repair mode (`docflow:repair`), skill composition (`docflow:generate-all`), and CI status/dependency integrity checks to the DocFlow plugin.

**Architecture:** Two new standalone skills (`skills/repair/SKILL.md`, `skills/generate-all/SKILL.md`) are invoked by `docflow:start` via new routing entries. `tests/validate.sh` is extended with two new sections that check `.docflow/status.yaml` consistency and dependency chain integrity when the file exists.

**Tech Stack:** Markdown skill files, bash (`tests/validate.sh`)

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `skills/repair/SKILL.md` | Create | Repair skill: diff-and-patch outdated documents |
| `skills/generate-all/SKILL.md` | Create | Generate-all skill: chain all 8 skills in dependency order with checkpoints |
| `skills/start/SKILL.md` | Modify | Add Repair and Generate-All menu options and routing |
| `tests/validate.sh` | Modify | Add structure checks for new skills + Status File Consistency + Dependency Order Integrity sections |

---

## Task 1: Extend validate.sh — structural checks for new skills

Add file existence, frontmatter, handoff, and routing checks for `repair` and `generate-all`. These will FAIL until the skills are written in Tasks 2 and 3.

**Files:**
- Modify: `tests/validate.sh`

- [ ] **Step 1: Read the current validate.sh to understand insertion points**

Open `tests/validate.sh`. The Structure section lists `check_file` calls; the Frontmatter loop lists skill names; the Handoffs section has per-skill `check_contains` calls; the Routing section checks start routes.

- [ ] **Step 2: Add file existence checks to the Structure section**

In `tests/validate.sh`, after the line:
```bash
check_file "skills/test-spec/SKILL.md"
```
Add:
```bash
check_file "skills/repair/SKILL.md"
check_file "skills/generate-all/SKILL.md"
```

- [ ] **Step 3: Add repair and generate-all to the frontmatter loop**

Find the line:
```bash
for skill in start pipeline prd use-cases domain-model ux-flow ui-spec api-spec api-implement-logic test-spec; do
```
Replace with:
```bash
for skill in start pipeline prd use-cases domain-model ux-flow ui-spec api-spec api-implement-logic test-spec repair generate-all; do
```

- [ ] **Step 4: Add REQUIRED SUB-SKILL handoff check for repair**

In the `--- REQUIRED SUB-SKILL Handoffs ---` section, after the `test-spec` handoff check, add:
```bash
check_contains "skills/repair/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "repair: hands off to pipeline"
```

- [ ] **Step 5: Add REQUIRED SUB-SKILL handoff check for generate-all**

Immediately after the line added in Step 4, add:
```bash
check_contains "skills/generate-all/SKILL.md" "REQUIRED SUB-SKILL.*docflow:use-cases" \
    "generate-all: hands off to use-cases"
```

- [ ] **Step 6: Add routing checks for repair and generate-all in start**

In the `--- Orchestrator Routing ---` section, after:
```bash
check_contains "skills/start/SKILL.md" "fast mode" "start: mentions fast mode"
```
Add:
```bash
check_contains "skills/start/SKILL.md" "docflow:repair" "start: routes to repair"
check_contains "skills/start/SKILL.md" "docflow:generate-all" "start: routes to generate-all"
```

- [ ] **Step 7: Run validate.sh and confirm new checks appear and fail**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep -E "(repair|generate-all)"
```
Expected: multiple `FAIL:` lines for the new checks (files missing, frontmatter missing, etc.)

- [ ] **Step 8: Commit**

```bash
git add tests/validate.sh
git commit -m "test: add structural validation checks for repair and generate-all skills"
```

---

## Task 2: Write `skills/repair/SKILL.md`

**Files:**
- Create: `skills/repair/SKILL.md`

- [ ] **Step 1: Run validate.sh to confirm repair checks are currently failing**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep "repair"
```
Expected: `FAIL: skills/repair/SKILL.md missing` and related failures.

- [ ] **Step 2: Create the skill file**

Create `skills/repair/SKILL.md` with this exact content:

```markdown
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
```

- [ ] **Step 3: Run validate.sh and confirm repair checks now pass**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep "repair"
```
Expected: all `repair:` lines show `PASS`.

- [ ] **Step 4: Commit**

```bash
git add skills/repair/SKILL.md
git commit -m "feat: add docflow:repair skill"
```

---

## Task 3: Write `skills/generate-all/SKILL.md`

**Files:**
- Create: `skills/generate-all/SKILL.md`

- [ ] **Step 1: Run validate.sh to confirm generate-all checks are currently failing**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep "generate-all"
```
Expected: `FAIL: skills/generate-all/SKILL.md missing` and related failures.

- [ ] **Step 2: Create the skill file**

Create `skills/generate-all/SKILL.md` with this exact content:

```markdown
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
```

- [ ] **Step 3: Run validate.sh and confirm generate-all checks now pass**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep "generate-all"
```
Expected: all `generate-all:` lines show `PASS`.

- [ ] **Step 4: Commit**

```bash
git add skills/generate-all/SKILL.md
git commit -m "feat: add docflow:generate-all skill"
```

---

## Task 4: Update `skills/start/SKILL.md` — add Repair and Generate-All routing

**Files:**
- Modify: `skills/start/SKILL.md`

- [ ] **Step 1: Add Repair option to the menu in Step 3**

In `skills/start/SKILL.md`, find the menu block:
```
What would you like to do?
1. Generate [doc] — guided (recommended for first generation)
2. Generate [doc] — fast (derive directly from approved dependencies)
3. Regenerate [outdated doc] — guided
4. Regenerate [outdated doc] — fast
```
Replace with:
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

- [ ] **Step 2: Add Repair and Generate-All entries to the Routing section**

At the end of the Routing section in `skills/start/SKILL.md`, after the last routing line (`test-spec.md fast`), add:
```
- Repair any outdated doc → **REQUIRED SUB-SKILL:** `docflow:repair` — pass the document name and its outdated_because list
- Generate all remaining documents → **REQUIRED SUB-SKILL:** `docflow:generate-all`
```

- [ ] **Step 3: Run validate.sh routing checks**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep -E "(start: routes to repair|start: routes to generate-all)"
```
Expected:
```
  PASS: start: routes to repair
  PASS: start: routes to generate-all
```

- [ ] **Step 4: Commit**

```bash
git add skills/start/SKILL.md
git commit -m "feat: add repair and generate-all routing to docflow:start"
```

---

## Task 5: Extend validate.sh — Status File Consistency checks

Add the new `--- Status File Consistency ---` section to `tests/validate.sh`. This section checks `.docflow/status.yaml` when present.

**Files:**
- Modify: `tests/validate.sh`

- [ ] **Step 1: Add the Status File Consistency section**

In `tests/validate.sh`, find the line:
```bash
echo ""
echo "--- Hook ---"
```
Insert the following block immediately before it:

```bash
echo ""
echo "--- Status File Consistency ---"
STATUS_FILE="$PLUGIN_ROOT/.docflow/status.yaml"
if [ -f "$STATUS_FILE" ]; then
    # Check all 8 documents are listed
    DOC_COUNT=0
    for d in prd.md use-cases.md ux-flow.md domain-model.md ui-spec.md api-spec.yaml api-implement-logic.md test-spec.md; do
        grep -q "  $d:" "$STATUS_FILE" 2>/dev/null && DOC_COUNT=$((DOC_COUNT+1))
    done
    [ "$DOC_COUNT" -eq 8 ] \
        && pass "status.yaml: all 8 documents listed" \
        || fail "status.yaml: missing entries — re-run 'init docflow' to upgrade (found $DOC_COUNT/8)"

    # Check approved/draft/outdated docs have files on disk
    for doc in prd.md use-cases.md ux-flow.md domain-model.md ui-spec.md api-spec.yaml api-implement-logic.md test-spec.md; do
        doc_status=$(grep -A2 "  $doc:" "$STATUS_FILE" 2>/dev/null | grep "status:" | awk '{print $2}')
        case "$doc_status" in
            approved|draft|outdated)
                [ -f "$PLUGIN_ROOT/docs/$doc" ] \
                    && pass "status.yaml: $doc ($doc_status) has file on disk" \
                    || fail "status.yaml: $doc is $doc_status but docs/$doc not found"
                ;;
            missing)
                [ -f "$PLUGIN_ROOT/docs/$doc" ] \
                    && echo "  WARN: docs/$doc exists but status.yaml lists it as missing"
                ;;
        esac
    done
else
    echo "  (skipping — .docflow/status.yaml not found)"
fi
```

- [ ] **Step 2: Run validate.sh and confirm the new section appears**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep -A2 "Status File Consistency"
```
Expected: section header followed by `(skipping — .docflow/status.yaml not found)` (no `.docflow/` in the plugin root).

- [ ] **Step 3: Commit**

```bash
git add tests/validate.sh
git commit -m "test: add Status File Consistency checks to validate.sh"
```

---

## Task 6: Extend validate.sh — Dependency Order Integrity checks

Add the `--- Dependency Order Integrity ---` section immediately after Status File Consistency.

**Files:**
- Modify: `tests/validate.sh`

- [ ] **Step 1: Add the Dependency Order Integrity section**

In `tests/validate.sh`, find the line added in Task 5:
```bash
else
    echo "  (skipping — .docflow/status.yaml not found)"
fi
```
(The one closing the Status File Consistency block.) Insert the following block immediately after it:

```bash
echo ""
echo "--- Dependency Order Integrity ---"
if [ -f "$STATUS_FILE" ]; then
    # Helper: get status of a doc from status.yaml
    get_status() {
        grep -A2 "  $1:" "$STATUS_FILE" 2>/dev/null | grep "status:" | awk '{print $2}'
    }

    # check_dep DOC DEP: if DOC is approved, DEP must also be approved
    check_dep() {
        local doc="$1" dep="$2"
        local doc_st dep_st
        doc_st=$(get_status "$doc")
        dep_st=$(get_status "$dep")
        if [ "$doc_st" = "approved" ]; then
            [ "$dep_st" = "approved" ] \
                && pass "dep integrity: $doc approved and $dep approved" \
                || fail "dep integrity: $doc is approved but $dep is ${dep_st:-missing} — dependency chain is broken"
        fi
    }

    check_dep "use-cases.md"           "prd.md"
    check_dep "ux-flow.md"             "prd.md"
    check_dep "ux-flow.md"             "use-cases.md"
    check_dep "domain-model.md"        "prd.md"
    check_dep "domain-model.md"        "use-cases.md"
    check_dep "ui-spec.md"             "prd.md"
    check_dep "ui-spec.md"             "ux-flow.md"
    check_dep "api-spec.yaml"          "use-cases.md"
    check_dep "api-spec.yaml"          "domain-model.md"
    check_dep "api-spec.yaml"          "ux-flow.md"
    check_dep "api-implement-logic.md" "use-cases.md"
    check_dep "api-implement-logic.md" "api-spec.yaml"
    check_dep "api-implement-logic.md" "domain-model.md"
    check_dep "test-spec.md"           "use-cases.md"
    check_dep "test-spec.md"           "api-spec.yaml"
    check_dep "test-spec.md"           "domain-model.md"
else
    echo "  (skipping — .docflow/status.yaml not found)"
fi
```

- [ ] **Step 2: Run validate.sh and confirm the new section appears**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh 2>&1 | grep -A2 "Dependency Order Integrity"
```
Expected: section header followed by `(skipping — .docflow/status.yaml not found)`.

- [ ] **Step 3: Smoke-test the dependency check logic with a synthetic status file**

```bash
mkdir -p /tmp/docflow-test/.docflow
cat > /tmp/docflow-test/.docflow/status.yaml << 'EOF'
version: 1
documents:
  prd.md:
    status: approved
  use-cases.md:
    status: approved
  ux-flow.md:
    status: missing
  domain-model.md:
    status: missing
  ui-spec.md:
    status: approved
  api-spec.yaml:
    status: missing
  api-implement-logic.md:
    status: missing
  test-spec.md:
    status: missing
EOF
PLUGIN_ROOT=/tmp/docflow-test bash -c "
STATUS_FILE=/tmp/docflow-test/.docflow/status.yaml
get_status() { grep -A2 \"  \$1:\" \"\$STATUS_FILE\" 2>/dev/null | grep 'status:' | awk '{print \$2}'; }
doc_st=\$(get_status 'ui-spec.md')
dep_st=\$(get_status 'ux-flow.md')
echo \"ui-spec: \$doc_st, ux-flow: \$dep_st\"
[ \"\$doc_st\" = 'approved' ] && [ \"\$dep_st\" != 'approved' ] && echo 'CORRECTLY DETECTED: ui-spec approved but ux-flow is not' || echo 'unexpected result'
"
```
Expected output:
```
ui-spec: approved, ux-flow: missing
CORRECTLY DETECTED: ui-spec approved but ux-flow is not
```

- [ ] **Step 4: Commit**

```bash
git add tests/validate.sh
git commit -m "test: add Dependency Order Integrity checks to validate.sh"
```

---

## Task 7: Full validation pass

Run the complete validate.sh and confirm zero failures.

**Files:** none (read-only verification)

- [ ] **Step 1: Run full validate.sh**

```bash
cd /home/honghaowu/project/docflow && bash tests/validate.sh
```
Expected final line:
```
=== Results: N passed, 0 failed ===
```
And exit code 0.

- [ ] **Step 2: If any FAIL lines appear, fix the specific file/check before proceeding**

Match each `FAIL:` line to its task above and re-run that task's steps.

- [ ] **Step 3: Commit if any fixes were needed**

```bash
git add -p
git commit -m "fix: resolve validate.sh failures"
```
