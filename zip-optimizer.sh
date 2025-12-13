#!/bin/bash
# (C) 2025 Benjamin Steenkamer
# Recompress all the ZIP archives provided using the highest compression level
# Replaces the original ZIP archive if space is saved
# Prints the space saved per file and the total space saved at the end
# Usage: ./zip-optimizer <directory or ZIP> <directory or ZIP> ...

find_zip_files() {
    if [ -d "$1" ]; then
        find "$1" -maxdepth 1 -name "*.zip"
    elif [[ "$1" == *.zip ]]; then
        echo "$1"
    fi
}

process_arguments() {
    declare -A seen_files   # Create a dictionary
    local zip_files=""

    for arg in "$@"; do
        local resolved_path=$(realpath "$arg")

        # Check if path exists
        if [ ! -e "$resolved_path" ]; then
            # Write to stderr so it's separate from the file paths returned
            echo "Directory or file not found: $resolved_path" >&2
            continue
        fi

        local found_files=$(find_zip_files "$resolved_path") # Depending on the user args, may return duplicate files

        if [ -z "$found_files" ]; then
            echo "No ZIP archive(s) found: $resolved_path" >&2
            continue
        fi

        # Record each ZIP filepath that has been seen
        # If a filepath has already been added to zip_files, don't add it again
        # This prevents recompressing the same file if a duplicate path is found
        while IFS= read -r zip_file; do
            if [ -z "${seen_files[$zip_file]}" ]; then
                seen_files[$zip_file]=1     # Mark filepath as seen
                zip_files+="$zip_file"$'\n' # Add unique filepath, appending with a literal new line character
            fi
        done <<< "$found_files"
    done

    echo "$zip_files" | sed -z "s/\n$//" | sort   # Return the unique ZIP file paths, sorted, and final newline of the list removed
}

ZIP_FILES=$(process_arguments "$@")

if [ -z "$ZIP_FILES" ]; then    # No ZIPs found
    exit 1
fi

FILE_COUNT=$(echo "$ZIP_FILES" | wc -l)
FILE_COUNT_WIDTH=${#FILE_COUNT}
INDENT_WIDTH=$(( FILE_COUNT_WIDTH * 2 + 1 ))
echo "Optimizing $FILE_COUNT ZIP archives..."

TEMP_DIR=$(mktemp -d)

count=1
total_saved_bytes=0
# FIXME ctrl-c not handled properly when in loop
while IFS= read -r zip_file; do
    printf "%0${FILE_COUNT_WIDTH}d/${FILE_COUNT} Processing ${zip_file}\n" "$count"

    old_size_bytes=$(stat -c %s "$zip_file")
    7z x "$zip_file" -y -o"$TEMP_DIR" > /dev/null

    file_basename=$(basename "$zip_file")
    new_zip_file="$TEMP_DIR/$file_basename"
    7z a -tzip -mx=9 -mmt=on "$new_zip_file" "$TEMP_DIR/*" > /dev/null

    new_size_bytes=$(stat -c %s "$new_zip_file")

    if [ "$new_size_bytes" -lt "$old_size_bytes" ]; then
        bytes_saved=$(( old_size_bytes - new_size_bytes ))
        human_saved=$(numfmt --to=iec-i --suffix=B --format='%.1f' $bytes_saved)
        printf "%${INDENT_WIDTH}s Saved ${human_saved} (${bytes_saved})\n"
        mv -f "$new_zip_file" "$zip_file"
        total_saved_bytes=$(( total_saved_bytes + bytes_saved ))
    fi

    rm -rf "$TEMP_DIR"/*
    count=$(( count + 1 ))
done <<< "$ZIP_FILES"

rm -rf "$TEMP_DIR"

total_saved_human=$(numfmt --to=iec-i --suffix=B --format='%.1f' $total_saved_bytes)
echo "Total space saved: $total_saved_human ($total_saved_bytes)"
