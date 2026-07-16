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

# --- Test: Dockerfile istnieje ---
if [ -f "$SCRIPT_DIR/../Dockerfile" ]; then
    echo "[PASS] Dockerfile exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[SKIP] Dockerfile - not yet created" >> "$RESULTS_FILE"
    SKIPPED=$((SKIPPED + 1))
fi

# --- Test: docker-compose.yml istnieje ---
if [ -f "$SCRIPT_DIR/../docker-compose.yml" ]; then
    echo "[PASS] docker-compose.yml exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[SKIP] docker-compose.yml - not yet created" >> "$RESULTS_FILE"
    SKIPPED=$((SKIPPED + 1))
fi

# --- Test: Makefile istnieje ---
if [ -f "$SCRIPT_DIR/../Makefile" ]; then
    echo "[PASS] Makefile exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[SKIP] Makefile - not yet created" >> "$RESULTS_FILE"
    SKIPPED=$((SKIPPED + 1))
fi

# --- Test: Git branch structure ---
if git -C "$SCRIPT_DIR/.." rev-parse --git-dir > /dev/null 2>&1; then
    echo "[PASS] Git repository initialized" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] Git repository not found" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

<<<<<<< HEAD
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

# --- Test: GSC has deep nested call stack tests ---
if grep -q "testDeepNestedCallStack\\|testNestedCallStackDeep" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has deep nested call stack tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing deep nested call stack tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has isDefined() on different types tests ---
if grep -q "isDefined.*int.*1\\|isDefined.*string.*1\\|isDefined.*array.*1" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has isDefined() type tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing isDefined() type tests" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has isDefined(undefined) test ---
if grep -q "isDefined.*undefined.*0\\|isDefined.*nonexistent" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has isDefined(undefined) test" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing isDefined(undefined) test" >> "$RESULTS_FILE"
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

# --- Test: GSC has CodeCallback_NotifyDebug test ---
if grep -q "CodeCallback_NotifyDebug" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has CodeCallback_NotifyDebug test" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing CodeCallback_NotifyDebug test" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: GSC has testRunnerVerbose() function ---
if grep -q "testRunnerVerbose" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has testRunnerVerbose() function" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing testRunnerVerbose() function" >> "$RESULTS_FILE"
=======
# --- Test: generate_html_report.sh istnieje ---
if [ -f "$SCRIPT_DIR/generate_html_report.sh" ]; then
    echo "[PASS] generate_html_report.sh exists" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] generate_html_report.sh missing" >> "$RESULTS_FILE"
>>>>>>> 04157d2 (feat: dodano generowanie kolorowego raportu HTML z wynikow testow (F3.4))
    FAILED=$((FAILED + 1))
fi

echo "" >> "$RESULTS_FILE"
echo "==================================================" >> "$RESULTS_FILE"
echo "Summary: $PASSED passed, $FAILED failed, $SKIPPED skipped" >> "$RESULTS_FILE"

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
