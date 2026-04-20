# Reviewer Decomposition Protocol

Reviewer prompt templates for Module Decomposition: Decomposition Round, Per-Module Round, Integration Round.

Standard round templates: see `reviewer-protocol.md`.

---

## Decomposition Round Review

Append after the reviewer role definition (from `reviewer-protocol.md`):

```
You are reviewing the Proposer's MODULE DECOMPOSITION.

Topic: "{debate_topic}"
Phase: {phase_name} | Objective: {phase_objective}

--- PROPOSER'S DECOMPOSITION ---
{proposer_decomposition_output_verbatim}
--- END ---

Review the DECOMPOSITION QUALITY, not individual module designs.

Focus on:
1. **Coverage**: Does the union of all modules cover the full phase objective? Any gaps?
2. **Boundaries**: Are module scope boundaries clear? Is there overlap?
3. **Granularity**: Too many (>7, too fine) or too few (<3, not enough separation)?
4. **Order**: Does the discussion order respect dependencies?
5. **Cross-module concerns**: Are the identified concerns complete?
6. **Missing modules**: Is there a capability that doesn't fit any listed module?

OUTPUT FORMAT:
## Missing Modules
## Boundary Issues (unclear or overlapping scope)
## Order Issues
## Missing Cross-Module Concerns
## Overall Assessment (Decomposition needs rework | needs adjustment | is solid)
```

---

## Per-Module Round Review

Use standard Round 1 reviewer prompt (from `reviewer-protocol.md`), adding at the end:

```
ADDITIONAL FOCUS for this module review:
- Does this module stay within its declared scope boundary?
- Are the interface points (inputs/outputs to other modules) concrete and well-defined?
- If a decision in this module affects other modules, is it clearly flagged?
- Are edge cases within this module's scope addressed?
```

---

## Integration Round Review

Append after the reviewer role definition:

```
You are reviewing the Integration Round — how all sub-modules fit together.

Topic: "{debate_topic}"
Phase: {phase_name}

Module summaries (what each module decided):
{modules_mini_consensuses_one_line_each}

--- PROPOSER'S INTEGRATION OUTPUT ---
{proposer_integration_output_verbatim}
--- END ---

{if integration_round > 1}
Your prior integration review:
{reviewer_prior_integration_output_verbatim}
{/if}

This is the most critical review — focus on the GAPS BETWEEN MODULES.

Review focus:
1. **Interface compatibility**: Are all module interface points (inputs/outputs) compatible with each other?
2. **Contradiction detection**: Do any two modules make incompatible decisions?
3. **Cross-module concern resolution**: Were all cross-module concerns from the Decomposition Round addressed?
4. **Consistency**: Does the integrated proposal feel like one coherent design or a patchwork?
5. **Missing integration**: Is there anything that spans modules but was left unaddressed?
6. **Scope integrity**: Does the integrated proposal still cover the full phase objective?

OUTPUT FORMAT (same as standard, but focus scoring on cross-module issues):
## Strengths
## Structural Objections (cross-module issues that block advancement)
## Clarification Needed
## Minor Issues
## Cross-Module Concern Status (for each concern from Decomposition Round: RESOLVED | PARTIAL | UNRESOLVED)
## Overall Assessment
```
