#!/bin/bash
# Script: generate_massdns.sh
# Description: Given a long host and a starting keyword, generate candidate domains by
# progressively prepending labels to the fixed portion (e.g., indrive.com) and then create
# massdns input lists and run massdns for each domain.
#
# Usage: ./generate_massdns.sh <long-host> <starting-keyword>
# Example:
#   ./generate_massdns.sh 0.1000000-okta-idpsvc-legacy1-api-e6zyxw.qamobile.qa.delivery.indrive.com delivery

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <long-host> <starting-keyword>"
  exit 1
fi

longhost="$1"
start_keyword="$2"

# Split the long host into an array using '.' as the delimiter.
IFS='.' read -r -a parts <<< "$longhost"

# Find the index where the starting keyword appears.
start_index=-1
for i in "${!parts[@]}"; do
  if [[ "${parts[$i]}" == "$start_keyword" ]]; then
    start_index=$i
    break
  fi
done

if [ $start_index -eq -1 ]; then
  echo "Error: Starting keyword '$start_keyword' not found in host '$longhost'."
  exit 1
fi

# Build candidate domains.
# We iterate from the starting keyword index down to 0 so that we prepend labels.
# For example, with start_index=3, we get:
#   i=3: delivery.indrive.com
#   i=2: qa.delivery.indrive.com
#   i=1: qamobile.qa.delivery.indrive.com
#   i=0: 0.1000000-okta-idpsvc-legacy1-api-e6zyxw.qamobile.qa.delivery.indrive.com
domains=()
for (( i=start_index; i>=0; i-- )); do
  # Join the parts from index i to the end using a dot as a separator.
  domain=$(IFS="."; echo "${parts[*]:i}")
  domains+=("$domain")
done

# Iterate through each candidate domain.
for domain in "${domains[@]}"; do
  echo "Processing domain: $domain"

  # Build the massdns input list.
  # For example, for domain "qa.delivery.indrive.com", each line becomes:
  #    <word>.qa.delivery.indrive.com
  awk -v host="$domain" '{print $0 "." host}' /usr/share/seclists/Discovery/DNS/namelist.txt > "${domain}_massdnslist.txt"
  
  # Run MassDNS with the generated list.
  massdns "${domain}_massdnslist.txt" -r /home/kali/Tools/massdns/lists/resolvers.txt -o S -t A -q | \
    awk -F" " '{print $1}' | sed 's/\.$//' | sort -u > "output_${domain}_include.txt"
done