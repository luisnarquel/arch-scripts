#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in "$SCRIPT_DIR"/*_*.sh; do
    if [ -f "$script" ]; then
        echo "Running: $(basename "$script")"
        bash "$script"
    fi
done

echo "All post-install scripts completed successfully."
