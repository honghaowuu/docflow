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
