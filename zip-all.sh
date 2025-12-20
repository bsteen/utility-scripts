#!/bin/bash
# (C) 2025 Benjamin Steenkamer
# Zip uncompressed files in a directory into their own ZIPs
# Each file will be deleted after being successfully zipped
exit_script() {
    exit 130
}
trap 'exit_script' INT  # Captures ctrl+c to cleanly exit for-loop

if [[ -z "$1" || ! -d "$1" ]]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

IGNORE_ARCHIVES="(zip|rar|7z|gz|tgz|xz|bz2)$" # Don't compressed already compressed files

cd "$1"
for file in *; do
    if [[ -f "$file" ]]; then
        if [[ "$file" =~ $IGNORE_ARCHIVES ]]; then
            echo "Already compressed: '$file'"
            continue
        fi

        archive_name="${file%.*}.zip"   # Remove file name, append zip

        if [[ -f "$archive_name" ]]; then
            echo "ERROR, ARCHIVE ALREADY EXISTS: '$archive_name'"
            continue
        fi

        echo "Compressing '$file' to '$archive_name'"
        7z a "$archive_name" "$file" -tzip -mmt=on -mx=9 -sdel -y > /dev/null
    fi
done
