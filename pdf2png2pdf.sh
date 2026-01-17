#!/bin/bash
# (C) 2020 - 2023, 2025 - 2026 Benjamin Steenkamer
# Convert .pdf to .png and then back to .pdf.
# Try to  maintain good quality in the process (increase the density if results are not good enough).
# Useful for removing hyperlinks and searchable text in PDFs.
if [[ ! -f "$1" ]]; then
    echo "File not found: \"$1\""
    exit 1
fi

TEMP_DIR=$(mktemp -d)

# density = PNG dots-per-inch (DPI)
echo "Converting PDF to PNGs..."
convert -density 300 "$1" ${TEMP_DIR}/page.png

# Get PNG names by numeric order
echo "Converting PNGs to PDF..."
convert $(ls -1 ${TEMP_DIR}/*.png | sort -V) "${1%.pdf}-converted.pdf"

rm -rf ${TEMP_DIR}
echo "Done"
