#!/bin/bash
# Script: sort_domains_tree.sh
# Description: Sorts domains so that top-level domains appear at the top and related subdomains are grouped.
#              This is done by reversing each domain, sorting the reversed lines, and then reversing them back.
#              The original input file remains unchanged.
#
# Usage: ./sort_domains_tree.sh <input_file> <output_file>
#
# Example:
#   ./sort_domains_tree.sh domains.txt sorted_domains.txt
#
# Input file should contain one domain per line.

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_file> <output_file>"
  exit 1
fi

input_file="$1"
output_file="$2"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Error: Input file '$input_file' not found."
  exit 1
fi

# Reverse each line of the input file, sort the reversed lines, then reverse back and save to the output file.
rev "$input_file" | sort | rev > "$output_file"

echo "Sorted domains have been written to $output_file."
