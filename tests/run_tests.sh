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

# --- Test: _test.gsc has getBot() helper ---
if grep -q "getBot()" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has getBot()" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing getBot()" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: _test.gsc has getPlayer() helper ---
if grep -q "getPlayer()" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc has getPlayer()" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing getPlayer()" >> "$RESULTS_FILE"
    FAILED=$((FAILED + 1))
fi

# --- Test: _test.gsc calls bot test functions ---
if grep -q "botTestSetOriginAndAngles\|botTestForceShot\|botTestSetWalkValues\|botTestMeleeWeapon" "$SCRIPT_DIR/../mods/_test.gsc" 2>/dev/null; then
    echo "[PASS] _test.gsc calls bot test functions" >> "$RESULTS_FILE"
    PASSED=$((PASSED + 1))
else
    echo "[FAIL] _test.gsc missing bot test function calls" >> "$RESULTS_FILE"
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
