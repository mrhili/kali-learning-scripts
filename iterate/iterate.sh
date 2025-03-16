#!/bin/bash
# Script: generate_placeholder_domains.sh
# Description: Given a domain template that contains a placeholder marker (e.g., "§§")
# and a numeric range, this script generates candidate domains by replacing the
# placeholder with each number in that range.
#
# Usage: ./generate_placeholder_domains.sh <template> <start_number> <end_number>
# Example:
#   ./generate_placeholder_domains.sh "§§.slkjd.com" 1 5
# This will produce:
#   1.slkjd.com
#   2.slkjd.com
#   3.slkjd.com
#   4.slkjd.com
#   5.slkjd.com
#
# The output is saved to output_domains.txt

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <template> <start_number> <end_number>"
    exit 1
fi

template="$1"
start_num="$2"
end_num="$3"

# Validate that start_num and end_num are numeric.
if ! [[ "$start_num" =~ ^[0-9]+$ ]] || ! [[ "$end_num" =~ ^[0-9]+$ ]]; then
    echo "Error: Start and end numbers must be numeric."
    exit 1
fi

# Ensure start is not greater than end.
if [ "$start_num" -gt "$end_num" ]; then
    echo "Error: Start number must be less than or equal to end number."
    exit 1
fi

# Validate that the template contains the placeholder marker.
if [[ "$template" != *"§§"* ]]; then
    echo "Error: Template must contain the placeholder marker '§§'."
    exit 1
fi

output_file="output_domains.txt"
> "$output_file"  # Clear the output file if it exists

# Loop from start to end, replace the placeholder marker in the template, and save each candidate.
for (( i=start_num; i<=end_num; i++ )); do
    candidate="${template//§§/$i}"
    echo "$candidate" >> "$output_file"
done

echo "Candidate domains have been saved to $output_file."
