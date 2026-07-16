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

echo "" >> "$RESULTS_FILE"
echo "==================================================" >> "$RESULTS_FILE"
echo "Summary: $PASSED passed, $FAILED failed, $SKIPPED skipped" >> "$RESULTS_FILE"

exit $FAILED
