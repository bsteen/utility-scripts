#!/bin/bash
# (C) 2023, 2025 - 2026 Benjamin Steenkamer
# Convert `.pdf` to a set of `.png`s
# Try to maintain good quality in the process (increase the density if results are not good enough)
if [[ ! -f "$1" ]]; then
    echo "File not found: \"$1\""
    exit 1
fi

convert -alpha remove -density 300 "$1" "${1%.pdf}.png"
