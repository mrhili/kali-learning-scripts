#!/bin/bash

# Function to generate IPs from ranges
generate_ips_from_ranges() {
    local input="$1"
    local output_file="$2"

    # Regex to validate and parse input ranges
    if [[ "$input" =~ ^([0-9]+(-[0-9]+)?).([0-9]+(-[0-9]+)?).([0-9]+(-[0-9]+)?).([0-9]+(-[0-9]+)?)$ ]]; then
        # Parse ranges for each octet
        IFS='-' read -r o1_start o1_end <<< "${BASH_REMATCH[1]}"
        IFS='-' read -r o2_start o2_end <<< "${BASH_REMATCH[3]}"
        IFS='-' read -r o3_start o3_end <<< "${BASH_REMATCH[5]}"
        IFS='-' read -r o4_start o4_end <<< "${BASH_REMATCH[7]}"

        # Default to the single value if no range is provided
        o1_end=${o1_end:-$o1_start}
        o2_end=${o2_end:-$o2_start}
        o3_end=${o3_end:-$o3_start}
        o4_end=${o4_end:-$o4_start}

        # Generate IPs using nested loops
        for o1 in $(seq "$o1_start" "$o1_end"); do
            for o2 in $(seq "$o2_start" "$o2_end"); do
                for o3 in $(seq "$o3_start" "$o3_end"); do
                    for o4 in $(seq "$o4_start" "$o4_end"); do
                        ip="$o1.$o2.$o3.$o4"
                        echo "$ip"
                        [[ -n "$output_file" ]] && echo "$ip" >> "$output_file"
                    done
                done
            done
        done
    else
        echo "Unsupported range format! Please use '1-2.1-2.1-2.1-3' or CIDR notation."
        exit 1
    fi
}

# Function to generate IPs from CIDR notation
generate_ips_from_cidr() {
    local input="$1"
    local output_file="$2"

    # Regex to validate CIDR notation
    if [[ "$input" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/([0-9]+)$ ]]; then
        local base_ip="${BASH_REMATCH[1]}"
        local prefix="${BASH_REMATCH[2]}"

        # Ensure the prefix is valid
        if ((prefix < 0 || prefix > 32)); then
            echo "Invalid CIDR prefix! Must be between 0 and 32."
            exit 1
        fi

        # Convert base IP to integer
        IFS='.' read -r o1 o2 o3 o4 <<< "$base_ip"
        local ip_as_int=$((o1 * 256 ** 3 + o2 * 256 ** 2 + o3 * 256 + o4))

        # Calculate the range of IPs based on the prefix
        local num_hosts=$((2 ** (32 - prefix)))
        local start_ip=$ip_as_int
        local end_ip=$((ip_as_int + num_hosts - 1))

        # Generate IPs within the range
        for ((ip = start_ip; ip <= end_ip; ip++)); do
            printf "%d.%d.%d.%d\n" $((ip >> 24 & 255)) $((ip >> 16 & 255)) $((ip >> 8 & 255)) $((ip & 255))
            [[ -n "$output_file" ]] && printf "%d.%d.%d.%d\n" $((ip >> 24 & 255)) $((ip >> 16 & 255)) $((ip >> 8 & 255)) $((ip & 255)) >> "$output_file"
        done
    else
        echo "Unsupported CIDR format! Please use 'A.B.C.D/E'."
        exit 1
    fi
}

# Main logic
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <IP_RANGE_OR_CIDR> [OUTPUT_FILE]"
    exit 1
fi

input="$1"
output_file="$2"

# Clear output file if specified
[[ -n "$output_file" ]] && > "$output_file"

# Determine the format and invoke the appropriate function
if [[ "$input" =~ / ]]; then
    generate_ips_from_cidr "$input" "$output_file"
else
    generate_ips_from_ranges "$input" "$output_file"
fi
