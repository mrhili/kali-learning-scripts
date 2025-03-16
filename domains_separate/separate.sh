#!/bin/bash
# Script: separate_and_sort_by_level.sh
# Description:
#   Reads a file of domains (one per line) and separates them into files based on the number
#   of subdomain labels preceding a given base domain.
#
#   In addition, each level file is sorted using a reversed-sort technique so that domains
#   are grouped by top-level domain parts (TLD, SLD, etc.) rather than just plain alphabetical order.
#
# Usage:
#   ./separate_and_sort_by_level.sh <input_file> <base_domain>
#
# Example:
#   ./separate_and_sort_by_level.sh all_subs.txt indrive.com
#
# Output:
#   level0.txt  - Domains that are exactly the base domain (if any)
#   level1.txt  - Domains with one subdomain (e.g., foo.indrive.com)
#   level2.txt  - Domains with two subdomains (e.g., bar.foo.indrive.com)
#   etc.
#
# Each file is sorted so that domains with the same top-level parts are grouped together.

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <base_domain>"
    exit 1
fi

input_file="$1"
base_domain="$2"

# Remove any previous level files so we start fresh.
rm -f level*.txt

# Process each domain using awk.
# For each domain that ends with ".<base_domain>", remove the base portion and count how many labels remain.
# That count is used as the level.
awk -v base="$base_domain" '
    # Only process domains that end with "." followed by the base domain.
    $0 ~ ("\\." base "$") {
        # Remove the dot and base domain from the end.
        sub_part = substr($0, 1, length($0) - length(base) - 1)
        if (sub_part == "") {
            level = 0
        } else {
            # Count the number of labels in the subdomain part by splitting on the dot.
            n = split(sub_part, arr, "\\.")
            level = n
        }
        print $0 >> ("level" level ".txt")
    }
' "$input_file"

# For each level file, sort the contents using reversed order.
# Reversing the domains brings the base parts (TLD, SLD, etc.) to the front,
# then we sort and reverse them back.
for file in level*.txt; do
    if [ -f "$file" ]; then
        # The LC_ALL=C ensures a fast, byte-wise sort. --parallel uses all available cores.
        rev "$file" | sort --parallel=$(nproc) | rev > "${file}.sorted"
        mv "${file}.sorted" "$file"
    fi
done

echo "Domains have been separated and sorted by level in files: level*.txt"
