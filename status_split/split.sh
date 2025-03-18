#!/bin/bash
# Script: split_by_status.sh
# Description:
#   Processes one or more input files (each containing HTTP probe output lines) by:
#   1. Stripping ANSI color codes.
#   2. Extracting a three-digit HTTP status code if it appears between square brackets.
#   3. Appending the line to "status_<code>.txt" (or to status_unknown.txt if no code is found).
#
# Usage:
#   ./split_by_status.sh <input_file1> [<input_file2> ...]
#
# Example:
#   ./split_by_status.sh results1.txt results2.txt

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input_file1> [<input_file2> ...]"
    exit 1
fi

# Loop over all input files.
for input_file in "$@"; do
    if [ ! -f "$input_file" ]; then
        echo "Error: File '$input_file' not found. Skipping."
        continue
    fi

    echo "Processing file: $input_file"
    
    while IFS= read -r line; do
        # First, strip ANSI escape sequences (color codes).
        clean_line=$(echo "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')
        
        # Extract a 3-digit status code if it's enclosed in square brackets, e.g., [200]
        status=$(echo "$clean_line" | grep -oE '\[[0-9]{3}\]' | head -n 1)
        
        if [ -n "$status" ]; then
            # Remove the square brackets
            status=$(echo "$status" | tr -d '[]')
            outfile="status_${status}.txt"
        else
            outfile="status_unknown.txt"
        fi

        echo "$line" >> "$outfile"
    done < "$input_file"
done

echo "Processing complete. Check the status_*.txt files for results."
