#!/bin/bash
# Run all tests and produce results/test_results.log
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
if grep -q "level\.players" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has level.players tests" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing level.players tests" >> "$RESULTS_FILE"
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

exit $FAILED
