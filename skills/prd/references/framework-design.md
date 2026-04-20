# Framework Design

How the host designs a custom debate framework for the user's topic.

## Design Principles

1. **Dependency chain first** — later phases must build on earlier phase conclusions. If a phase does not depend on prior conclusions, it may not belong in this framework.
2. **Each phase has a concrete output** — not "further discussion." The output must be something writable into `consensus.md`.
3. **Why → What → How** — clarify why, then what, before discussing how. Do not jump to solutions in Phase 1.
4. **4-7 phases** — fewer than 4 usually means critical layers are skipped; more than 7 is too granular and reduces efficiency.
5. **Each phase escalates** — each phase should be more specific or deeper than the previous on some dimension.

## Design Process

### Step 1: Classify the Topic

| Type | Characteristics | Typical entry |
|---|---|---|
| **Product Feature PRD** | User wants to build a new or improved feature | "Design a…", "I want to build…", "How should this feature work" |
| **Strategy Decision** | Choosing between multiple directions | "Should we use A or B", "technology selection", "strategic direction" |
| **Problem Diagnosis** | Known problems that need systematic analysis | "How to fix these 6 issues", "why are users churning" |
| **Process Design** | Designing workflows, pipelines, collaboration flows | "How to design the review process", "optimize the release flow" |
| **Product Positioning** | Clarifying core value and boundaries | "What exactly is this product", "how to differentiate from competitors" |

### Step 2: Select a Base Pattern

Choose one as a starting point, then tailor it to the specific topic.

#### Pattern A: Product Feature PRD

```
Phase 1: Problem Definition
  Objective: Clarify what problem to solve and for whom
  Key questions:
  - What is the core pain point? How can it be quantified?
  - Who are the target users? How many types? Priority order?
  - How are users currently solving this (workarounds)?
  - What are the success metrics?
  Completion criteria: Clear problem statement + user profile + success metrics

Phase 2: Ideal State
  Objective: Describe the ideal final state without constraints
  Key questions:
  - With no limitations, what would this feature ultimately look like?
  - What is the complete user journey? Key experience nodes?
  - What core capabilities are needed and how do they relate?
  - How does this relate to existing systems (standalone/embedded/replacement)?
  Completion criteria: Full ideal state + user journey + capability list

Phase 3: Gap Analysis
  Objective: Identify gaps between ideal state and current state
  Key questions:
  - What capabilities already exist vs. need to be built?
  - Which experiences are adequate vs. have gaps?
  - What data is needed and what is the data quality?
  - What operational support is needed post-launch?
  Completion criteria: Structured gap list with severity ratings

Phase 4: Solution Strategy
  Objective: Determine strategy and roadmap to close gaps
  Key questions:
  - What are the solution options and their trade-offs?
  - How many phases? What is each phase's core deliverable?
  - What is V1 scope? What must be included vs. deferred?
  - What are the key risks and how to mitigate them?
  Completion criteria: Phase strategy + V1 scope + risk list

Phase 5: Specification Detail
  Objective: Detailed requirements for V1 scope
  Key questions:
  - Detailed behavior for each feature?
  - Edge cases and error handling?
  - Interaction flows and state transitions?
  - Data model and interface constraints?
  Completion criteria: Requirements spec ready for engineering
```

#### Pattern B: Strategy Decision

```
Phase 1: Context Mapping — current state, constraints, stakeholders, timeline
Phase 2: Option Generation — enumerate 3-5 differentiated options
Phase 3: Multi-Dimensional Evaluation — build evaluation framework, score each option
Phase 4: Decision and Roadmap — choose, explain why, plan execution, mitigate risks
```

#### Pattern C: Problem Diagnosis

```
Phase 1: Problem Definition and Classification — group surface problems, build problem tree
Phase 2: Ideal State — positive description of the resolved state
Phase 3: Root Cause Analysis — find structural causes, map root cause → problem
Phase 4: Strategy Formulation — phased solutions with verification approach
```

#### Pattern D: Process Design

```
Phase 1: Current State Mapping — what does the current process look like
Phase 2: Pain Point Identification — bottlenecks, waste, risks
Phase 3: Process Redesign — what should the ideal process look like
Phase 4: Transition Planning — how to move from current to ideal
```

### Step 3: Tailor and Customize

The base pattern is a starting point only. Based on the specific topic:

- **Merge**: If two phases can naturally complete in one discussion, merge them
- **Split**: If a phase is too complex, split into two more focused phases
- **Add**: If the topic has special dimensions (compliance, multi-platform), add dedicated phases
- **Reorder**: If dependencies differ from the template, adjust phase order
- **Rewrite key questions**: Key questions must be specific to the topic, not generic

### Step 4: Validate the Framework

Before presenting to the user, self-check:

- [ ] Does each phase have a concrete output goal?
- [ ] Do phases form a clear dependency chain?
- [ ] Are key questions written specifically for this topic, not from a generic template?
- [ ] Are any two phases discussing the same thing?
- [ ] Does discussion depth increase from first to last phase?
- [ ] Is the count between 4 and 7?

## Presenting the Framework to the User

```
Debate Framework ({N} phases):

1. {Phase Name} — {one-sentence objective}
   Key questions: {2-3 core questions}

2. {Phase Name} — {one-sentence objective}
   Key questions: {2-3 core questions}

...

Estimated {N*2} to {N*4} rounds of discussion.

Shall we begin, or would you like to adjust the framework?
```

User may request: add/remove/merge phases, modify key questions, reorder phases, simplify or deepen overall.

After accepting adjustments, update `debate-framework.md` and proceed to Phase 4 (debate loop).
