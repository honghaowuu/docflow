# DocFlow Full Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the DocFlow MVP to a full 8-document pipeline with candidate-first questioning, fast mode, and 5 new document skills.

**Architecture:** Same layered pattern as MVP — `docflow:start` (orchestrator) → `docflow:<doc>` (document skill with candidate-first intake or fast mode skip) → `docflow:pipeline` (shared generate/review/commit pipeline, extended to support YAML documents). All new skills follow the exact same structure as the 3 MVP skills.

**Tech Stack:** Bash (validate.sh), Markdown (SKILL.md files, .md templates), YAML (api-spec template, status file), Claude Code plugin conventions.

---

### Task 1: Extend validate.sh with checks for all new files

**Files:**
- Modify: `tests/validate.sh`

This is the TDD step — add all new checks first so subsequent tasks have clear pass/fail targets.

- [ ] **Step 1: Replace tests/validate.sh with the extended version**

Write the full file:

```bash
#!/usr/bin/env bash
# Structural validation for the DocFlow plugin.
# Run from the plugin root directory.

set -euo pipefail
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

check_file() {
    [ -f "$PLUGIN_ROOT/$1" ] && pass "$1 exists" || fail "$1 missing"
}

check_contains() {
    local file="$PLUGIN_ROOT/$1"
    local pattern="$2"
    local label="$3"
    grep -q "$pattern" "$file" 2>/dev/null && pass "$label" || fail "$label"
}

check_executable() {
    [ -x "$PLUGIN_ROOT/$1" ] && pass "$1 is executable" || fail "$1 not executable"
}

echo "=== DocFlow Plugin Validation ==="
echo ""

echo "--- Structure ---"
check_file "package.json"
check_file "hooks/hooks.json"
check_file "hooks/session-start"
check_file "skills/start/SKILL.md"
check_file "skills/pipeline/SKILL.md"
check_file "skills/prd/SKILL.md"
check_file "skills/use-cases/SKILL.md"
check_file "skills/domain-model/SKILL.md"
check_file "skills/ux-flow/SKILL.md"
check_file "skills/ui-spec/SKILL.md"
check_file "skills/api-spec/SKILL.md"
check_file "skills/api-implement-logic/SKILL.md"
check_file "skills/test-spec/SKILL.md"
check_file "templates/prd.md"
check_file "templates/use-cases.md"
check_file "templates/domain-model.md"
check_file "templates/ux-flow.md"
check_file "templates/ui-spec.md"
check_file "templates/api-spec.yaml"
check_file "templates/api-implement-logic.md"
check_file "templates/test-spec.md"

echo ""
echo "--- Skill Frontmatter (CSO descriptions) ---"
for skill in start pipeline prd use-cases domain-model ux-flow ui-spec api-spec api-implement-logic test-spec; do
    check_contains "skills/$skill/SKILL.md" "^name:" "$skill: has name frontmatter"
    check_contains "skills/$skill/SKILL.md" "description: Use when" "$skill: description starts with 'Use when'"
done

echo ""
echo "--- Iron Laws ---"
check_contains "skills/pipeline/SKILL.md" \
    "NO DOCUMENT WRITTEN TO DISK WITH UNFILLED TEMPLATE SECTIONS" \
    "pipeline: unfilled-section Iron Law"
check_contains "skills/pipeline/SKILL.md" \
    "NO DOCUMENT WRITTEN TO DISK WITHOUT ALL THREE ANNOTATION TYPES" \
    "pipeline: annotation Iron Law"
check_contains "skills/pipeline/SKILL.md" \
    "NO CLEAN DOCUMENT COMMITTED WITHOUT HUMAN APPROVAL" \
    "pipeline: approval Iron Law"
check_contains "skills/start/SKILL.md" \
    "NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED" \
    "start: dependency Iron Law"

echo ""
echo "--- Candidate-First Pattern ---"
check_contains "skills/prd/SKILL.md" "recommended" "prd: has candidate-first recommendations"
check_contains "skills/use-cases/SKILL.md" "recommended" "use-cases: has candidate-first recommendations"
check_contains "skills/domain-model/SKILL.md" "recommended" "domain-model: has candidate-first recommendations"
check_contains "skills/ux-flow/SKILL.md" "recommended" "ux-flow: has candidate-first recommendations"
check_contains "skills/ui-spec/SKILL.md" "recommended" "ui-spec: has candidate-first recommendations"
check_contains "skills/api-spec/SKILL.md" "recommended" "api-spec: has candidate-first recommendations"
check_contains "skills/api-implement-logic/SKILL.md" "recommended" "api-implement-logic: has candidate-first recommendations"
check_contains "skills/test-spec/SKILL.md" "recommended" "test-spec: has candidate-first recommendations"

echo ""
echo "--- REQUIRED SUB-SKILL Handoffs ---"
check_contains "skills/prd/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "prd: hands off to pipeline"
check_contains "skills/use-cases/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "use-cases: hands off to pipeline"
check_contains "skills/domain-model/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "domain-model: hands off to pipeline"
check_contains "skills/ux-flow/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "ux-flow: hands off to pipeline"
check_contains "skills/ui-spec/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "ui-spec: hands off to pipeline"
check_contains "skills/api-spec/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "api-spec: hands off to pipeline"
check_contains "skills/api-implement-logic/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "api-implement-logic: hands off to pipeline"
check_contains "skills/test-spec/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "test-spec: hands off to pipeline"

echo ""
echo "--- Orchestrator Routing ---"
check_contains "skills/start/SKILL.md" "docflow:ux-flow" "start: routes to ux-flow"
check_contains "skills/start/SKILL.md" "docflow:ui-spec" "start: routes to ui-spec"
check_contains "skills/start/SKILL.md" "docflow:api-spec" "start: routes to api-spec"
check_contains "skills/start/SKILL.md" "docflow:api-implement-logic" "start: routes to api-implement-logic"
check_contains "skills/start/SKILL.md" "docflow:test-spec" "start: routes to test-spec"
check_contains "skills/start/SKILL.md" "fast" "start: mentions fast mode"

echo ""
echo "--- Templates ---"
check_contains "templates/prd.md" "<!-- AI Generated -->" "prd template: AI Generated markers"
check_contains "templates/prd.md" "<!-- Human Review Required -->" "prd template: Human Review Required markers"
check_contains "templates/use-cases.md" "<!-- AI Generated -->" "use-cases template: AI Generated markers"
check_contains "templates/use-cases.md" "<!-- Human Review Required -->" "use-cases template: Human Review Required markers"
check_contains "templates/domain-model.md" "<!-- AI Generated -->" "domain-model template: AI Generated markers"
check_contains "templates/domain-model.md" "<!-- Human Review Required -->" "domain-model template: Human Review Required markers"
check_contains "templates/ux-flow.md" "<!-- AI Generated -->" "ux-flow template: AI Generated markers"
check_contains "templates/ux-flow.md" "<!-- Human Review Required -->" "ux-flow template: Human Review Required markers"
check_contains "templates/ui-spec.md" "<!-- AI Generated -->" "ui-spec template: AI Generated markers"
check_contains "templates/ui-spec.md" "<!-- Human Review Required -->" "ui-spec template: Human Review Required markers"
check_contains "templates/api-spec.yaml" "# AI Generated" "api-spec template: AI Generated markers"
check_contains "templates/api-spec.yaml" "# Human Review Required" "api-spec template: Human Review Required markers"
check_contains "templates/api-implement-logic.md" "<!-- AI Generated -->" "api-implement-logic template: AI Generated markers"
check_contains "templates/api-implement-logic.md" "<!-- Human Review Required -->" "api-implement-logic template: Human Review Required markers"
check_contains "templates/test-spec.md" "<!-- AI Generated -->" "test-spec template: AI Generated markers"
check_contains "templates/test-spec.md" "<!-- Human Review Required -->" "test-spec template: Human Review Required markers"

echo ""
echo "--- Hook ---"
check_executable "hooks/session-start"
check_contains "hooks/hooks.json" "SessionStart" "hooks.json: has SessionStart event"
check_contains "hooks/hooks.json" "session-start" "hooks.json: references session-start script"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

- [ ] **Step 2: Run validate.sh and confirm new checks fail**

```bash
cd /Users/honghaowu/projects/docflow
bash tests/validate.sh 2>&1 | tail -5
```

Expected: `=== Results: 37 passed, N failed ===` where N is the number of new checks that don't have files yet. The original 37 checks must still pass.

- [ ] **Step 3: Commit**

```bash
git add tests/validate.sh
git commit -m "test: extend validate.sh for full 8-document plugin"
```

---

### Task 2: Update docflow:start orchestrator

**Files:**
- Modify: `skills/start/SKILL.md`

Full replacement — adds 8-document status init, full dependency graph, guided/fast menu, 5 new routes.

- [ ] **Step 1: Replace skills/start/SKILL.md**

```markdown
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
```

- [ ] **Step 2: Run validate.sh — start routing checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(Orchestrator|fast|start:)"
```

Expected: all 6 orchestrator routing checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/start/SKILL.md
git commit -m "feat: update docflow:start for 8-document graph and fast mode"
```

---

### Task 3: Update docflow:pipeline for YAML document support

**Files:**
- Modify: `skills/pipeline/SKILL.md`

Two small updates: note YAML marker syntax in Steps 1–2, and strip YAML-style markers in Step 6.

- [ ] **Step 1: Replace the Step 1 section in skills/pipeline/SKILL.md**

Find and replace exactly this block:

Old:
```
## Step 1: Generate

Using the intake answers and dependency content, fill every `<!-- AI Generated -->` section in the template.

**Before proceeding:** Scan the assembled document for any remaining `<!-- AI Generated -->` markers. If any exist, fill them now. A document with unfilled markers MUST NOT continue to Step 2.
```

New:
```
## Step 1: Generate

Using the intake answers and dependency content, fill every generated section in the template.

- For `.md` templates: sections are marked with `<!-- AI Generated -->`
- For `.yaml` templates: sections are marked with `# AI Generated`

**Before proceeding:** Scan the assembled document for any remaining unfilled markers. If any exist, fill them now. A document with unfilled markers MUST NOT continue to Step 2.
```

- [ ] **Step 2: Update the annotation format note in Step 2**

Find and replace exactly this block:

Old:
```
Place annotations between the generated content and the `<!-- Human Review Required -->` marker.
```

New:
```
Place annotations between the generated content and the review marker (`<!-- Human Review Required -->` for `.md` files, `# Human Review Required` for `.yaml` files).

For `.yaml` documents, use YAML comment prefix for annotation lines:
```
# AI Reasoning: [what inputs and logic produced this content]
# Assumption: [any inference the human must validate — write "None" if no assumption]
# Review focus: [the single most important question to answer before confirming]
```
```

- [ ] **Step 3: Update Step 6 to strip YAML-style markers**

Find and replace exactly this block:

Old:
```
## Step 6: Strip Annotations

Remove the following from the document content:

- All lines matching `> **AI Reasoning:***`
- All lines matching `> **Assumption:***`
- All lines matching `> **Review focus:***`
- All `<!-- AI Generated -->` markers
- All `<!-- Human Review Required -->` markers
- All `[ ] Confirmed` lines
```

New:
```
## Step 6: Strip Annotations

Remove the following from the document content:

- All lines matching `> **AI Reasoning:**`
- All lines matching `> **Assumption:**`
- All lines matching `> **Review focus:**`
- All lines matching `# AI Reasoning:`
- All lines matching `# Assumption:`
- All lines matching `# Review focus:`
- All `<!-- AI Generated -->` markers
- All `<!-- Human Review Required -->` markers
- All `[ ] Confirmed` lines
- All `# AI Generated` markers
- All `# Human Review Required` markers
- All `# [ ] Confirmed` lines
```

- [ ] **Step 4: Commit**

```bash
git add skills/pipeline/SKILL.md
git commit -m "feat: extend docflow:pipeline to support YAML document markers"
```

---

### Task 4: Update candidate-first questioning in existing skills

**Files:**
- Modify: `skills/prd/SKILL.md`
- Modify: `skills/use-cases/SKILL.md`
- Modify: `skills/domain-model/SKILL.md`

Replace the `## Dynamic Questioning` section in each skill with a `## Candidate-First Questioning` section.

- [ ] **Step 1: Replace Dynamic Questioning in skills/prd/SKILL.md**

Find and replace the entire `## Dynamic Questioning` section. Old section starts with `## Dynamic Questioning` and ends before `## Rationalization Table`. Replace with:

```markdown
## Candidate-First Questioning

Ask one question per message. After each answer, derive candidates for the next question from what the user has told you. Present options as a numbered list with one marked `*(recommended)*`. Always include a final option: `[N]. Other — describe your own`.

**Opening question — open-ended (no prior context to derive candidates from):**
> "What problem does this product solve?"

**After the problem is stated — derive candidate primary users from the problem description:**
> "Based on the problem you described, these seem like the most likely primary users:
>
> 1. **[Role most directly affected by problem]** *(recommended)*
> 2. **[Second likely role]**
> 3. Other — describe your own
>
> Which are correct? You can select multiple or adjust."

**After users confirmed — derive candidate goals from the problem and users:**
> "Given those users and that problem, these seem like the most important outcomes this product must achieve:
>
> 1. **[Measurable outcome derived from the problem statement]** *(recommended)*
> 2. **[Second likely measurable outcome]**
> 3. **[Third likely outcome]**
> 4. Other — describe your own
>
> Which of these should be goals? Each goal must be measurable — if any are vague, I'll ask you to sharpen them."

**If a proposed or selected goal is vague (e.g. "better experience", "faster workflow") — validate before accepting:**
> "How would you measure '[goal]'? For example:
>
> 1. **[Specific observable or numeric metric]** *(recommended)*
> 2. **[Alternative metric]**
> 3. Other — describe your own"

**After goals confirmed — derive candidate non-goals from what the goals do NOT cover:**
> "Based on the goals, these adjacent things might be out of scope — worth stating explicitly:
>
> 1. **[Adjacent capability not addressed by any goal]** *(recommended)*
> 2. **[Another adjacent out-of-scope item]**
> 3. Other — describe your own
>
> Which of these are explicit non-goals? Non-goals must be explicitly stated — empty is not acceptable."

**After non-goals — derive candidate success metrics, one per goal:**
> "For each goal, here are candidate metrics:
>
> - **[Goal 1]**: 1. **[Specific metric]** *(recommended)* / 2. [Alternative] / 3. Other
> - **[Goal 2]**: 1. **[Specific metric]** *(recommended)* / 2. [Alternative] / 3. Other
>
> Confirm or adjust each. One metric per goal."

**After metrics — derive candidate risks from the problem domain and goals:**
> "Common risks for this type of product:
>
> 1. **[Technical risk derived from approach or domain]** *(recommended)*
> 2. **[Adoption or user behaviour risk]**
> 3. **[Resource or timeline risk]**
> 4. Other — describe your own
>
> Which risks apply? At least one is required."

**For each confirmed risk — derive a candidate mitigation:**
> "For the risk '[risk]', a likely mitigation:
>
> 1. **[Mitigation derived from the problem context]** *(recommended)*
> 2. **[Alternative mitigation]**
> 3. Other — describe your own"

**Coverage check before proceeding:**
Can you fill every row of the Required Information table from the answers collected? If any row is empty, ask for it using candidate-first format before proceeding.
```

- [ ] **Step 2: Replace Dynamic Questioning in skills/use-cases/SKILL.md**

Find and replace the entire `## Dynamic Questioning` section. Old section starts with `## Dynamic Questioning` and ends before `## Rationalization Table`. Replace with:

```markdown
## Candidate-First Questioning

Read `docs/prd.md` before asking any question. Derive candidates from the PRD throughout.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate actors from prd.md target users:**
> "Based on the PRD, I've identified these actors:
>
> 1. **[Primary user from prd.md]** *(recommended)*
> 2. **[Secondary user from prd.md]**
> 3. Other — describe your own
>
> Which actors should be included? You can select multiple, rename, or split any into more specific roles."

**For each confirmed actor — derive candidate goals from PRD goals section:**
> "The PRD goals most relevant to [actor] suggest these use case goals:
>
> 1. **[Goal derived from PRD for this actor]** *(recommended)*
> 2. **[Second derived goal]**
> 3. Other — describe your own
>
> What is the most critical thing [actor] needs to accomplish?"

**For each confirmed goal — derive candidate main flow steps from the PRD problem and goal descriptions:**
> "For [actor] accomplishing [goal], a likely main flow would be:
>
> 1. [Step derived from PRD or domain context]
> 2. [Step 2]
> 3. [Step 3]
>
> Does this match? What steps are wrong or missing? The main flow needs at least 3 concrete steps."

**For alternative flows — derive candidates from PRD risks and problem description:**
> "For the step '[step]' in this flow, likely failure modes are:
>
> 1. **[Failure derived from PRD risks or problem domain]** *(recommended)*
> 2. **[Second failure mode]**
> 3. Other — describe your own
>
> What does [actor] do when this step fails? At least one alternative flow is required per use case."

**For preconditions — derive candidates from the goal and system context:**
> "Before [actor] can start this use case, the following must be true:
>
> 1. **[Precondition derived from use case context or PRD]** *(recommended)*
> 2. **[Second precondition]**
> 3. Other — describe your own"

**For postconditions — derive from the goal statement and PRD success metrics:**
> "When this use case completes successfully, the system state will be:
>
> 1. **[Postcondition derived from goal and PRD]** *(recommended)*
> 2. **[Second postcondition]**
> 3. Other — describe your own"

**Coverage check before proceeding:**
- Every PRD goal maps to at least one use case → if not, ask in candidate-first format: "The PRD lists '[goal]' — which use case covers this, or should we add one?"
- Every use case has at least one alternative flow → if not, ask for it in candidate-first format
- Every use case has explicit preconditions → if not, ask in candidate-first format
```

- [ ] **Step 3: Replace Dynamic Questioning in skills/domain-model/SKILL.md**

Find and replace the entire `## Dynamic Questioning` section. Old section starts with `## Dynamic Questioning` and ends before `## Rationalization Table`. Replace with:

```markdown
## Candidate-First Questioning

Read `docs/use-cases.md` and `docs/prd.md` before asking any question. Derive candidates from these documents throughout.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate entities from nouns in use-case main flows:**
> "I've identified these candidate entities from the use cases:
>
> 1. **[Core domain noun from main flows]** *(recommended — appears most frequently)*
> 2. **[Second domain noun]** *(recommended)*
> 3. **[Noun that may be a UI concern]**
> 4. **[Noun that may be infrastructure]**
> N. Other — add your own
>
> Which are core domain concepts to include? Which are UI/infrastructure concerns to exclude? An excluded entity needs a reason."

**For each confirmed entity — derive candidate attributes from use-case steps:**
> "For [entity], these attributes appear in the use case flows:
>
> 1. **[Attribute from use case step — field the domain logic depends on]** *(recommended)*
> 2. **[Second attribute]**
> 3. Other — describe your own
>
> Which attributes does the domain logic depend on? Exclude display fields and technical identifiers like database IDs."

**For each confirmed entity — derive candidate invariants from use-case preconditions and postconditions:**
> "Based on how [entity] is used in the use cases, these rules likely always hold:
>
> 1. **[Invariant derived from use-case precondition or postcondition]** *(recommended)*
> 2. **[Second invariant]**
> 3. Other — describe your own
>
> Which invariants are correct? At least one invariant is required per entity."

**For relationships — derive candidate cardinalities from how entities interact in use case flows:**
> "The use cases show [entity A] and [entity B] interacting. The relationship seems to be:
>
> 1. **One [A] has many [B]s** *(recommended — based on [use case step])*
> 2. One [A] has exactly one [B]
> 3. Many [A]s relate to many [B]s
> 4. Other — describe your own"

**For the glossary — derive candidates from domain-specific terms used in the document:**
> "These terms in the domain model may need clarification for a new team member:
>
> 1. **[Term A]** — suggested definition: [definition derived from use case context] *(recommended)*
> 2. **[Term B]** — suggested definition: [definition]
> 3. Other — add your own
>
> Which definitions are correct? Which terms are missing?"

**Coverage check before proceeding:**
- Every noun from use-case main flows is either included as an entity or explicitly excluded with a reason
- Every relationship has a cardinality
- Every entity has at least one invariant
- Every domain-specific term used in the document appears in the glossary
```

- [ ] **Step 4: Run validate.sh — candidate-first checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(Candidate|recommended)"
```

Expected: all 3 existing skill candidate-first checks show `PASS`.

- [ ] **Step 5: Commit**

```bash
git add skills/prd/SKILL.md skills/use-cases/SKILL.md skills/domain-model/SKILL.md
git commit -m "feat: upgrade existing skills to candidate-first questioning"
```

---

### Task 5: Add 5 new templates

**Files:**
- Create: `templates/ux-flow.md`
- Create: `templates/ui-spec.md`
- Create: `templates/api-spec.yaml`
- Create: `templates/api-implement-logic.md`
- Create: `templates/test-spec.md`

- [ ] **Step 1: Create templates/ux-flow.md**

```markdown
# UX Flow

<!-- Repeat the block below for each user journey -->

## Journey: [Actor] — [Goal]

### Entry Point
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Steps & Transitions
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Error States
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Exit Points
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 2: Create templates/ui-spec.md**

```markdown
# UI Specification

<!-- Repeat the block below for each screen -->

## Screen: [Screen Name]

### Purpose
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Components
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### State Variations
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Interaction Patterns
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 3: Create templates/api-spec.yaml**

Note: this template uses YAML comment markers (`# AI Generated`, `# Human Review Required`) because HTML comments are not valid YAML syntax.

```yaml
# API Specification

# == Metadata ==
# AI Generated

title: ~
version: ~
base_url: ~

# Human Review Required
# [ ] Confirmed

# == Endpoints ==
# AI Generated

# Generate a YAML list of endpoint objects. Each object must include:
#   id:           unique identifier (e.g. create-order)
#   method:       HTTP method (GET, POST, PUT, DELETE, PATCH)
#   path:         URL path (e.g. /api/v1/orders)
#   description:  what the endpoint does
#   auth_required: true or false
#   request:
#     body:       list of fields with name, type, required
#   response:
#     success:
#       status:   HTTP status code
#       body:     response shape
#     errors:     list of error cases with status code and description
endpoints: []

# Human Review Required
# [ ] Confirmed
```

- [ ] **Step 4: Create templates/api-implement-logic.md**

```markdown
# API Implementation Logic

<!-- Repeat the block below for each endpoint -->

## Endpoint: [Method] [Path]

### Business Rules
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Data Transformations
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Side Effects
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Sequencing
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Invariant Checks
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 5: Create templates/test-spec.md**

```markdown
# Test Specification

<!-- Repeat the block below for each test scenario -->

## Scenario: [Scenario Name]

### Type
<!-- AI Generated -->
(happy path / negative path / edge case)

<!-- Human Review Required -->
[ ] Confirmed

### Steps
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Input
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Expected Output
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

### Acceptance Criteria
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 6: Run validate.sh — template checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(Templates|template)"
```

Expected: all 10 template checks (5 existing + 5 new) show `PASS`.

- [ ] **Step 7: Commit**

```bash
git add templates/ux-flow.md templates/ui-spec.md templates/api-spec.yaml \
        templates/api-implement-logic.md templates/test-spec.md
git commit -m "feat: add 5 new document templates"
```

---

### Task 6: docflow:ux-flow skill

**Files:**
- Create: `skills/ux-flow/SKILL.md`

- [ ] **Step 1: Create skills/ux-flow/SKILL.md**

```markdown
---
name: docflow:ux-flow
description: Use when the user wants to generate or regenerate the UX Flow document (ux-flow.md) for a DocFlow project
---

# Generate UX Flow

**Announce at start:** "I'm using docflow:ux-flow to generate the UX Flow document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify both `prd.md` and `use-cases.md` have `status: approved`.

If either is not approved:
> "Cannot generate ux-flow.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/prd.md` and `docs/use-cases.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| User journeys | One journey per actor + primary goal pair | Every use-case main flow must map to a journey |
| Entry points | Where each journey begins (screen, event, or trigger) | Must be specific — "app opens" is not sufficient |
| Transitions | State-to-state movements within each journey | Every use-case main flow step must map to a transition |
| Error states | What happens when a transition fails | At least one error state per journey |
| Exit points | How each journey ends | Must cover both success and failure exits |

---

## Candidate-First Questioning

Read `docs/use-cases.md` and `docs/prd.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate journeys from use-case actor+goal pairs:**
> "I've identified these candidate user journeys from the use cases:
>
> 1. **[Actor A] — [Goal from UC-1]** *(recommended — highest priority use case)*
> 2. **[Actor B] — [Goal from UC-2]**
> 3. [Additional journey if multiple actors/goals]
> N. Other — describe your own
>
> Which of these should be included? You can select multiple."

**For each confirmed journey — derive candidate entry points from use-case preconditions:**
> "For the **[Actor] — [Goal]** journey, the use case preconditions suggest it could begin at:
>
> 1. **[Entry derived from preconditions or problem context]** *(recommended)*
> 2. **[Alternative entry point]**
> 3. Other — describe your own
>
> Which is correct?"

**For transitions — derive candidate steps from the use-case main flow:**
> "Based on the use-case main flow for [goal], I've mapped these transitions:
>
> 1. [Use-case step 1] → [resulting state]: **[Transition description]** *(recommended)*
> 2. [Alternative sequencing]
> 3. Adjust / add steps
>
> Does this match the intended flow? What should change? Every use-case step needs a mapped transition."

**For each transition — derive candidate error states from use-case alternative flows:**
> "The use case lists these alternative flows that could create error states here:
>
> 1. **[Alt flow 1 mapped to an error state]** *(recommended)*
> 2. **[Alt flow 2 mapped to an error state]**
> 3. Other — describe your own
>
> Which error states apply? At least one is required per journey."

**For exit points — derive from use-case postconditions and alternative flow endings:**
> "This journey could exit at:
>
> 1. **[Success exit derived from use-case postcondition]** *(recommended)*
> 2. **[Failure exit from a terminal alternative flow]**
> 3. Other — describe your own"

**Coverage check before proceeding:**
- Every use-case main flow maps to a journey
- Every journey has at least one error state
- Every journey has explicit success and failure exit points

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The entry point is obvious" | Unstated entry points become inconsistent implementations across screens. Write them. |
| "We don't need error states for this journey" | Every journey has failure modes. Derive them from the use-case alternative flows. |
| "The transitions are just the use-case steps" | UX transitions capture system state changes, not just actions. Map each step to a state. |

---

## Template

Use `templates/ux-flow.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency
- `docs/use-cases.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — ux-flow checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep "ux-flow"
```

Expected: all 4 ux-flow checks show `PASS` (exists, name frontmatter, description, recommended, handoff).

- [ ] **Step 3: Commit**

```bash
git add skills/ux-flow/
git commit -m "feat: add docflow:ux-flow document skill"
```

---

### Task 7: docflow:ui-spec skill

**Files:**
- Create: `skills/ui-spec/SKILL.md`

- [ ] **Step 1: Create skills/ui-spec/SKILL.md**

```markdown
---
name: docflow:ui-spec
description: Use when the user wants to generate or regenerate the UI Specification document (ui-spec.md) for a DocFlow project
---

# Generate UI Specification

**Announce at start:** "I'm using docflow:ui-spec to generate the UI Specification document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify both `prd.md` and `ux-flow.md` have `status: approved`.

If either is not approved:
> "Cannot generate ui-spec.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/prd.md` and `docs/ux-flow.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Screens | One screen per distinct UX state or step | Every UX flow transition must map to a screen or shared component |
| Components | UI elements on each screen | Each component must have: name, purpose, interaction behaviour |
| State variations | How each screen or component changes based on data or user state | At least one state variation per interactive component |
| Interaction patterns | User actions and system responses | Every component with user interaction must define the system response |

---

## Candidate-First Questioning

Read `docs/ux-flow.md` and `docs/prd.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate screens from UX flow transitions:**
> "Based on the UX flow, I've identified these candidate screens — one per distinct state:
>
> 1. **[Screen derived from UX flow entry point or step]** *(recommended)*
> 2. **[Second screen]**
> 3. **[Error state screen]**
> N. Other — describe your own
>
> Which screens should be specified? You can select multiple or rename any."

**For each confirmed screen — derive candidate components from the UX flow description of that step:**
> "For the **[Screen Name]** screen, these components are likely needed based on the UX flow:
>
> 1. **[Component derived from UX flow action or state]** *(recommended — primary interaction)*
> 2. **[Secondary component]**
> 3. **[Navigation or feedback component]**
> N. Other — describe your own
>
> Which components appear on this screen? Include name, purpose, and interaction behaviour for each."

**For state variations — derive candidates from UX flow error states and common UI states:**
> "For the **[Component]** component, these states are likely based on the UX flow:
>
> 1. **Empty / initial state** *(recommended — always required)*
> 2. **Loading state** (if async data)
> 3. **Error state** (derived from UX flow error states)
> 4. **Populated / success state**
> N. Other — describe your own
>
> Which state variations apply?"

**For interaction patterns — derive from UX flow transitions that involve this component:**
> "When the user interacts with **[Component]**, the UX flow indicates:
>
> 1. **[Action] → [System response derived from UX transition]** *(recommended)*
> 2. **[Alternative interaction]**
> 3. Other — describe your own"

**Coverage check before proceeding:**
- Every UX flow transition maps to a screen or shared component
- Every interactive component has at least one state variation
- Every interactive component has a defined interaction pattern and system response

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The components are obvious from the screen name" | Undefined components become inconsistently implemented across the frontend. Name and specify each. |
| "We only need the happy-path states" | UX flow error states must map to UI components. Empty, loading, and error states prevent blank or broken screens. |
| "The interaction pattern is just a click" | Undefined system responses to clicks become undefined behaviour in implementation. Specify the response. |

---

## Template

Use `templates/ui-spec.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency
- `docs/ux-flow.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — ui-spec checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep "ui-spec"
```

Expected: all ui-spec checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/ui-spec/
git commit -m "feat: add docflow:ui-spec document skill"
```

---

### Task 8: docflow:api-spec skill

**Files:**
- Create: `skills/api-spec/SKILL.md`

- [ ] **Step 1: Create skills/api-spec/SKILL.md**

```markdown
---
name: docflow:api-spec
description: Use when the user wants to generate or regenerate the API Specification document (api-spec.yaml) for a DocFlow project
---

# Generate API Specification

**Announce at start:** "I'm using docflow:api-spec to generate the API Specification."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `use-cases.md`, `domain-model.md`, and `ux-flow.md` all have `status: approved`.

If any is not approved:
> "Cannot generate api-spec.yaml — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/use-cases.md`, `docs/domain-model.md`, and `docs/ux-flow.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Endpoints | One endpoint per use-case action that requires a system call | Every use-case step that mutates state or fetches data must map to an endpoint |
| Request schemas | Input fields per endpoint | Field names and types derived from domain model entity attributes |
| Response schemas | Output structure per endpoint | Must include both success shape and error shape |
| Error codes | HTTP status codes per endpoint | At least one error response per endpoint |
| Authentication | Which endpoints require auth and what mechanism | Must be explicit — "standard auth" is not acceptable |

---

## Candidate-First Questioning

Read `docs/use-cases.md`, `docs/domain-model.md`, and `docs/ux-flow.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Note:** `api-spec.yaml` is a YAML document. When calling `docflow:pipeline`, specify that annotations should use YAML comment format (`# AI Reasoning:`, `# Assumption:`, `# Review focus:`).

**Opening question — derive candidate endpoints from use-case main flow action verbs:**
> "Based on the use cases, I've identified these candidate API endpoints (one per state-mutating or data-fetching action):
>
> 1. **POST /[resource]** — [use-case action, e.g. create order] *(recommended)*
> 2. **GET /[resource]/{id}** — [fetch action]
> 3. **PUT /[resource]/{id}** — [update action]
> 4. **DELETE /[resource]/{id}** — [delete action if applicable]
> N. Other — describe your own
>
> Which endpoints are needed? You can rename paths, adjust methods, or add your own."

**For each confirmed endpoint — derive candidate request fields from domain model attributes:**
> "For **[Method] [Path]**, the domain model suggests these request body fields:
>
> 1. **[Attribute from domain entity]** (type: [type], required: true) *(recommended)*
> 2. **[Second attribute]** (type: [type], required: [true/false])
> 3. Other — describe your own
>
> Which fields are correct? Add type and required status for each."

**For each endpoint — derive candidate response shapes from domain model entities:**
> "For the success response of **[Method] [Path]**:
>
> 1. **HTTP [status] with [entity] object** *(recommended — matches domain model shape)*
> 2. **HTTP [status] with [minimal/id-only] shape**
> 3. Other — describe your own"

**For error codes — derive candidates from use-case alternative flows and domain model invariants:**
> "For **[Method] [Path]**, likely error responses based on the use cases and invariants:
>
> 1. **400 Bad Request** — invalid input *(recommended — always required for mutating endpoints)*
> 2. **401 Unauthorized** — missing or invalid auth (if auth required)
> 3. **404 Not Found** — [resource] does not exist
> 4. **409 Conflict** — [invariant violation from domain model]
> N. Other — describe your own
>
> Which error codes apply?"

**For authentication — derive from the PRD target users and security context:**
> "Which endpoints require authentication?
>
> 1. **All endpoints** *(recommended — default for most products)*
> 2. All except: [specific public endpoints, e.g. GET /products]
> 3. None — this API is fully public
> 4. Other — describe your own"

**Coverage check before proceeding:**
- Every use-case step that mutates state maps to an endpoint
- Every use-case step that fetches data for display maps to an endpoint
- Every endpoint has at least one error response
- Authentication requirement is explicit for every endpoint

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The request fields are obvious from the entity name" | Undefined fields become inconsistent API contracts. List every field with its type. |
| "We only need the happy path response" | API consumers must handle errors. Every endpoint needs at least one error response defined. |
| "Auth requirement is obvious" | Unstated auth requirements become security gaps. State it explicitly for every endpoint. |
| "This use-case action doesn't need its own endpoint" | If the use case mutates state, it needs an endpoint. If it fetches data, it needs an endpoint. |

---

## Template

Use `templates/api-spec.yaml`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/use-cases.md` content as dependency
- `docs/domain-model.md` content as dependency
- `docs/ux-flow.md` content as dependency
- Specify: this is a YAML document — use YAML comment annotation format

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — api-spec checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep "api-spec"
```

Expected: all api-spec checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/api-spec/
git commit -m "feat: add docflow:api-spec document skill"
```

---

### Task 9: docflow:api-implement-logic skill

**Files:**
- Create: `skills/api-implement-logic/SKILL.md`

- [ ] **Step 1: Create skills/api-implement-logic/SKILL.md**

```markdown
---
name: docflow:api-implement-logic
description: Use when the user wants to generate or regenerate the API Implementation Logic document (api-implement-logic.md) for a DocFlow project
---

# Generate API Implementation Logic

**Announce at start:** "I'm using docflow:api-implement-logic to generate the API Implementation Logic document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `use-cases.md`, `api-spec.yaml`, and `domain-model.md` all have `status: approved`.

If any is not approved:
> "Cannot generate api-implement-logic.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected for every endpoint in api-spec.yaml before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Business rules | Per-endpoint logic that the schema alone does not express | At least one business rule per endpoint |
| Data transformations | How input data is mapped, validated, or enriched before persistence | Required for any endpoint that stores or modifies data |
| Side effects | Non-obvious actions triggered by the endpoint (emails, events, background jobs) | Must be explicit — omitted side effects become bugs |
| Sequencing | Order-dependent operations within an endpoint | Required whenever multiple writes or external calls occur |
| Invariant checks | Which domain model invariants this endpoint must enforce | Every domain invariant relevant to the endpoint's entities must appear |

---

## Candidate-First Questioning

Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` before asking any question.

Ask one question per message. Iterate through each endpoint in api-spec.yaml. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**For each endpoint — derive candidate business rules from domain model invariants and use-case pre/postconditions:**
> "For **[Method] [Path]**, the domain model and use cases suggest these business rules:
>
> 1. **[Rule derived from domain invariant or use-case precondition]** *(recommended)*
> 2. **[Second rule]**
> 3. Other — describe your own
>
> Which rules must this endpoint enforce? At least one is required."

**For data transformations — derive from domain model attribute types and use-case input descriptions:**
> "For **[Method] [Path]**, the following data transformations are likely needed before persistence:
>
> 1. **Validate [field] is [type/constraint from domain model]** *(recommended)*
> 2. **Enrich [field] with [derived value]**
> 3. None — data is stored as-is
> 4. Other — describe your own"

**For side effects — derive from use-case postconditions and PRD goals:**
> "After **[Method] [Path]** succeeds, these side effects may occur based on the use cases:
>
> 1. **[Side effect derived from use-case postcondition, e.g. send confirmation email]** *(recommended)*
> 2. **[Second side effect, e.g. emit domain event]**
> 3. None
> 4. Other — describe your own
>
> Which side effects apply? Unwritten side effects become missing features."

**For sequencing — derive from use-case step ordering and domain constraints:**
> "For **[Method] [Path]**, operations must happen in this order:
>
> 1. **[Step order derived from domain invariants and use-case flow]** *(recommended)*
> 2. [Alternative ordering]
> 3. No ordering constraint — operations are independent
> 4. Other — describe your own"

**For invariant checks — derive directly from domain model invariants for this endpoint's entities:**
> "The domain model defines these invariants relevant to **[Method] [Path]**:
>
> 1. **[Invariant from domain model for affected entity]** *(recommended — must be enforced)*
> 2. **[Second invariant]**
> 3. Other — describe your own
>
> Which invariants must this endpoint check before writing?"

**Coverage check before proceeding:**
- Every endpoint in api-spec.yaml has at least one business rule
- Every endpoint that writes data has explicit data transformation steps
- Every endpoint has explicit side effects (or explicitly "none")
- Every domain invariant for the affected entities appears in at least one endpoint's invariant check list

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The business rules are just the schema validation" | Schema validation is not a business rule. Business rules are the constraints the schema cannot express. |
| "There are no side effects for this endpoint" | Ask again: does success trigger an email? An event? A job? A cache invalidation? Default to "none" only after explicitly checking each. |
| "The sequencing is obvious" | Unwritten operation order becomes a race condition or data integrity bug under load. Write it. |
| "The invariant checks happen in the database" | Document them here regardless. The implementation logic document is for humans, not the database. |

---

## Template

Use `templates/api-implement-logic.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/use-cases.md` content as dependency
- `docs/api-spec.yaml` content as dependency
- `docs/domain-model.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — api-implement-logic checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep "api-implement-logic"
```

Expected: all api-implement-logic checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/api-implement-logic/
git commit -m "feat: add docflow:api-implement-logic document skill"
```

---

### Task 10: docflow:test-spec skill

**Files:**
- Create: `skills/test-spec/SKILL.md`

- [ ] **Step 1: Create skills/test-spec/SKILL.md**

```markdown
---
name: docflow:test-spec
description: Use when the user wants to generate or regenerate the Test Specification document (test-spec.md) for a DocFlow project
---

# Generate Test Specification

**Announce at start:** "I'm using docflow:test-spec to generate the Test Specification document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `use-cases.md`, `api-spec.yaml`, and `domain-model.md` all have `status: approved`.

If any is not approved:
> "Cannot generate test-spec.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Happy path scenarios | One scenario per use-case main flow | Every use case must have at least one happy path test |
| Negative path scenarios | Tests for invalid inputs, missing auth, constraint violations | At least one negative path per endpoint in api-spec.yaml |
| Edge cases | Boundary conditions from domain model invariants | Every invariant must have a corresponding edge case test |
| Acceptance criteria | Explicit pass/fail conditions per scenario | Every scenario must have measurable acceptance criteria |

---

## Candidate-First Questioning

Read `docs/use-cases.md`, `docs/api-spec.yaml`, and `docs/domain-model.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate happy path scenarios from use-case main flows:**
> "Based on the use cases, I've identified these candidate happy path test scenarios:
>
> 1. **[UC-1 main flow as a test scenario]** *(recommended)*
> 2. **[UC-2 main flow as a test scenario]**
> 3. [Additional use case]
> N. Other — describe your own
>
> Which scenarios should be included? Every use case must have at least one."

**For each happy path scenario — derive candidate steps and inputs from the use-case main flow:**
> "For the **[Scenario Name]** scenario, the use-case main flow maps to these test steps:
>
> 1. [Step 1 from main flow with test input]
> 2. [Step 2]
> 3. [Step 3]
>
> Does this match? What steps or inputs need adjustment?"

**For acceptance criteria — derive from use-case postconditions and api-spec response schemas:**
> "For **[Scenario Name]**, the test passes when:
>
> 1. **[Postcondition from use case as a measurable assertion]** *(recommended)*
> 2. **[API response check from api-spec success shape]**
> 3. Other — describe your own
>
> Which criteria must pass for this scenario to be considered successful?"

**For negative path scenarios — derive from use-case alternative flows and api-spec error codes:**
> "Based on the use-case alternative flows and api-spec error codes, these negative path scenarios are needed:
>
> 1. **[Alt flow 1 as a test: invalid input → 400]** *(recommended)*
> 2. **[Missing auth → 401]** (if endpoint requires auth)
> 3. **[Resource not found → 404]**
> 4. **[Invariant violation → 409]** (if domain model has a relevant invariant)
> N. Other — describe your own
>
> Which negative paths must be tested? At least one per endpoint."

**For edge cases — derive directly from domain model invariants:**
> "The domain model defines these invariants that need edge case tests:
>
> 1. **[Invariant A] → test: [boundary condition that would violate it]** *(recommended)*
> 2. **[Invariant B] → test: [its boundary condition]**
> N. Other — describe your own
>
> Which edge cases should be included? Every invariant needs a test."

**Coverage check before proceeding:**
- Every use case has at least one happy path scenario
- Every endpoint in api-spec.yaml has at least one negative path scenario
- Every domain model invariant has at least one edge case test
- Every scenario has explicit, measurable acceptance criteria

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The negative paths are obvious from the error codes" | Obvious tests that aren't written don't get run. Write the scenario. |
| "This invariant doesn't need its own test" | Invariants without tests get violated in production. One test per invariant, no exceptions. |
| "The acceptance criteria is just 'it works'" | Untestable acceptance criteria means the test cannot be automated or reviewed. Define what observable state proves success. |
| "Happy path tests are enough" | Use-case alternative flows document the failure modes your users will encounter. Test them. |

---

## Template

Use `templates/test-spec.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/use-cases.md` content as dependency
- `docs/api-spec.yaml` content as dependency
- `docs/domain-model.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — test-spec checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep "test-spec"
```

Expected: all test-spec checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/test-spec/
git commit -m "feat: add docflow:test-spec document skill"
```

---

### Task 11: Final validation

**Files:**
- No new files

- [ ] **Step 1: Run full validate.sh**

```bash
cd /Users/honghaowu/projects/docflow
bash tests/validate.sh
```

Expected output ends with:
```
=== Results: N passed, 0 failed ===
```

All checks must pass. If any fail, fix the failing file before proceeding.

- [ ] **Step 2: Verify git log is clean**

```bash
git log --oneline
```

Expected: all commits are `feat:`, `test:`, or `docs:` prefixed.

- [ ] **Step 3: Commit this plan**

```bash
git add docs/superpowers/plans/2026-04-16-docflow-full-plugin.md
git commit -m "docs: add DocFlow full plugin implementation plan"
```
