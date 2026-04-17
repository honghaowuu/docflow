---
name: docflow:domain-model
description: Use when the user wants to generate or regenerate the Domain Model document (domain-model.md) for a DocFlow project
---

# Generate Domain Model

**Announce at start:** "I'm using docflow:domain-model to generate the Domain Model document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify both `prd.md` and `use-cases.md` have `status: approved`.

If either is not approved:
> "Cannot generate domain-model.md — [missing doc] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|-------|-------------|------------|
| Entities | Core domain concepts | Not UI components, not infrastructure; every use-case noun must be accounted for |
| Attributes | Essential data fields per entity | Only what domain logic depends on — not persistence or display concerns |
| Invariants | Rules that must always hold for each entity | At least one invariant per entity |
| Relationships | How entities relate to each other | Every relationship must have cardinality (1:1, 1:N, M:N) |
| Glossary | Domain-specific terms | Every domain-specific term used in the document must appear here |

---

## Candidate-First Questioning

Read `docs/use-cases.md` and `docs/prd.md` before asking any question. Derive candidates from these documents throughout.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate entities from nouns in use-case main flows:**
> "I've identified these candidate entities from the use cases:
>
> 1. **[Core domain noun from main flows]** *(recommended — appears most frequently)*
> 2. **[Second domain noun]** *(recommended)*
> 3. **[Noun that may be a UI concern]**
> 4. **[Noun that may be infrastructure]**
> N. Other — add your own
>
> Which are core domain concepts to include? Which are UI/infrastructure concerns to exclude? An excluded entity needs a reason."

**For each confirmed entity — derive candidate attributes from use-case steps:**
> "For [entity], these attributes appear in the use case flows:
>
> 1. **[Attribute from use case step — field the domain logic depends on]** *(recommended)*
> 2. **[Second attribute]**
> 3. Other — describe your own
>
> Which attributes does the domain logic depend on? Exclude display fields and technical identifiers like database IDs."

**For each confirmed entity — derive candidate invariants from use-case preconditions and postconditions:**
> "Based on how [entity] is used in the use cases, these rules likely always hold:
>
> 1. **[Invariant derived from use-case precondition or postcondition]** *(recommended)*
> 2. **[Second invariant]**
> 3. Other — describe your own
>
> Which invariants are correct? At least one invariant is required per entity."

**For relationships — derive candidate cardinalities from how entities interact in use case flows:**
> "The use cases show [entity A] and [entity B] interacting. The relationship seems to be:
>
> 1. **One [A] has many [B]s** *(recommended — based on [use case step])*
> 2. One [A] has exactly one [B]
> 3. Many [A]s relate to many [B]s
> 4. Other — describe your own"

**For the glossary — derive candidates from domain-specific terms used in the document:**
> "These terms in the domain model may need clarification for a new team member:
>
> 1. **[Term A]** — suggested definition: [definition derived from use case context] *(recommended)*
> 2. **[Term B]** — suggested definition: [definition]
> 3. Other — add your own
>
> Which definitions are correct? Which terms are missing?"

**Coverage check before proceeding:**
- Every noun from use-case main flows is either included as an entity or explicitly excluded with a reason
- Every relationship has a cardinality
- Every entity has at least one invariant
- Every domain-specific term used in the document appears in the glossary

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "This entity is obvious, we don't need to define its attributes" | Undefined attributes become inconsistent implementations across the codebase. |
| "The relationship cardinality is obvious from context" | Unwritten cardinality becomes a source of data integrity bugs. Write it. |
| "We don't have any invariants for this entity" | Every entity has constraints. Probe: "Can a [entity] exist without a [field]?" or "Can [entity] ever be in [state] and [other state] at the same time?" |
| "The glossary is overkill for an internal document" | Domain terms mean different things to different people. A glossary prevents meetings about meanings. |

---

## Template

Use `templates/domain-model.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency
- `docs/use-cases.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
