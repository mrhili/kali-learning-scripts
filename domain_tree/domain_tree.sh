#!/bin/bash
# Script: domain_tree.sh
# Description: Given a file containing domains (one per line), this script displays
# a hierarchical tree of the domain parts. The tree is built from right to left,
# so the TLD is at the top and each subdomain is nested below its parent.
#
# Usage: ./domain_tree.sh <domains_file>
# Example:
#   ./domain_tree.sh domains.txt
#
# Make sure your domains file contains one domain per line, e.g.:
#   foo.example.com
#   bar.example.com
#   test.foo.example.com

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <domains_file>"
  exit 1
fi

DOMAIN_FILE="$1"

python3 - <<EOF
import sys

def add_to_tree(tree, parts):
    """Recursively add domain parts (in reverse order) into the nested dictionary."""
    if not parts:
        return
    part = parts[0]
    if part not in tree:
        tree[part] = {}
    add_to_tree(tree[part], parts[1:])

def print_tree(tree, prefix=""):
    """Recursively print the tree using a tree-like indentation."""
    keys = sorted(tree.keys())
    for i, key in enumerate(keys):
        last = (i == len(keys) - 1)
        if last:
            print(prefix + "└── " + key)
            new_prefix = prefix + "    "
        else:
            print(prefix + "├── " + key)
            new_prefix = prefix + "│   "
        print_tree(tree[key], new_prefix)

def main():
    filename = "$DOMAIN_FILE"
    tree = {}
    try:
        with open(filename, "r") as f:
            for line in f:
                domain = line.strip()
                if not domain:
                    continue
                # Split the domain into parts and reverse the list so that TLD is first.
                parts = domain.split(".")
                parts = parts[::-1]
                add_to_tree(tree, parts)
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)
    print_tree(tree)

if __name__ == "__main__":
    main()
EOF
