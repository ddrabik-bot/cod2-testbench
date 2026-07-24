#!/bin/bash
# ============================================================================
# generate_html_report.sh — Converts test_results.log to test_report.html
# ============================================================================
# Usage:  ./tests/generate_html_report.sh [results/test_results.log]
# Output:   results/test_report.html (or next to the source file)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."

# Determine the output and source files
if [ $# -ge 1 ]; then
    LOG_FILE="$1"
else
    LOG_FILE="$PROJECT_DIR/results/test_results.log"
fi

LOG_DIR="$(cd "$(dirname "$LOG_FILE")" && pwd)"
LOG_BASENAME="$(basename "$LOG_FILE" .log)"
HTML_FILE="${LOG_DIR}/${LOG_BASENAME}.html"

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log file not found: $LOG_FILE" >&2
    exit 1
fi

# --- Parse the log file ---
# Note: grep -c writes "0" to stdout and exits with code 1 when no matches exist.
# Use "|| :" instead of "|| echo 0" to avoid duplicating zero.
TIMESTAMP=$(head -1 "$LOG_FILE" 2>/dev/null || echo "Unknown")
PASSED=$(grep -c '\[PASS\]' "$LOG_FILE" 2>/dev/null || :)
FAILED=$(grep -c '\[FAIL\]' "$LOG_FILE" 2>/dev/null || :)
SKIPPED=$(grep -c '\[SKIP\]' "$LOG_FILE" 2>/dev/null || :)
TOTAL=$((PASSED + FAILED + SKIPPED))

# Determine whether the result is PASS or FAIL
if grep -qi "RESULT: PASS" "$LOG_FILE" 2>/dev/null; then
    RESULT="PASS"
    RESULT_CLASS="pass"
elif grep -qi "RESULT: FAIL" "$LOG_FILE" 2>/dev/null; then
    RESULT="FAIL"
    RESULT_CLASS="fail"
else
    if [ "$FAILED" -gt 0 ]; then
        RESULT="FAIL"
        RESULT_CLASS="fail"
    else
        RESULT="PASS"
        RESULT_CLASS="pass"
    fi
fi

NOW=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

# --- Generate HTML ---
html_header() {
    local html_file="$1" timestamp="$2" passed="$3" failed="$4"
    local skipped="$5" total="$6" result="$7" result_class="$8"
    cat > "$html_file" << HEADER_END
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Test Report - CoD2 Testbench</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #1a1a2e; color: #e0e0e0; margin: 0; padding: 20px; }
  .container { max-width: 800px; margin: 0 auto; background: #16213e; border-radius: 12px; padding: 24px; box-shadow: 0 4px 20px rgba(0,0,0,0.4); }
  h1 { color: #0f3460; border-bottom: 3px solid #e94560; padding-bottom: 10px; font-size: 24px; }
  .summary { display: flex; gap: 16px; margin: 20px 0; flex-wrap: wrap; }
  .summary-card { flex: 1; min-width: 120px; padding: 16px; border-radius: 8px; text-align: center; font-size: 18px; font-weight: bold; }
  .card-pass { background: #1b4332; border: 2px solid #2d6a4f; color: #95d5b2; }
  .card-fail { background: #4a0e0e; border: 2px solid #e94560; color: #ff6b6b; }
  .card-skip { background: #3d3520; border: 2px solid #b8860b; color: #ffd700; }
  .card-total { background: #1a1a2e; border: 2px solid #0f3460; color: #a8d8ea; }
  .card-result { background: #0f3460; border: 2px solid #e94560; color: #e0e0e0; }
  .card-result.pass { background: #1b4332; border-color: #2d6a4f; color: #95d5b2; }
  .card-result.fail { background: #4a0e0e; border-color: #e94560; color: #ff6b6b; }
  .card-count { font-size: 36px; display: block; margin-top: 4px; }
  table { width: 100%; border-collapse: collapse; margin-top: 16px; }
  th { background: #0f3460; color: #a8d8ea; padding: 10px 12px; text-align: left; font-weight: 600; }
  td { padding: 10px 12px; border-bottom: 1px solid #1a1a2e; font-size: 14px; font-family: 'Consolas', 'Courier New', monospace; }
  tr:hover { background: #1a1a4e; }
  .badge { display: inline-block; padding: 3px 10px; border-radius: 4px; font-weight: bold; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }
  .badge-pass { background: #2d6a4f; color: #d8f3dc; }
  .badge-fail { background: #e94560; color: #fff; }
  .badge-skip { background: #b8860b; color: #fff; }
  .timestamp { color: #6c757d; font-size: 13px; margin-top: 8px; }
  .footer { margin-top: 24px; padding-top: 16px; border-top: 1px solid #1a1a2e; font-size: 12px; color: #6c757d; text-align: center; }
</style>
</head>
<body>
<div class="container">
  <h1>Test Report - CoD2 Testbench</h1>
  <div class="timestamp">Time: ${timestamp}</div>
  <div class="summary">
    <div class="summary-card card-total">Total<span class="card-count">${total}</span></div>
    <div class="summary-card card-pass">PASSED<span class="card-count">${passed}</span></div>
    <div class="summary-card card-fail">FAILED<span class="card-count">${failed}</span></div>
    <div class="summary-card card-skip">SKIPPED<span class="card-count">${skipped}</span></div>
    <div class="summary-card card-result ${result_class}">RESULT<span class="card-count">${result}</span></div>
  </div>
  <h2>Test details</h2>
  <table>
    <thead>
      <tr><th>Status</th><th>Entry</th></tr>
    </thead>
    <tbody>
HEADER_END
}

html_footer() {
    local html_file="$1" log_file="$2"
    cat >> "$html_file" << FOOTER_END
    </tbody>
  </table>
  <h2>Raw logs</h2>
  <pre style="background:#0d1117; color:#c9d1d9; padding:12px; border-radius:6px; font-size:12px; overflow-x:auto; max-height:300px;">
FOOTER_END
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$log_file" >> "$html_file"
    cat >> "$html_file" << FOOTER_END_END
  </pre>
  <div class="footer">
    Generated by CoD2 Testbench - generate_html_report.sh<br>
    Source: $(basename "$log_file")
  </div>
</div>
</body>
</html>
FOOTER_END_END
}

# --- Create the HTML file ---
html_header "$HTML_FILE" "$NOW" "$PASSED" "$FAILED" "$SKIPPED" "$TOTAL" "$RESULT" "$RESULT_CLASS"

# Parse each line and add it to the table
while IFS= read -r line; do
    case "$line" in
        "[PASS]"*)
            test_name="${line#\[PASS\] }"
            echo "      <tr><td><span class=\"badge badge-pass\">PASS</span></td><td>${test_name}</td></tr>" >> "$HTML_FILE"
            ;;
        "[FAIL]"*)
            test_name="${line#\[FAIL\] }"
            echo "      <tr><td><span class=\"badge badge-fail\">FAIL</span></td><td>${test_name}</td></tr>" >> "$HTML_FILE"
            ;;
        "[SKIP]"*)
            test_name="${line#\[SKIP\] }"
            echo "      <tr><td><span class=\"badge badge-skip\">SKIP</span></td><td>${test_name}</td></tr>" >> "$HTML_FILE"
            ;;
    esac
done < "$LOG_FILE"

html_footer "$HTML_FILE" "$LOG_FILE"

echo "HTML report generated: $HTML_FILE"
echo "  Total: ${TOTAL}, Passed: ${PASSED}, Failed: ${FAILED}, Skipped: ${SKIPPED}, Result: ${RESULT}"