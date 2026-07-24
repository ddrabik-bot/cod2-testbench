#!/bin/bash
# slow_async.sh — script simulating a long-running execute_async operation
# It runs for about 10 seconds (timeout test).
set -euo pipefail

echo "Starting slow_async at $(date -u '+%H:%M:%S')"
sleep 10
echo "Finished slow_async at $(date -u '+%H:%M:%S')"