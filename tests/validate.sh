#!/usr/bin/env bash
# Structural validation for the DocFlow plugin.
# Run from the plugin root directory.

set -euo pipefail
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

check_file() {
    [ -f "$PLUGIN_ROOT/$1" ] && pass "$1 exists" || fail "$1 missing"
}

check_contains() {
    local file="$PLUGIN_ROOT/$1"
    local pattern="$2"
    local label="$3"
    grep -q "$pattern" "$file" 2>/dev/null && pass "$label" || fail "$label"
}

check_executable() {
    [ -x "$PLUGIN_ROOT/$1" ] && pass "$1 is executable" || fail "$1 not executable"
}

echo "=== DocFlow Plugin Validation ==="
echo ""

echo "--- Structure ---"
check_file "hooks/hooks.json"
check_file "hooks/session-start"
check_file "hooks/start-context.md"
check_file "skills/start/SKILL.md"
check_file "skills/pipeline/SKILL.md"
check_file "skills/prd/SKILL.md"
for ref in intent-clarification framework-design backtracking-algorithm context-management phase-progression proposer-protocol reviewer-protocol session-recovery prd-template proposer-decomposition reviewer-decomposition; do
    check_file "skills/prd/references/$ref.md"
done
check_file "skills/use-cases/SKILL.md"
check_file "skills/domain-model/SKILL.md"
check_file "skills/ux-flow/SKILL.md"
check_file "skills/ui-spec/SKILL.md"
check_file "skills/api-spec/SKILL.md"
check_file "skills/api-implement-logic/SKILL.md"
check_file "skills/test-spec/SKILL.md"
check_file "skills/repair/SKILL.md"
check_file "skills/generate-all/SKILL.md"
check_file "templates/prd.md"
check_file "templates/use-cases.md"
check_file "templates/domain-model.md"
check_file "templates/ux-flow.md"
check_file "templates/ui-spec.md"
check_file "templates/api-spec.yaml"
check_file "templates/api-implement-logic.md"
check_file "templates/test-spec.md"

echo ""
echo "--- Skill Frontmatter (CSO descriptions) ---"
for skill in start pipeline prd use-cases domain-model ux-flow ui-spec api-spec api-implement-logic test-spec repair generate-all; do
    check_contains "skills/$skill/SKILL.md" "^name:" "$skill: has name frontmatter"
    check_contains "skills/$skill/SKILL.md" "description: Use when" "$skill: description starts with 'Use when'"
done

echo ""
echo "--- Iron Laws ---"
check_contains "skills/pipeline/SKILL.md" \
    "NO DOCUMENT WRITTEN TO DISK WITH UNFILLED TEMPLATE SECTIONS" \
    "pipeline: unfilled-section Iron Law"
check_contains "skills/pipeline/SKILL.md" \
    "NO DOCUMENT WRITTEN TO DISK WITHOUT ALL THREE ANNOTATION TYPES" \
    "pipeline: annotation Iron Law"
check_contains "skills/pipeline/SKILL.md" \
    "NO CLEAN DOCUMENT COMMITTED WITHOUT HUMAN APPROVAL" \
    "pipeline: approval Iron Law"
check_contains "hooks/start-context.md" \
    "NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED" \
    "start-context: dependency Iron Law"

echo ""
echo "--- Candidate-First Pattern ---"
check_contains "skills/prd/SKILL.md" "debate-state" "prd: has debate state management"
check_contains "skills/prd/SKILL.md" "commitments.md" "prd: extracts commitments"
check_contains "skills/prd/SKILL.md" "model.*opus\|opus.*model" "prd: dispatches opus proposer"
check_contains "skills/use-cases/SKILL.md" "\*(recommended)\*" "use-cases: has candidate-first recommendations"
check_contains "skills/domain-model/SKILL.md" "\*(recommended)\*" "domain-model: has candidate-first recommendations"
check_contains "skills/ux-flow/SKILL.md" "\*(recommended)\*" "ux-flow: has candidate-first recommendations"
check_contains "skills/ui-spec/SKILL.md" "\*(recommended)\*" "ui-spec: has candidate-first recommendations"
check_contains "skills/api-spec/SKILL.md" "\*(recommended)\*" "api-spec: has candidate-first recommendations"
check_contains "skills/api-implement-logic/SKILL.md" "\*(recommended)\*" "api-implement-logic: has candidate-first recommendations"
check_contains "skills/test-spec/SKILL.md" "\*(recommended)\*" "test-spec: has candidate-first recommendations"

echo ""
echo "--- REQUIRED SUB-SKILL Handoffs ---"
check_contains "skills/prd/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "prd: hands off to pipeline"
check_contains "skills/use-cases/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "use-cases: hands off to pipeline"
check_contains "skills/domain-model/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "domain-model: hands off to pipeline"
check_contains "skills/ux-flow/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "ux-flow: hands off to pipeline"
check_contains "skills/ui-spec/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "ui-spec: hands off to pipeline"
check_contains "skills/api-spec/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "api-spec: hands off to pipeline"
check_contains "skills/api-implement-logic/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "api-implement-logic: hands off to pipeline"
check_contains "skills/test-spec/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "test-spec: hands off to pipeline"
check_contains "skills/repair/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "repair: hands off to pipeline"
check_contains "skills/generate-all/SKILL.md" "REQUIRED SUB-SKILL.*docflow:use-cases" \
    "generate-all: hands off to use-cases"

echo ""
echo "--- Orchestrator Routing ---"
check_contains "hooks/start-context.md" "docflow:ux-flow" "start: routes to ux-flow"
check_contains "hooks/start-context.md" "docflow:ui-spec" "start: routes to ui-spec"
check_contains "hooks/start-context.md" "docflow:api-spec" "start: routes to api-spec"
check_contains "hooks/start-context.md" "docflow:api-implement-logic" "start: routes to api-implement-logic"
check_contains "hooks/start-context.md" "docflow:test-spec" "start: routes to test-spec"
check_contains "hooks/start-context.md" "docflow:prd" "start: routes to prd"
check_contains "hooks/start-context.md" "docflow:use-cases" "start: routes to use-cases"
check_contains "hooks/start-context.md" "docflow:domain-model" "start: routes to domain-model"
check_contains "hooks/start-context.md" "fast mode" "start: mentions fast mode"
check_contains "hooks/start-context.md" "docflow:repair" "start: routes to repair"
check_contains "hooks/start-context.md" "docflow:generate-all" "start: routes to generate-all"

echo ""
echo "--- Templates ---"
check_contains "templates/prd.md" "<!-- AI Generated -->" "prd template: AI Generated markers"
check_contains "templates/prd.md" "<!-- Human Review Required -->" "prd template: Human Review Required markers"
check_contains "templates/use-cases.md" "<!-- AI Generated -->" "use-cases template: AI Generated markers"
check_contains "templates/use-cases.md" "<!-- Human Review Required -->" "use-cases template: Human Review Required markers"
check_contains "templates/domain-model.md" "<!-- AI Generated -->" "domain-model template: AI Generated markers"
check_contains "templates/domain-model.md" "<!-- Human Review Required -->" "domain-model template: Human Review Required markers"
check_contains "templates/ux-flow.md" "<!-- AI Generated -->" "ux-flow template: AI Generated markers"
check_contains "templates/ux-flow.md" "<!-- Human Review Required -->" "ux-flow template: Human Review Required markers"
check_contains "templates/ui-spec.md" "<!-- AI Generated -->" "ui-spec template: AI Generated markers"
check_contains "templates/ui-spec.md" "<!-- Human Review Required -->" "ui-spec template: Human Review Required markers"
check_contains "templates/api-spec.yaml" "# AI Generated" "api-spec template: AI Generated markers"
check_contains "templates/api-spec.yaml" "# Human Review Required" "api-spec template: Human Review Required markers"
check_contains "templates/api-implement-logic.md" "<!-- AI Generated -->" "api-implement-logic template: AI Generated markers"
check_contains "templates/api-implement-logic.md" "<!-- Human Review Required -->" "api-implement-logic template: Human Review Required markers"
check_contains "templates/test-spec.md" "<!-- AI Generated -->" "test-spec template: AI Generated markers"
check_contains "templates/test-spec.md" "<!-- Human Review Required -->" "test-spec template: Human Review Required markers"

echo ""
echo "--- Status File Consistency ---"
STATUS_FILE="$PLUGIN_ROOT/.docflow/status.yaml"
if [ -f "$STATUS_FILE" ]; then
    # Check all 8 documents are listed
    DOC_COUNT=0
    for d in prd.md use-cases.md ux-flow.md domain-model.md ui-spec.md api-spec.yaml api-implement-logic.md test-spec.md; do
        grep -q "  $d:" "$STATUS_FILE" 2>/dev/null && DOC_COUNT=$((DOC_COUNT+1))
    done
    [ "$DOC_COUNT" -eq 8 ] \
        && pass "status.yaml: all 8 documents listed" \
        || fail "status.yaml: missing entries — re-run 'init docflow' to upgrade (found $DOC_COUNT/8)"

    # Check approved/draft/outdated docs have files on disk
    for doc in prd.md use-cases.md ux-flow.md domain-model.md ui-spec.md api-spec.yaml api-implement-logic.md test-spec.md; do
        doc_status=$(grep -A2 "  $doc:" "$STATUS_FILE" 2>/dev/null | grep "status:" | awk '{print $2}')
        case "$doc_status" in
            approved|draft|outdated)
                [ -f "$PLUGIN_ROOT/docs/$doc" ] \
                    && pass "status.yaml: $doc ($doc_status) has file on disk" \
                    || fail "status.yaml: $doc is $doc_status but docs/$doc not found"
                ;;
            missing)
                [ -f "$PLUGIN_ROOT/docs/$doc" ] \
                    && echo "  WARN: docs/$doc exists but status.yaml lists it as missing"
                ;;
        esac
    done
else
    echo "  (skipping — .docflow/status.yaml not found)"
fi

echo ""
echo "--- Dependency Order Integrity ---"
if [ -f "$STATUS_FILE" ]; then
    # Helper: get status of a doc from status.yaml
    get_status() {
        grep -A2 "  $1:" "$STATUS_FILE" 2>/dev/null | grep "status:" | awk '{print $2}'
    }

    # check_dep DOC DEP: if DOC is approved, DEP must also be approved
    check_dep() {
        local doc="$1" dep="$2"
        local doc_st dep_st
        doc_st=$(get_status "$doc")
        dep_st=$(get_status "$dep")
        if [ "$doc_st" = "approved" ]; then
            [ "$dep_st" = "approved" ] \
                && pass "dep integrity: $doc approved and $dep approved" \
                || fail "dep integrity: $doc is approved but $dep is ${dep_st:-missing} — dependency chain is broken"
        fi
    }

    check_dep "use-cases.md"           "prd.md"
    check_dep "ux-flow.md"             "prd.md"
    check_dep "ux-flow.md"             "use-cases.md"
    check_dep "domain-model.md"        "prd.md"
    check_dep "domain-model.md"        "use-cases.md"
    check_dep "ui-spec.md"             "prd.md"
    check_dep "ui-spec.md"             "ux-flow.md"
    check_dep "api-spec.yaml"          "use-cases.md"
    check_dep "api-spec.yaml"          "domain-model.md"
    check_dep "api-spec.yaml"          "ux-flow.md"
    check_dep "api-implement-logic.md" "use-cases.md"
    check_dep "api-implement-logic.md" "api-spec.yaml"
    check_dep "api-implement-logic.md" "domain-model.md"
    check_dep "test-spec.md"           "use-cases.md"
    check_dep "test-spec.md"           "api-spec.yaml"
    check_dep "test-spec.md"           "domain-model.md"
else
    echo "  (skipping — .docflow/status.yaml not found)"
fi

echo ""
echo "--- Hook ---"
check_executable "hooks/session-start"
check_contains "settings.json" "SessionStart" "settings.json: has SessionStart hook registered"
check_contains "settings.json" "CLAUDE_PLUGIN_ROOT" "settings.json: hook uses \${CLAUDE_PLUGIN_ROOT}"
check_contains "settings.json" "session-start" "settings.json: hook references session-start script"

echo ""
echo "--- Consistency Check Gate ---"
for skill in use-cases ux-flow domain-model ui-spec api-spec api-implement-logic test-spec; do
    check_contains "skills/$skill/SKILL.md" "commitments.md" "$skill: has consistency check"
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
