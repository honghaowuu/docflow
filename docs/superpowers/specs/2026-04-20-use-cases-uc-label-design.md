# Design: Inline Use Case Labels in Candidate-First Questioning

**Date:** 2026-04-20

## Problem

When the `docflow:use-cases` skill asks questions referencing a use case by ID (e.g., "UC7"), users must mentally look up which use case that ID refers to. This interrupts the questioning flow.

## Solution

Add one instruction at the top of the `Candidate-First Questioning` section in `skills/use-cases/SKILL.md`:

> **Use case references:** Whenever referencing a use case by ID, always include a one-sentence goal summary inline — e.g., `UC7 (User uploads a document to a project)` — so the user never needs to look it up.

## Scope

- **File changed:** `skills/use-cases/SKILL.md`
- **Location:** Top of `Candidate-First Questioning` section, before the opening question block
- **No other changes required**

## Success Criteria

Any question in the skill that references a use case ID also includes a parenthetical one-sentence goal summary.
