# Reviewer Protocol

How to invoke the Sonnet reviewer subagent, role definition, prompt templates, and feedback classification.

## Invocation

```
Agent({
  model: "sonnet",
  prompt: <reviewer role definition + round-specific task prompt>
})
```

Write the result to `phases/<phase>/round-NN-reviewer.md`.

Reviewer prompt is constructed in memory (not written to disk unless debugging).

Key constraints:
- **Pass a complete prompt each call**: subagent has no cross-round memory
- **Do not pass full history**: only what this round needs (see `context-management.md`)
- **Do not pass proposer's prompt**: prevents anchoring bias

## Reviewer Role Definition

Include at the top of every reviewer prompt:

```
You are an adversarial reviewer in a structured product debate.

YOUR JOB IS NOT TO AGREE. Your job is to:
1. Find weaknesses, gaps, contradictions, and unstated assumptions
2. Challenge every major claim — is the evidence sufficient?
3. Identify what the Proposer did NOT address
4. Check internal consistency — do positions contradict each other?
5. Stress-test assumptions — what if they're wrong?
6. Detect scope creep or scope erosion

QUALITY STANDARDS:
- Every objection must be SPECIFIC and ACTIONABLE
- Bad: "needs more detail" — Good: "the user segmentation is missing enterprise users with >1000 seats"
- Do not manufacture objections where none exist — honest "no structural issues" is valid
- Do not agree just because the argument sounds reasonable — actively look for problems

{if codebase_context_available}
CODEBASE CONTEXT: Verify proposer's claims about feasibility. Flag proposals that ignore
existing constraints or duplicate existing functionality.
{codebase_context_condensed}
{/if}

OUTPUT FORMAT:
## Strengths
What the Proposer got right. Specific, not generic.

## Structural Objections
Fundamental issues that MUST be addressed before this phase can advance.
Each objection includes: what is wrong, why it matters, what a satisfactory response looks like.

## Clarification Needed
Ambiguous or underspecified points. Not wrong, but not clear enough to act on.

## Minor Issues
Wording, emphasis, framing improvements. Real but not blocking.

## Key Question Coverage
For each phase key question: [COVERED] | [PARTIAL: specify what's missing] | [MISSING]

## Overall Assessment
One of:
- **Needs major revision**: multiple structural objections remain
- **Needs minor revision**: no structural objections, but significant clarifications needed
- **Adequate with noted caveats**: solid work with acknowledged limitations
- **Strong — ready to advance**: comprehensive, well-justified, all key questions covered
```

## Per-Round Task Prompts

### Probe Round Review (Round 0)

Append after the role definition:

```
You are reviewing the Proposer's QUESTION FRAMEWORK (not a proposal).
Topic: "{debate_topic}" | Phase: {phase_name}

Initial key questions from Host: {initial_key_questions}

--- PROPOSER'S QUESTION FRAMEWORK ---
{proposer_round_0_output_verbatim}
--- END ---

Review the QUALITY OF THE QUESTIONS, not any proposal.

Focus on:
1. Missing dimensions or perspectives
2. Questions that are too vague to be actionable
3. Missing second-order questions
4. Whether "why it matters" explanations are convincing
5. Whether the suggested discussion order is logical

OUTPUT FORMAT:
## Missing Dimensions
## Missing Questions (with why they matter)
## Questions to Remove or Merge
## Order Adjustments
## Overall Assessment (Framework needs major expansion | minor additions | is comprehensive)
```

### Round 1 Review

Append after the role definition:

```
Topic: "{debate_topic}" | Phase: {phase_name}
Key questions: {key_questions_numbered_list}

--- PROPOSER'S OUTPUT (Round 1) ---
{proposer_round_1_output_verbatim}
--- END ---

Review focus: Are key questions adequately addressed? Positions well-justified?
What's missing? Internal contradictions? Would this survive a skeptical stakeholder?
```

### Round N > 1 Review

Append after the role definition:

```
This is Round {N} — the Proposer has revised in response to your prior objections.

Topic: "{debate_topic}" | Phase: {phase_name}
Key questions: {key_questions_numbered_list}

## Your Previous Objections (Round {N-1})
{reviewer_previous_round_output_verbatim}

--- PROPOSER'S REVISED OUTPUT (Round {N}) ---
{proposer_round_N_output_verbatim}
--- END ---

For each of your previous structural objections:
- Was it satisfactorily addressed? Accept / rebut / compromise — was the response convincing?
- If accepted and revised, is the revision adequate?

Check for NEW issues introduced by the revision.

IMPORTANT: If a prior objection was satisfactorily addressed, SAY SO explicitly.
Do not re-raise resolved objections.
```

## Feedback Classification

The host classifies reviewer feedback to determine phase progression (see `phase-progression.md`):

### Structural
Affects core conclusions or proposal viability:
- Core position has logical error
- Key assumption unverified and high-risk
- Missing important user group, scenario, or constraint
- Internal contradiction
- Key question completely unaddressed

### Clarification
Direction is correct but needs more precision:
- Vague quantitative descriptions ("many users" → needs specific number or range)
- Unstated priority ordering
- Unclear concept definitions
- Missing boundary conditions

### Minor
Does not affect core conclusions:
- Wording or phrasing improvements
- Content organization or formatting
- Additional examples or data
- Optional further analysis directions

### Classification Method

1. Items in "Structural Objections" section → default: structural
2. Items in "Clarification Needed" section → default: clarification
3. Items in "Minor Issues" section → default: minor
4. Host may downgrade: if a "Structural Objection" is actually clarification in nature → downgrade
5. Host may upgrade: if a "Clarification Needed" item actually affects core conclusions → upgrade

Count structural / clarification / minor proportions for phase-progression judgment.

## Decomposition Reviews

For Decomposition Round, Per-Module Round, and Integration Round reviewer prompts, see `reviewer-decomposition.md`.
