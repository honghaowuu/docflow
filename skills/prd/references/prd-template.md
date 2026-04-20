# PRD Template (Product Feature Type)

This template applies to "Product Feature PRD" type debate outputs. For other types (Strategy Decision, Problem Diagnosis, Process Design), the agent organizes content based on the discussion.

```markdown
# {Product Name} Product Requirements Document

> Debate: "{debate_name}"
> Generated at: {ISO timestamp}
> Based on {total_phases} discussion phases, {total_rounds} debate rounds

## 1. Overview
{One paragraph: what this product is, what problem it solves, why now}

## 2. Target Users
{User profiles, priority order, current alternatives}

## 3. User Scenarios
{Core use cases, user journeys, key experience nodes}

## 4. Requirements
{Requirements organized by module/feature, with priority labels (P0/P1/P2)}

## 5. Interaction Design
{Page structure and navigation, core interaction flows, key state transitions, error and edge case handling}

## 6. Product Decision Log
{Key decisions made during discussion, chosen approaches and rationale, rejected alternatives}

## 7. Scope and Boundaries
- **In scope**: {explicitly included in this release}
- **Out of scope**: {explicitly excluded}
- **TBD**: {needs further confirmation}

## 8. Risks and Dependencies
{Identified product risks, external dependencies, prerequisites}

## 9. Open Items
{Topics that did not reach consensus, areas needing further research}

## 10. Success Criteria
{Measurable acceptance indicators}

---

> Technical implementation plans should be created separately based on this PRD.
```

## Usage Notes

- The host uses this structure to organize PRD content during the final synthesis phase
- Inputs: all `consensus.md` files + `core-commitments.md` + `debate-framework.md` + `intent-brief.md` + `codebase-context.md` (if exists)
- Sections may be trimmed based on actual discussion: if a section was not covered, mark as "Not covered in this discussion" rather than forcing content
- Product perspective only: no technical architecture, interface definitions, database design, or implementation schedules
