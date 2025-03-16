#!/bin/bash
# Script: sort_domains_tree.sh
# Description: Sorts domains so that top-level domains appear at the top and related subdomains
# are grouped together. It reverses each domain, sorts using external sorting (with parallelism),
# then reverses the domains back. Designed to efficiently handle very large files.
#
# Usage: ./sort_domains_tree.sh <input_file> <output_file>
# Example:
#   ./sort_domains_tree.sh domains.txt sorted_domains.txt
#
# The input file should contain one domain per line.

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_file> <output_file>"
  exit 1
fi

input_file="$1"
output_file="$2"

if [ ! -f "$input_file" ]; then
  echo "Error: Input file '$input_file' not found."
  exit 1
fi

# Use LC_ALL=C for faster sorting (byte-wise) and --parallel for multi-core processing.
LC_ALL=C rev "$input_file" | sort --parallel=$(nproc) | rev > "$output_file"

echo "Sorted domains have been written to $output_file."
