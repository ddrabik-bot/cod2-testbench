#!/bin/bash
# empty_arg_test.sh — test script for empty-argument handling
# It should fail when it receives empty arguments.
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "ERROR: No arguments provided"
    exit 1
fi

FIRST_ARG="${1:-}"
if [ -z "$FIRST_ARG" ]; then
    echo "ERROR: The first argument is empty"
    exit 2
fi

echo "OK: Argument: $FIRST_ARG"
exit 0