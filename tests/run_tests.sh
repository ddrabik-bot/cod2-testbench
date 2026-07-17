#!/bin/bash
# Run all tests and produce results/test_results.log + results/test_report.html
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/../results"
mkdir -p "$RESULTS_DIR"

RESULTS_FILE="$RESULTS_DIR/test_results.log"
echo "Test Results - $(date -u '+%Y-%m-%d %H:%M:%S UTC')" > "$RESULTS_FILE"
echo "==================================================" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

PASSED=0
FAILED=0
SKIPPED=0

# --- Test: Projekt istnieje i ma README ---
if [ -f "$SCRIPT_DIR/../README.md" ]; then
    echo "[PASS] Project README.md exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] Project README.md missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: Git branch structure ---
if git -C "$SCRIPT_DIR/.." rev-parse --git-dir > /dev/null 2>&1; then
    echo "[PASS] Git repository initialized" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] Git repository not found" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC test framework exists ---
if [ -f "$SCRIPT_DIR/../mods/_test.gsc" ]; then
    echo "[PASS] mods/_test.gsc exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] mods/_test.gsc missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC test cfg exists ---
if [ -f "$SCRIPT_DIR/../mods/test.cfg" ]; then
    echo "[PASS] mods/test.cfg exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] mods/test.cfg missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC framework has testRunner() ---
if grep -q "testRunner()" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc contains testRunner()" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing testRunner()" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC framework has assertEQ() ---
if grep -q "assertEQ(" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc contains assertEQ()" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing assertEQ()" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC framework writes test results ---
if grep -q "writeFile" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc uses writeFile() for results" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing writeFile()" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has bot tests (F3.2) ---
if [ -f "$SCRIPT_DIR/../mods/bot_test_setOriginAndAngles.gsc" ]; then
    echo "[PASS] mods/bot_test_setOriginAndAngles.gsc exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] mods/bot_test_setOriginAndAngles.gsc missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

if [ -f "$SCRIPT_DIR/../mods/bot_test_forceShot.gsc" ]; then
    echo "[PASS] mods/bot_test_forceShot.gsc exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] mods/bot_test_forceShot.gsc missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

if [ -f "$SCRIPT_DIR/../mods/bot_test_setWalkValues.gsc" ]; then
    echo "[PASS] mods/bot_test_setWalkValues.gsc exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] mods/bot_test_setWalkValues.gsc missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

if [ -f "$SCRIPT_DIR/../mods/bot_test_meleeWeapon.gsc" ]; then
    echo "[PASS] mods/bot_test_meleeWeapon.gsc exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] mods/bot_test_meleeWeapon.gsc missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC test.cfg loads bot test files ---
if grep -q "bot_test" "$SCRIPT_DIR/../mods/test.cfg" 2>/dev/null; then
    echo "[PASS] test.cfg loads bot test files" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] test.cfg missing bot test execs" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has math tests ---
if grep -q "1 + 1" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has basic math tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing math tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has string concatenation tests ---
if grep -q "strConcat\|Hello.*World\|level\.str" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has string concatenation tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing string concatenation tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has level.players tests ---
if grep -q "level\\.players" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has level.players tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing level.players tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: generate_html_report.sh exists ---
if [ -f "$SCRIPT_DIR/generate_html_report.sh" ]; then
    echo "[PASS] generate_html_report.sh exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] generate_html_report.sh missing" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has getCallStack() tests ---
if grep -q "getCallStack()" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has getCallStack() tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing getCallStack() tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has nested call stack tests ---
if grep -q "testNestedCallStack" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has nested call stack tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing nested call stack tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has isDefined() on different types tests ---
if grep -q "isDefined.*int.*1\|isDefined.*string.*1\|isDefined.*array.*1" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has isDefined() type tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing isDefined() type tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has logPrintConsole test ---
if grep -q "logPrintConsole.*test" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has logPrintConsole test" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing logPrintConsole test" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has printf/println/iprintln tests ---
if grep -q "printf\|println\|iprintln" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has printf/println/iprintln tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing printf/println/iprintln tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# MySQL Integration Tests (F3.1)
# ============================================================================
echo "" >> "$RESULTS_FILE"
echo "--- MySQL Integration Tests ---" >> "$RESULTS_FILE"

# Check if MySQL is reachable via pymysql
if python3 -c "import pymysql" 2>/dev/null; then
    echo "[*] Running MySQL integration tests..." >> "$RESULTS_FILE"
    python3 "$SCRIPT_DIR/mysql_test.py" 2>&1 | tee -a "$RESULTS_FILE"
    MYSQL_EXIT=${PIPESTATUS[0]}
else
    echo "[SKIP] MySQL tests - pymysql not installed. Install: pip install pymysql" >> "$RESULTS_FILE"
    MYSQL_EXIT=0
fi

# Propagate MySQL test failures to the overall count
if [ "$MYSQL_EXIT" -ne 0 ]; then
    FAILED=$((FAILED + MYSQL_EXIT))
fi

echo "" >> "$RESULTS_FILE"
echo "==================================================" >> "$RESULTS_FILE"
echo "Summary: $PASSED passed, $FAILED failed, $SKIPPED skipped" >> "$RESULTS_FILE"

# --- IWD file check (F1.6) ---
if [ -f "$SCRIPT_DIR/../main/iwd/mp_carentan.iwd" ]; then
    echo "" >> "$RESULTS_FILE"
    echo "[PASS] IWD file mp_carentan.iwd is present" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "" >> "$RESULTS_FILE"
    echo "[SKIP] IWD file mp_carentan.iwd not present — downloaded in CI via IWD_TOKEN" >> "$RESULTS_FILE"
    SKIPPED=$((SKIPPED + 1))
fi

# --- Run failure mode tests (F3.3) ---
echo "" >> "$RESULTS_FILE"
echo "==================================================" >> "$RESULTS_FILE"
echo "  Running F3.3 Failure Mode tests..." >> "$RESULTS_FILE"
echo "==================================================" >> "$RESULTS_FILE"

"$SCRIPT_DIR/failure_mode_tests.sh" >> "$RESULTS_FILE" 2>&1 || true

# --- Generowanie raportu HTML ---
if [ -f "$SCRIPT_DIR/generate_html_report.sh" ]; then
    bash "$SCRIPT_DIR/generate_html_report.sh" "$RESULTS_FILE"
fi

exit $FAILED