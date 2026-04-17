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
> "For **[Goal 1]**, a candidate success metric:
>
> 1. **[Specific metric]** *(recommended)*
> 2. **[Alternative metric]**
> N. Other — describe your own"
>
> *(Repeat for each goal. One metric per goal.)*

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
