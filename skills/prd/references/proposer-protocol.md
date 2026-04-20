---
name: Proposer Protocol
---

# Proposer Protocol

How to invoke the Opus proposer subagent, prompt templates, and output requirements.

## Invocation

```
Agent({
  model: "opus",
  prompt: <contents of the constructed prompt>
})
```

Write the result to the appropriate output file (e.g., `phases/<phase>/round-NN-proposer.md`).

Write the prompt to `phases/<phase>/prompts/round-NN-proposer-prompt.md` for auditability.

## Prompt Templates

### Probe Round Prompt (Round 0 — Question Framework)

Used when the host determines a Probe Round is needed. The proposer outputs a question framework, NOT a proposal.

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"

Current phase: {phase_name}
Phase objective: {phase_objective}

The Host has provided these initial key questions:
{key_questions_numbered_list}

DO NOT answer these questions yet. Instead, your job is to BUILD A BETTER QUESTION
FRAMEWORK. Think deeply about:
- What does it mean to FULLY address this phase's objective?
- What information is needed to produce a truly thorough analysis?
- What dimensions or perspectives might the initial questions miss?

Produce a structured question framework that, when answered, would give someone
everything they need to make excellent decisions for this phase.
</task>

{if codebase_context_available}
<codebase_context>
{codebase_context_content}
</codebase_context>
{/if}

<structured_output_contract>
## Assessment of Initial Questions
Brief evaluation: are the Host's initial key questions sufficient? What do they miss?

## Question Framework
Group questions by dimension. For each question:
- The question itself (specific, not vague)
- **Why it matters**: What goes wrong if this question isn't answered
- **What good looks like**: What a satisfactory answer would contain

## Suggested Discussion Order
Which questions should be addressed first? Why?

## Information Gaps
What information would you ideally want but don't have?
What assumptions will need to be made, and how risky are they?
</structured_output_contract>

<grounding_rules>
- Each question must be specific to this topic — no generic "what are the requirements?"
- Consider second-order questions: "if we decide X, what else must we decide?"
- If initial key questions already cover something well, say so — don't re-ask
</grounding_rules>
```

### Round 1 Prompt

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"

Current phase: {phase_name}
Phase objective: {phase_objective}

Key questions to address:
{key_questions_numbered_list}

{if phase > 1}
Context from prior phases:
The following core commitments have been established in earlier phases. Your analysis
must be consistent with these commitments. If you believe any commitment should be
reconsidered, you must explicitly argue why.

{core_commitments_for_this_phase}
{/if}

Produce a thorough, well-reasoned analysis and proposal for this phase.
</task>

{if codebase_context_available}
<codebase_context>
Your proposals MUST be compatible with this existing architecture.
{codebase_context_content}
</codebase_context>
{/if}

<structured_output_contract>
## Analysis
Key observations and reasoning. Every claim must be supported — do not assert without justification.

## Proposal
Concrete positions and recommendations for each key question. Numbered to match key questions.

## Evidence and Rationale
Supporting arguments for each position. Label assumptions explicitly: [Assumption: …]

## Trade-offs Acknowledged
What you are deliberately NOT optimizing for, and why that is acceptable.

## Open Questions
Items needing further discussion.
</structured_output_contract>

<completeness_contract>
You MUST address every key question. If you lack information, state your assumption and proceed.
</completeness_contract>

<grounding_rules>
- Ground every claim in reasoning or evidence
- Label assumptions: [Assumption: …]
- Distinguish "this is true" from "this is my recommendation"
</grounding_rules>
```

### Round N > 1 Prompt

```xml
<task>
You are the Proposer in a structured product debate, continuing Round {N}.

Topic: "{debate_topic}"
Current phase: {phase_name}
Phase objective: {phase_objective}

Key questions to address:
{key_questions_numbered_list}

## Previous Round Summary
{host_synthesized_round_summary}

## Reviewer's Objections from Previous Round
You must address EACH objection explicitly.

{reviewer_previous_round_output_verbatim}

{if phase > 1}
## Core Commitments from Prior Phases
{core_commitments_for_this_phase}
{/if}
</task>

<structured_output_contract>
## Response to Reviewer
For each objection, do ONE of:
- **Accept**: acknowledge validity, state how position changes
- **Rebut**: explain why objection is incorrect, with reasoning
- **Acknowledge as trade-off**: objection is valid but deliberately accepted — explain why

Do NOT ignore any objection.

## Revised Analysis
Updated analysis incorporating responses. Only include changed sections.

## Revised Proposal
Updated positions. Mark each: [UNCHANGED], [REVISED], or [NEW].

## Evidence and Rationale
Arguments for revised or new positions.

## Trade-offs Acknowledged
Updated trade-off list.

## Open Questions
Remaining items.
</structured_output_contract>
```

### Mediation Round Prompt (Round 5, when forced)

```xml
<task>
You are the Proposer in a structured product debate. This is the FINAL round.

Topic: "{debate_topic}"
Phase: {phase_name}

After {N-1} rounds, structural disagreements remain. You must work toward compromise.

## Unresolved Disagreements
{list_of_unresolved_structural_objections}

## Your Last Position
{summary_of_proposer_last_round}

## Reviewer's Last Position
{summary_of_reviewer_last_round}

For each unresolved disagreement, propose a COMPROMISE that:
1. Acknowledges the legitimate concern behind the Reviewer's objection
2. Preserves the core value of your original position
3. Finds a middle ground both sides can accept

If no compromise is possible, clearly state as OPEN ITEM for user escalation.
</task>

<structured_output_contract>
## Compromise Proposals
For each disagreement: the disagreement, proposed compromise, what each side gives up, why acceptable.

## Consolidated Position
Full proposal with each position marked [AGREED], [COMPROMISED], or [OPEN ITEM].

## Open Items for Escalation
Unresolved disagreements framed as clear questions for the user/stakeholder.
</structured_output_contract>
```

## Output Quality Checks

After receiving proposer output, the host checks:

1. **Length**: output < 200 words → likely insufficient quality, consider re-prompting
2. **Structure**: are all required section headings present?
3. **Coverage**: are all key questions addressed?
4. **Grounding**: are there unsubstantiated assertions or unlabeled assumptions?

For Probe Rounds, check instead: dimension coverage (not just functional), specificity (topic-specific, not generic), value explanation (why each question matters).

If checks fail, re-prompt with explicit gap description. Maximum 2 retries.

## Prompt File Management

Write all prompts to `phases/<phase>/prompts/` directory:
- `round-01-proposer-prompt.md`
- `round-02-proposer-prompt.md`
- `round-05-mediation-prompt.md`

Decomposition templates: see `proposer-decomposition.md`.

Keep prompt files for audit and debugging.
