#!/bin/bash
# (C) 2020 Benjamin Steenkamer.
# Calculates the checksum/hashes of all the files in a folder and then
# generates a Markdown-style table of the results. The results are outputted
# into `output.md`.
# Usage:
# Create table from files in given directory (no directory means current one):
#   `./hashmd.sh path/to/dir` or `./hashmd.sh`
# Create table of files in given directory and all sub directories:
#   `./hashmd.sh -r path/to/dir` or `./hashmd.sh -r`
# TODO:
# Handle case where directory doesn't exist
# Specify output file name: -o "file_name"
# Specify file filter (only hash these files): -f "*.iso|*.bin"

output_name="output.md"
script_name="./$(basename $0)"
dir="."
recur=false

# Parse arguments
for arg in "$@"; do
	if [[ -d "$arg" ]]; then
		dir=$arg
	elif [ "$arg" = "-r" ]; then
        recur=true
	fi
done

# Create file list
if [ $recur = true ]; then
    # Find all files and directories recursively, sort case-insensitive
    files=$(find "$dir" | sort -f)
else
    # Find files and directories only in base directory, sort case-insensitive
    files=$(find "$dir" -maxdepth 1 | sort -f)
fi

> $output_name      # Create or truncate output file
printf "| File| Size (B) | CRC-32 | SHA-256 |\n" >> $output_name
printf "|---|:---:|---|---|\n" >> $output_name

while read file; do
    if [[ -f "$file" ]]; then         # If it is actually a file, hash it
        if [ "$file" = "$script_name" ]; then    # Don't hash this script file
            continue
        fi

        printf "Processing $file...\n"
        size=$(du -b "$file" | awk '{print $1}')
        crc=$(crc32 "$file")
        sha=$(sha256sum "$file" | awk '{print $1}')

        if [[ "$file" = "./"* ]]; then
            file=$(echo "$file" | cut -c 3-)    # Cut off the leading "./"
        fi

        printf "| $file | \`$size\` | \`$crc\`  | \`$sha\` |\n" >> $output_name
    fi
done <<< $files
printf "Done.\n"
