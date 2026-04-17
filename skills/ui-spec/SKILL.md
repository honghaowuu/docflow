---
name: docflow:ui-spec
description: Use when the user wants to generate or regenerate the UI Specification document (ui-spec.md) for a DocFlow project
---

# Generate UI Specification

**Announce at start:** "I'm using docflow:ui-spec to generate the UI Specification document."

---

## Dependency Check

Read `.docflow/status.yaml`. Verify both `prd.md` and `ux-flow.md` have `status: approved`.

If either is not approved, identify which document is missing and tell the user:
> "Cannot generate ui-spec.md — [name the specific missing document] must be approved first."

Stop here. Do not proceed with unapproved dependencies.

---

## Fast Mode

If the orchestrator indicated fast mode:
1. Read `docs/prd.md` and `docs/ux-flow.md` in full
2. Skip all intake questioning — pass dependency contents directly to `docflow:pipeline`
3. Jump to the Template section below

---

## Required Information

All of the following must be collected before calling docflow:pipeline:

| Field | Description | Validation |
|---|---|---|
| Screens | One screen per distinct UX state or step | Every UX flow transition must map to a screen or shared component |
| Components | UI elements on each screen | Each component must have: name, purpose, interaction behaviour |
| State variations | How each screen or component changes based on data or user state | At least one state variation per interactive component |
| Interaction patterns | User actions and system responses | Every component with user interaction must define the system response |

---

## Candidate-First Questioning

Read `docs/ux-flow.md` and `docs/prd.md` before asking any question.

Ask one question per message. Present each question as numbered options with one marked `*(recommended)*` and a final option `[N]. Other — describe your own`.

**Opening question — derive candidate screens from UX flow transitions:**
> "Based on the UX flow, I've identified these candidate screens — one per distinct state:
>
> 1. **[Screen derived from UX flow entry point or step]** *(recommended)*
> 2. **[Second screen]**
> 3. **[Error state screen]**
> N. Other — describe your own
>
> Which screens should be specified? You can select multiple or rename any."

**For each confirmed screen — derive candidate components from the UX flow description of that step:**
> "For the **[Screen Name]** screen, these components are likely needed based on the UX flow:
>
> 1. **[Component derived from UX flow action or state]** *(recommended — primary interaction)*
> 2. **[Secondary component]**
> 3. **[Navigation or feedback component]**
> N. Other — describe your own
>
> Which components appear on this screen? Include name, purpose, and interaction behaviour for each."

**For state variations — derive candidates from UX flow error states and common UI states:**
> "For the **[Component]** component, these states are likely based on the UX flow:
>
> 1. **Empty / initial state** *(recommended — always required)*
> 2. **Loading state** (if async data)
> 3. **Error state** (derived from UX flow error states)
> 4. **Populated / success state**
> N. Other — describe your own
>
> Which state variations apply?"

**For interaction patterns — derive from UX flow transitions that involve this component:**
> "When the user interacts with **[Component]**, the UX flow indicates:
>
> 1. **[Action] → [System response derived from UX transition]** *(recommended)*
> 2. **[Alternative interaction]**
> N. Other — describe your own"

**Coverage check before proceeding:**
- Every UX flow transition maps to a screen or shared component
- Every interactive component has at least one state variation
- Every interactive component has a defined interaction pattern and system response

---

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "The components are obvious from the screen name" | Undefined components become inconsistently implemented across the frontend. Name and specify each. |
| "We only need the happy-path states" | UX flow error states must map to UI components. Empty, loading, and error states prevent blank or broken screens. |
| "The interaction pattern is just a click" | Undefined system responses to clicks become undefined behaviour in implementation. Specify the response. |

---

## Template

Use `templates/ui-spec.md`.

Pass to docflow:pipeline:
- All intake answers mapped to template sections
- `docs/prd.md` content as dependency
- `docs/ux-flow.md` content as dependency

**REQUIRED SUB-SKILL:** `docflow:pipeline`
