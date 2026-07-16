#!/bin/bash
# empty_arg_test.sh — skrypt testowy do testowania obslugi pustych argumentow
# Powinien zakonczyc sie bledem gdy otrzyma puste argumenty
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "ERROR: Nie podano argumentow"
    exit 1
fi

FIRST_ARG="${1:-}"
if [ -z "$FIRST_ARG" ]; then
    echo "ERROR: Pierwszy argument jest pusty"
    exit 2
fi

echo "OK: Argument: $FIRST_ARG"
exit 0