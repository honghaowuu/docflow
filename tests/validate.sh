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
check_file "package.json"
check_file "hooks/hooks.json"
check_file "hooks/session-start"
check_file "skills/start/SKILL.md"
check_file "skills/pipeline/SKILL.md"
check_file "skills/prd/SKILL.md"
check_file "skills/use-cases/SKILL.md"
check_file "skills/domain-model/SKILL.md"
check_file "templates/prd.md"
check_file "templates/use-cases.md"
check_file "templates/domain-model.md"

echo ""
echo "--- Skill Frontmatter (CSO descriptions) ---"
for skill in start pipeline prd use-cases domain-model; do
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
check_contains "skills/start/SKILL.md" \
    "NO DOCUMENT GENERATION WITHOUT ALL DEPENDENCIES APPROVED" \
    "start: dependency Iron Law"

echo ""
echo "--- REQUIRED SUB-SKILL Handoffs ---"
check_contains "skills/prd/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "prd: hands off to pipeline"
check_contains "skills/use-cases/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "use-cases: hands off to pipeline"
check_contains "skills/domain-model/SKILL.md" "REQUIRED SUB-SKILL.*docflow:pipeline" \
    "domain-model: hands off to pipeline"

echo ""
echo "--- Templates ---"
check_contains "templates/prd.md" "<!-- AI Generated -->" "prd template: AI Generated markers"
check_contains "templates/prd.md" "<!-- Human Review Required -->" "prd template: Human Review Required markers"
check_contains "templates/use-cases.md" "<!-- AI Generated -->" "use-cases template: AI Generated markers"
check_contains "templates/use-cases.md" "<!-- Human Review Required -->" "use-cases template: Human Review Required markers"
check_contains "templates/domain-model.md" "<!-- AI Generated -->" "domain-model template: AI Generated markers"
check_contains "templates/domain-model.md" "<!-- Human Review Required -->" "domain-model template: Human Review Required markers"

echo ""
echo "--- Hook ---"
check_executable "hooks/session-start"
check_contains "hooks/hooks.json" "SessionStart" "hooks.json: has SessionStart event"
check_contains "hooks/hooks.json" "session-start" "hooks.json: references session-start script"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
