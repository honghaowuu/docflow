# DocFlow Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the DocFlow Claude Code plugin — a skills-based documentation pipeline that enforces dependency order, guides document generation through dynamic questioning, and manages human review with annotated drafts.

**Architecture:** Layered skills pattern: `docflow:start` (orchestrator bootstrapped by hook) → `docflow:<doc>` (document-specific intake) → `docflow:pipeline` (shared generate/review/commit pipeline). Git-native state: `.docflow/status.yaml` committed to the project repo tracks approval states; `git log` detects change impact.

**Tech Stack:** Bash (hook script), Markdown (SKILL.md files, templates), YAML (status file), Claude Code plugin conventions.

---

### Task 1: Plugin scaffold and validation script

**Files:**
- Create: `package.json`
- Create: `tests/validate.sh`

- [ ] **Step 1: Write the failing validation test**

Create `tests/validate.sh`:

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
check_file "templates/prd.md"
check_file "templates/use-cases.md"
check_file "templates/domain-model.md"

echo ""
echo "--- Skill Frontmatter (CSO descriptions) ---"
for skill in start pipeline prd use-cases domain-model; do
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
echo "--- REQUIRED SUB-SKILL Handoffs ---"
check_contains "skills/prd/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "prd: hands off to pipeline"
check_contains "skills/use-cases/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "use-cases: hands off to pipeline"
check_contains "skills/domain-model/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "domain-model: hands off to pipeline"

echo ""
echo "--- Templates ---"
check_contains "templates/prd.md" "<!-- AI Generated -->" "prd template: AI Generated markers"
check_contains "templates/prd.md" "<!-- Human Review Required -->" "prd template: Human Review Required markers"
check_contains "templates/use-cases.md" "<!-- AI Generated -->" "use-cases template: AI Generated markers"
check_contains "templates/use-cases.md" "<!-- Human Review Required -->" "use-cases template: Human Review Required markers"
check_contains "templates/domain-model.md" "<!-- AI Generated -->" "domain-model template: AI Generated markers"
check_contains "templates/domain-model.md" "<!-- Human Review Required -->" "domain-model template: Human Review Required markers"

echo ""
echo "--- Hook ---"
check_executable "hooks/session-start"
check_contains "hooks/hooks.json" "SessionStart" "hooks.json: has SessionStart event"
check_contains "hooks/hooks.json" "session-start" "hooks.json: references session-start script"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
```

- [ ] **Step 2: Run validate.sh to confirm it fails**

```bash
cd /home/honghaowu/project/docflow
chmod +x tests/validate.sh
bash tests/validate.sh
```

Expected: multiple FAIL lines — no files exist yet. Script exits with code 1.

- [ ] **Step 3: Create package.json**

```json
{
  "name": "docflow",
  "version": "1.0.0",
  "description": "AI-assisted documentation generation plugin for Claude Code"
}
```

- [ ] **Step 4: Commit scaffold**

```bash
git add tests/validate.sh package.json
git commit -m "feat: add plugin scaffold and validation script"
```

---

### Task 2: Hook files

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/session-start`

- [ ] **Step 1: Create hooks/hooks.json**

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

- [ ] **Step 2: Create hooks/session-start**

```bash
#!/usr/bin/env bash
# DocFlow SessionStart hook.
# Injects docflow:start skill if a DocFlow project is detected,
# otherwise emits an init prompt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

emit_json() {
    local content="$1"
    local escaped
    escaped=$(escape_for_json "$content")
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$escaped"
}

# No DocFlow project in CWD — emit init prompt only
if [ ! -f ".docflow/status.yaml" ]; then
    emit_json "No DocFlow project detected. Say 'init docflow' to initialize a new DocFlow project in this directory."
    exit 0
fi

# DocFlow project detected — inject docflow:start skill
# Use raw skill content (not pre-escaped) so emit_json handles escaping in one pass.
start_skill=$(cat "${PLUGIN_ROOT}/skills/start/SKILL.md" 2>/dev/null \
    || echo "Error: could not read docflow:start skill")

context="<EXTREMELY_IMPORTANT>"$'\n'"You have the DocFlow plugin installed."$'\n\n'"**Below is the full content of your 'docflow:start' skill. Follow it now.**"$'\n\n'"${start_skill}"$'\n'"</EXTREMELY_IMPORTANT>"

emit_json "$context"
```

- [ ] **Step 3: Make session-start executable**

```bash
chmod +x hooks/session-start
```

- [ ] **Step 4: Smoke-test the hook (no DocFlow project)**

```bash
cd /home/honghaowu/project/docflow
bash hooks/session-start
```

Expected output: JSON with `"No DocFlow project detected..."` in `additionalContext`. Verify it is valid JSON:

```bash
bash hooks/session-start | python3 -m json.tool > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

Expected: `Valid JSON`

- [ ] **Step 5: Smoke-test with a mock project**

```bash
mkdir -p /tmp/docflow-test/.docflow
echo "version: 1" > /tmp/docflow-test/.docflow/status.yaml
cd /tmp/docflow-test
bash /home/honghaowu/project/docflow/hooks/session-start | python3 -m json.tool > /dev/null \
    && echo "Valid JSON" || echo "Invalid JSON"
cd /home/honghaowu/project/docflow
rm -rf /tmp/docflow-test
```

Expected: `Valid JSON`

- [ ] **Step 6: Commit hook files**

```bash
git add hooks/hooks.json hooks/session-start
git commit -m "feat: add session-start hook"
```

---

### Task 3: Templates

**Files:**
- Create: `templates/prd.md`
- Create: `templates/use-cases.md`
- Create: `templates/domain-model.md`

- [ ] **Step 1: Create templates/prd.md**

```markdown
# Product Requirements Document

## Problem Statement
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Target Users
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Goals
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Non-Goals
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Success Metrics
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Risks & Mitigations
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 2: Create templates/use-cases.md**

```markdown
# Use Cases

## Actors
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Use Cases

<!-- Repeat the block below for each use case -->

### UC-[N]: [Use Case Name]

#### Goal
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

#### Preconditions
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

#### Main Flow
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

#### Alternative Flows
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

#### Postconditions
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 3: Create templates/domain-model.md**

```markdown
# Domain Model

## Entities

<!-- Repeat the block below for each entity -->

### [Entity Name]

#### Attributes
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

#### Invariants
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Relationships
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed

## Glossary
<!-- AI Generated -->

<!-- Human Review Required -->
[ ] Confirmed
```

- [ ] **Step 4: Run validate.sh — template checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(Templates|PASS|FAIL)"
```

Expected: all 6 template checks show `PASS`.

- [ ] **Step 5: Commit templates**

```bash
git add templates/
git commit -m "feat: add document templates with review markers"
```

---

### Task 4: docflow:start skill

**Files:**
- Create: `skills/start/SKILL.md`

- [ ] **Step 1: Create skills/start/SKILL.md**

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
sha256sum docs/<doc> | cut -d' ' -f1
```

If it differs from `content_hash` in status.yaml → warn the user:
> "⚠ `docs/<doc>` was manually edited after its last approval. Changes may be lost if regenerated. Would you like to preserve edits or treat this as a new draft?"

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
```

- [ ] **Step 2: Run validate.sh — start skill checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(start|PASS|FAIL)" | head -20
```

Expected: all start-related checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/start/
git commit -m "feat: add docflow:start orchestrator skill"
```

---

### Task 5: docflow:pipeline skill

**Files:**
- Create: `skills/pipeline/SKILL.md`

- [ ] **Step 1: Create skills/pipeline/SKILL.md**

```markdown
---
name: docflow:pipeline
description: Use when a DocFlow document skill has finished collecting intake answers and is ready to generate, annotate, review, and commit a document
---

# DocFlow Document Pipeline

This skill is called by document skills after intake is complete. It receives:
- **document type** (e.g. `prd.md`)
- **template path** (e.g. `templates/prd.md`)
- **intake answers** (collected during guided questioning)
- **dependency file contents** (contents of approved dependency documents)

---

## Iron Laws

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

## Step 1: Generate

Using the intake answers and dependency content, fill every `<!-- AI Generated -->` section in the template.

**Before proceeding:** Scan the assembled document for any remaining `<!-- AI Generated -->` markers. If any exist, fill them now. A document with unfilled markers MUST NOT continue to Step 2.

---

## Step 2: Annotate

After each generated section body, insert three annotation lines:

```markdown
> **AI Reasoning:** [what inputs and logic produced this content — be specific: which intake answer, which dependency section]
> **Assumption:** [any inference you made that the human must explicitly validate — if no assumption was made, write "None"]
> **Review focus:** [the single most important question the reviewer should answer before confirming this section]
```

Place annotations between the generated content and the `<!-- Human Review Required -->` marker.

**Before proceeding:** Verify every section has all three annotation lines. A section with any missing annotation MUST NOT be written to disk.

---

## Step 3: LLM Self-Review

Before writing to disk, review the assembled document:

- [ ] All `<!-- AI Generated -->` sections are filled
- [ ] Every section has all three annotation types
- [ ] No logical contradictions between sections
- [ ] Content is consistent with dependency documents
- [ ] Goals are measurable (for prd.md)
- [ ] Every risk has a mitigation (for prd.md)

Fix any issues inline. Do not write until this checklist passes.

---

## Step 4: Write Annotated Draft

Write the annotated document to `docs/<doc>`.

Tell the user:
> "Generated `docs/<doc>` — please open and review it in your editor. Let me know if you'd like any changes or are ready to approve."

---

## Step 5: Human Review Loop

**If the user requests changes:**
- Apply the requested edits to the in-memory content
- Rewrite `docs/<doc>` with the updated annotated content
- Repeat: "Updated `docs/<doc>` — please review again and let me know when you're ready to approve."

**If the user approves:**
- Proceed to Step 6.

---

## Step 6: Strip Annotations

Remove the following from the document content:

- All lines matching `> **AI Reasoning:***`
- All lines matching `> **Assumption:***`
- All lines matching `> **Review focus:***`
- All `<!-- AI Generated -->` markers
- All `<!-- Human Review Required -->` markers
- All `[ ] Confirmed` lines

---

## Step 7: Write Clean Document

Overwrite `docs/<doc>` with the stripped, annotation-free content.

---

## Step 8: Update status.yaml

Compute the content hash of the clean file:
```bash
sha256sum docs/<doc> | cut -d' ' -f1
```

Update `.docflow/status.yaml` for this document:
```yaml
status: approved
generated_at: <current ISO 8601 timestamp>
approved_at: <current ISO 8601 timestamp>
content_hash: sha256:<hash>
```

Remove `outdated_because` if it was present.

---

## Step 9: Commit

```bash
git add docs/<doc> .docflow/status.yaml
git commit -m "docflow: generate <doc>"
```

Tell the user:
> "`docs/<doc>` approved and committed. Run `docflow:start` to see updated project status."
```

- [ ] **Step 2: Run validate.sh — pipeline checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(pipeline|Iron Law|PASS|FAIL)" | head -20
```

Expected: all pipeline-related checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/pipeline/
git commit -m "feat: add docflow:pipeline shared pipeline skill"
```

---

### Task 6: docflow:prd skill

**Files:**
- Create: `skills/prd/SKILL.md`

- [ ] **Step 1: Create skills/prd/SKILL.md**

```markdown
---
name: docflow:prd
description: Use when the user wants to generate or regenerate the Product Requirements Document (prd.md) for a DocFlow project
---

# Generate PRD

**Announce at start:** "I'm using docflow:prd to generate the Product Requirements Document."

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|-------|-------------|------------|
| Problem | The specific problem this product solves | Must name who is affected and what it costs them |
| Primary users | Who uses it most | Must be a specific role or persona, not "everyone" |
| Secondary users | Who else uses it (may be none) | Can be empty |
| Goals | 2–5 outcomes the product must achieve | Each must be measurable |
| Non-goals | What this explicitly does NOT do | Must be explicitly stated — empty is not acceptable |
| Success metrics | How we measure each goal | One metric per goal |
| Risks | What could prevent success or cause harm | At least one risk required |
| Mitigations | How each risk is addressed | One mitigation per risk |

---

## Dynamic Questioning

Ask one question at a time. Never ask more than one question per message.

**Opening question:**
> "What problem does this product solve?"

**Decision tree after each answer:**

- Answer is vague or abstract (e.g., "improve productivity", "make things easier") →
  > "Who experiences this problem most acutely, and what does it cost them in time, money, or quality?"

- Problem is clear → move to users:
  > "Who are the primary users of this product?"

- Users defined → move to goals:
  > "What are the 2–5 most important outcomes this product must achieve for those users?"

- A goal is vague (e.g., "better experience", "faster workflow") → validate it:
  > "How would you measure '[goal]'? What does success look like in observable or numeric terms?"

- Goals are measurable → move to non-goals:
  > "What are the explicit non-goals — things this product will NOT do, even if they seem related?"

- Non-goals defined → move to metrics:
  > "For each goal, what is the specific metric that tells you the goal has been achieved?"

- Metrics defined → move to risks:
  > "What is the most likely thing that could prevent this product from succeeding?"

- Each risk identified → ask for mitigation:
  > "How will you address that risk?"

- Continue until every field in the Required Information table is covered.

**Coverage check before proceeding:**
Can you fill every row of the Required Information table from the answers collected? If any row is empty, ask the missing question before proceeding.

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The non-goals are obvious, I'll skip that section" | Unstated non-goals become assumptions that cause scope creep. Make them explicit. |
| "This goal is clear enough without a metric" | Unmeasured goals cannot be evaluated. Every goal needs a metric. |
| "We don't have any real risks" | Every product has risks. Dig: technical, adoption, resource, timeline. |

---

## Template

Use `templates/prd.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- No dependency files (prd.md has no dependencies)

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — prd checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(prd|handoff|PASS|FAIL)" | head -10
```

Expected: prd-related checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/prd/
git commit -m "feat: add docflow:prd document skill"
```

---

### Task 7: docflow:use-cases skill

**Files:**
- Create: `skills/use-cases/SKILL.md`

- [ ] **Step 1: Create skills/use-cases/SKILL.md**

```markdown
---
name: docflow:use-cases
description: Use when the user wants to generate or regenerate the Use Cases document (use-cases.md) for a DocFlow project
---

# Generate Use Cases

**Announce at start:** "I'm using docflow:use-cases to generate the Use Cases document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify `prd.md` has `status: approved`.

If not approved:
> "Cannot generate use-cases.md — prd.md must be approved first. Would you like to generate prd.md instead?"

Stop here. Do not proceed without an approved prd.md.

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|-------|-------------|------------|
| Actors | All people and systems that interact with the product | Derived from prd.md target users — confirm and extend |
| Use cases | One use case per actor goal | Each must have: goal, preconditions, main flow, alternative flows, postconditions |

**Minimum:** Every goal from prd.md Goals section must map to at least one use case.

---

## Dynamic Questioning

Ask one question at a time. Never ask more than one question per message.

**Start by reading `docs/prd.md`** — extract target users as candidate actors and goals as candidate use case goals.

**Opening question:**
> "Based on the PRD, I've identified these actors: [list from prd.md target users]. Are there others, or should any of these be renamed or split into more specific roles?"

**For each confirmed actor:**
> "What is the most critical thing [actor] needs to accomplish with this product?"

**For each goal identified per actor, walk through the use case:**

1. > "Walk me through the steps [actor] takes to accomplish [goal]. What do they do first?"
   Continue prompting until the main flow has at least 3 concrete steps.

2. > "What could go wrong at any step in that flow? What does [actor] do when it fails?"
   Capture at least one alternative flow per use case.

3. > "What must be true before [actor] can start this use case? Any system state or prerequisites?"

4. > "What is the exact state of the system when this use case completes successfully?"

**Coverage check before proceeding:**
- Every PRD goal maps to at least one use case → if not, ask: "The PRD lists '[goal]' — which use case covers this?"
- Every use case has at least one alternative flow → if not, ask: "What happens if [step] fails in UC-[N]?"
- Every use case has explicit preconditions → if not, ask: "What must be true before [actor] can start UC-[N]?"

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The alternative flows are obvious" | Alternative flows that aren't written don't get implemented. Write them. |
| "This PRD goal is covered implicitly by another use case" | Implicit coverage is invisible coverage. Map it explicitly or explain why the goal is no longer valid. |
| "Preconditions are just common sense" | Engineers implement what is written. Common sense preconditions become bugs. |

---

## Template

Use `templates/use-cases.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — use-cases checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(use-cases|PASS|FAIL)" | head -10
```

Expected: use-cases-related checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/use-cases/
git commit -m "feat: add docflow:use-cases document skill"
```

---

### Task 8: docflow:domain-model skill

**Files:**
- Create: `skills/domain-model/SKILL.md`

- [ ] **Step 1: Create skills/domain-model/SKILL.md**

```markdown
---
name: docflow:domain-model
description: Use when the user wants to generate or regenerate the Domain Model document (domain-model.md) for a DocFlow project
---

# Generate Domain Model

**Announce at start:** "I'm using docflow:domain-model to generate the Domain Model document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify both `prd.md` and `use-cases.md` have `status: approved`.

If either is not approved:
> "Cannot generate domain-model.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|-------|-------------|------------|
| Entities | Core domain concepts | Not UI components, not infrastructure; every use-case noun must be accounted for |
| Attributes | Essential data fields per entity | Only what domain logic depends on — not persistence or display concerns |
| Invariants | Rules that must always hold for each entity | At least one invariant per entity |
| Relationships | How entities relate to each other | Every relationship must have cardinality (1:1, 1:N, M:N) |
| Glossary | Domain-specific terms | Every domain-specific term used in the document must appear here |

---

## Dynamic Questioning

Ask one question at a time. Never ask more than one question per message.

**Start by reading `docs/use-cases.md`** — extract nouns that appear as subjects or objects in main flows as candidate entities. Also read `docs/prd.md` for any domain terms introduced there.

**Opening question:**
> "I've identified these candidate entities from the use cases: [list of nouns]. Which of these are core domain concepts? Which are UI concerns (screens, forms, buttons) or infrastructure concerns (databases, queues, APIs) that should be excluded?"

**For each confirmed entity:**

1. > "What are the essential attributes of [entity]? Focus on what the domain logic actually depends on — not display fields or technical identifiers."

2. > "What rules must always be true about [entity]? For example: 'A [entity] must always have [field]', or '[entity] cannot be in states X and Y simultaneously.'"

**For relationships** (iterate through confirmed entity pairs that interact in use cases):
> "How does [entity A] relate to [entity B]? How many [A]s can one [B] have, and vice versa?"

**For the glossary:**
> "Are there any terms in this document that someone joining the team next week might misunderstand or interpret differently than you intend?"

**Coverage check before proceeding:**
- Every noun from use-case main flows is either included as an entity or explicitly excluded with a reason
- Every relationship has a cardinality
- Every entity has at least one invariant
- Every domain-specific term in the document appears in the glossary

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "This entity is obvious, we don't need to define its attributes" | Undefined attributes become inconsistent implementations across the codebase. |
| "The relationship cardinality is obvious from context" | Unwritten cardinality becomes a source of data integrity bugs. Write it. |
| "We don't have any invariants for this entity" | Every entity has constraints. Probe: "Can a [entity] exist without a [field]?" or "Can [entity] ever be in [state] and [other state] at the same time?" |
| "The glossary is overkill for an internal document" | Domain terms mean different things to different people. A glossary prevents meetings about meanings. |

---

## Template

Use `templates/domain-model.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency
- `docs/use-cases.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
```

- [ ] **Step 2: Run validate.sh — domain-model checks should now pass**

```bash
bash tests/validate.sh 2>&1 | grep -E "(domain-model|PASS|FAIL)" | head -10
```

Expected: domain-model-related checks show `PASS`.

- [ ] **Step 3: Commit**

```bash
git add skills/domain-model/
git commit -m "feat: add docflow:domain-model document skill"
```

---

### Task 9: Final validation and installation note

**Files:**
- No new files — run full validation and verify clean state

- [ ] **Step 1: Run full validate.sh**

```bash
cd /home/honghaowu/project/docflow
bash tests/validate.sh
```

Expected output:
```
=== DocFlow Plugin Validation ===

--- Structure ---
  PASS: package.json exists
  PASS: hooks/hooks.json exists
  PASS: hooks/session-start exists
  PASS: skills/start/SKILL.md exists
  PASS: skills/pipeline/SKILL.md exists
  PASS: skills/prd/SKILL.md exists
  PASS: skills/use-cases/SKILL.md exists
  PASS: skills/domain-model/SKILL.md exists
  PASS: templates/prd.md exists
  PASS: templates/use-cases.md exists
  PASS: templates/domain-model.md exists

--- Skill Frontmatter (CSO descriptions) ---
  PASS: start: has name frontmatter
  PASS: start: description starts with 'Use when'
  ... (all PASS)

--- Iron Laws ---
  PASS: pipeline: unfilled-section Iron Law
  PASS: pipeline: annotation Iron Law
  PASS: pipeline: approval Iron Law
  PASS: start: dependency Iron Law

--- REQUIRED SUB-SKILL Handoffs ---
  PASS: prd: hands off to pipeline
  PASS: use-cases: hands off to pipeline
  PASS: domain-model: hands off to pipeline

--- Templates ---
  PASS: prd template: AI Generated markers
  PASS: prd template: Human Review Required markers
  ... (all PASS)

--- Hook ---
  PASS: hooks/session-start is executable
  PASS: hooks.json: has SessionStart event
  PASS: hooks.json: references session-start script

=== Results: 37 passed, 0 failed ===
```

If any check fails, fix the issue before proceeding.

- [ ] **Step 2: Verify git log is clean**

```bash
git log --oneline
```

Expected: 9 commits (scaffold + hook + templates + 5 skills), all `docflow:` or `feat:` prefixed.

- [ ] **Step 3: Final commit (plan + validation)**

```bash
git add docs/superpowers/plans/2026-04-16-docflow-plugin.md
git commit -m "docs: add DocFlow implementation plan"
```

---

## Installation

To use the plugin in a project, add to the project's `.claude/settings.local.json`:

```json
{
  "enabledPlugins": {
    "docflow@local": "/home/honghaowu/project/docflow"
  }
}
```

Then open the project in Claude Code and say "init docflow" to initialize.
