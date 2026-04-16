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

## Dynamic Questioning

Ask one question at a time. Never ask more than one question per message.

**Start by reading `docs/use-cases.md`** — extract nouns that appear as subjects or objects in main flows as candidate entities. Also read `docs/prd.md` for any domain terms introduced there.

**Opening question:**
> "I've identified these candidate entities from the use cases: [list of nouns]. Which of these are core domain concepts? Which are UI concerns (screens, forms, buttons) or infrastructure concerns (databases, queues, APIs) that should be excluded?"

**For each confirmed entity:**

1. > "What are the essential attributes of [entity]? Focus on what the domain logic actually depends on — not display fields or technical identifiers."

2. > "What rules must always be true about [entity]? For example: 'A [entity] must always have [field]', or '[entity] cannot be in states X and Y simultaneously.'"

**For relationships** (iterate through confirmed entity pairs that interact in use cases):
> "How does [entity A] relate to [entity B]? How many [A]s can one [B] have, and vice versa?"

**For the glossary:**
> "Are there any terms in this document that someone joining the team next week might misunderstand or interpret differently than you intend?"

**Coverage check before proceeding:**
- Every noun from use-case main flows is either included as an entity or explicitly excluded with a reason
- Every relationship has a cardinality
- Every entity has at least one invariant
- Every domain-specific term in the document appears in the glossary

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
