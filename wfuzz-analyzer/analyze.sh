#!/bin/bash

# Define the criteria for each column
col2_value=200
col3_value=29
col5_value=190
col7_min=3700
col7_max=380

while read -r line; do
  col2=$(echo "$line" | awk '{print $2}')
  col3=$(echo "$line" | awk '{print $3}')
  col5=$(echo "$line" | awk '{print $5}')
  col7=$(echo "$line" | awk '{print $7}')

  if [ "$col2" -ne "$col2_value" ] || [ "$col3" -ne "$col3_value" ] || [ "$col5" -ne "$col5_value" ] || [ "$col7" -lt "$col7_min" ] || [ "$col7" -gt "$col7_max" ]; then
    echo "$line"
  fi
done < tstawk.txt