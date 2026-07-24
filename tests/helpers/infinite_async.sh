#!/bin/bash
# infinite_async.sh — script simulating execute_async without a timeout
# It loops indefinitely to test timeout detection.
set -euo pipefail

echo "Starting infinite_async at $(date -u '+%H:%M:%S')"
echo "This process will never finish on its own."
echo "Timeout should terminate it."

while true; do
    sleep 60
done