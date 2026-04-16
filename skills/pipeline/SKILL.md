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
shasum -a 256 docs/<doc> | cut -d' ' -f1
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

Note: Use `shasum -a 256` (not `sha256sum`) for macOS compatibility.
