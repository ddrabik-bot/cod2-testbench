#!/bin/bash
# slow_async.sh — skrypt symulujacy dlugotrwale execute_async
# Dziala przez ok. 10 sekund (test timeoutu)
set -euo pipefail

echo "Starting slow_async at $(date -u '+%H:%M:%S')"
sleep 10
echo "Finished slow_async at $(date -u '+%H:%M:%S')"