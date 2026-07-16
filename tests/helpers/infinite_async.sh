#!/bin/bash
# infinite_async.sh — skrypt symulujacy execute_async bez timeoutu
# Zapetla sie w nieskonczonosc — test timeout detection
set -euo pipefail

echo "Starting infinite_async at $(date -u '+%H:%M:%S')"
echo "This process will never finish on its own."
echo "Timeout should terminate it."

while true; do
    sleep 60
done