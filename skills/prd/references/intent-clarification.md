# Intent Clarification Protocol

## Why Intent Clarification Is Needed

Users' initial descriptions are often vague or incomplete. A statement like "I want to build X feature" may hide:
- Unstated business context and constraints
- Different understandings of the feature's scope
- Implicit priority and trade-off preferences
- Specific user scenarios and pain points
- Hidden expectations about success criteria

## Clarification Dimensions

The host asks questions across the following dimensions, but **does not need to cover all dimensions at once**. Adjust dynamically based on user responses — skip dimensions that are already clear.

### 1. Background and Motivation
- What is the source of this requirement? (user feedback / business goal / competitive pressure / internal discovery)
- Why now? What triggered this?
- What is the ultimate business objective?

### 2. Target Users and Scenarios
- Who is this feature/solution for?
- How are users currently solving this problem? (existing solutions / workarounds)
- What is the core use case? Can you give a concrete example?

### 3. Scope and Boundaries
- How large is this effort in your view? (small feature / medium feature / large product direction)
- Is there anything explicitly out of scope?
- What existing features or modules does this relate to?

### 4. Expectations and Constraints
- What form of output do you expect? (directional exploration / detailed PRD / option comparison / problem diagnosis)
- Are there any hard constraints? (time, resources, technical limitations, compliance requirements)
- Do you already have preferences or leanings?

### 5. Success Criteria
- How will you know this was done well? Are there measurable indicators?
- Who are the stakeholders that need to be aligned?

## Confirmation Template

When the host believes it has sufficient information, present a summary for user confirmation:

```
Based on our conversation, here is my understanding of what you need:

**Background**: {…}
**Core objective**: {…}
**Target users**: {…}
**Key scenarios**: {…}
**Scope**: {…}
**Constraints**: {…}
**Expected output**: {…}

Is my understanding accurate? Anything to add or correct?
```

## Output: `.docflow/intent-brief.md`

```markdown
# Intent Brief

> DocFlow project: "{project_name}"
> Clarified at: {ISO timestamp}

## Background and Motivation
{Business context, source of requirement, triggering factors}

## Core Objective
{What the user wants to achieve — 1-3 sentences}

## Target Users
{User profiles and priority order}

## Key Scenarios
{Core use cases with concrete examples}

## Scope and Boundaries
- **In scope**: {explicitly included}
- **Out of scope**: {explicitly excluded}
- **TBD**: {needs confirmation during discussion}

## Constraints
{Hard constraints: time, resources, compliance, compatibility}

## Expected Output
{Desired form and depth of the final output}

## Success Criteria
{How to measure success}
```

## State Update

After writing the brief, update `.docflow/debate/<slug>/.debate-state`:
```yaml
last_action: "intent_clarified"
intent_confirmed: true
intent_confirmed_at: "<ISO timestamp>"
```

## Special Cases

- **Topic is already very clear**: Still run intent clarification, but compress to 1 round. Confirm: "Your description is already quite clear — let me confirm my understanding…"
- **User pushes to skip**: Explain the cost of misalignment, but if they insist, compress to 1 round and mark as "fast confirmation."
- **User changes direction mid-debate**: If the change is significant, pause, update `intent-brief.md`, then reassess whether the debate framework needs adjustment.
