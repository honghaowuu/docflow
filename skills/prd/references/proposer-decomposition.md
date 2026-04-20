# Proposer Decomposition Protocol

Proposer prompt templates for Module Decomposition: Decomposition Round, Per-Module Round, Integration Round.

Standard round templates: see `proposer-protocol.md`.

---

## Decomposition Round Prompt

Used when the host determines Module Decomposition is needed.

Write to `phases/<phase>/prompts/round-D-decomposition-prompt.md`, then dispatch:

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"
Current phase: {phase_name}
Phase objective: {phase_objective}

This phase involves multiple sub-modules that should be discussed individually
before integration. Your job is to DECOMPOSE this phase into sub-modules.

Context from prior phases:
{core_commitments_relevant}

{if probe_round_happened}
The enriched key questions for this phase:
{enriched_key_questions}
{/if}
</task>

{if codebase_context_available}
<codebase_context>
Consider aligning sub-modules with the existing code structure where it makes sense.
{codebase_context_content}
</codebase_context>
{/if}

<structured_output_contract>
## Module List
For each module:
- **Name**: Short, descriptive
- **Scope**: What this module covers (and explicitly what it does NOT cover)
- **Key questions**: 2-3 questions specific to this module
- **Dependencies**: Which other modules does this depend on or affect?

## Discussion Order
Order in which modules should be discussed, with reasoning. Modules others depend on first.

## Cross-Module Concerns
Issues spanning multiple modules for the Integration round:
- Data flow between modules
- Navigation/transition between modules
- Shared state or resources
- Consistency requirements
</structured_output_contract>

<grounding_rules>
- Each module must have a clear, non-overlapping scope boundary
- The union of all modules must cover the full phase objective
- Aim for 3-7 modules
- Cross-module concerns are identified here, not resolved
</grounding_rules>
```

---

## Per-Module Round Prompt

One round per sub-module.

Write to `phases/<phase>/prompts/module-NN-proposer-prompt.md`:

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"
Current phase: {phase_name}

You are now working on MODULE: "{module_name}"
Module scope: {module_scope}
Module key questions: {module_key_questions}

{if previous_modules_exist}
Previous modules discussed. Here are their conclusions (mini-consensus summaries):
{previous_modules_mini_consensuses}
{/if}

Core commitments from prior phases:
{core_commitments_relevant}
</task>

<structured_output_contract>
## Module Analysis
Key observations specific to this module's scope.

## Module Proposal
Concrete positions for each of this module's key questions.

## Interface Points
How this module connects to other modules:
- **Inputs**: What this module receives from other modules
- **Outputs**: What this module provides to other modules
- **Shared state**: Any state this module shares with others

## Evidence and Rationale
Supporting arguments for module-level positions.

## Open Questions
Items that may affect other modules or require Integration round resolution.
</structured_output_contract>

<grounding_rules>
- Stay within this module's declared scope
- Explicitly flag decisions that affect other modules
- Interface points must be concrete, not abstract
</grounding_rules>
```

---

## Integration Round Prompt

Used after all per-module rounds are complete.

```xml
<task>
You are the Proposer in a structured product debate.

Topic: "{debate_topic}"
Current phase: {phase_name}
Phase objective: {phase_objective}

All sub-modules have been discussed individually. You now need to INTEGRATE them
into a coherent whole-phase proposal.

## Module Conclusions (mini-consensus summaries)
{all_modules_mini_consensuses}

## Cross-Module Concerns (identified in Decomposition Round)
{cross_module_concerns}

{if integration_round > 1}
## Integration Reviewer Feedback from Prior Round
{reviewer_prior_integration_output_verbatim}
{/if}

## Core Commitments from Prior Phases
{core_commitments_relevant}
</task>

<structured_output_contract>
## Integration Analysis
How the modules fit together. Focus on cross-module issues, not re-litigating individual modules.

## Integrated Proposal
The full phase proposal incorporating all modules. Cross-module issues resolved.

## Cross-Module Resolutions
For each cross-module concern: how it is resolved in the integrated design.

## Consistency Check
Are all module interface points compatible? Any contradictions between modules?

## Trade-offs Acknowledged
What integration trade-offs were made and why.

## Open Items
Anything that could not be resolved at integration level.
</structured_output_contract>
```
