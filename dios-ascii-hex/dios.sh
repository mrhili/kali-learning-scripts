#!/bin/bash

# Function to convert hex to ASCII (decoding)
hex_to_ascii() {
    local hex_input="$1"
    # Remove "0x" prefix if present
    hex_input="${hex_input#0x}"

    # Validate input - check if it's a valid hexadecimal string
    if [[ ! "$hex_input" =~ ^[0-9a-fA-F]+$ ]]; then
        echo "Invalid input: Please enter a valid hexadecimal string."
        exit 1
    fi

    # Convert hex to ASCII
    ascii_output=$(echo "$hex_input" | xxd -r -p)
    echo "ASCII result: $ascii_output"
}

# Function to convert ASCII to hex (encoding)
ascii_to_hex() {
    local ascii_input="$1"
    # Convert ASCII to hex
    hex_output=$(echo -n "$ascii_input" | xxd -p | tr -d '\n')
    echo "Hex result: 0x$hex_output"
}

# Main menu
echo "Choose an option:"
echo "1. Decode hex to ASCII"
echo "2. Encode ASCII to hex"
read -p "Enter your choice (1 or 2): " choice

# Process user choice
case $choice in
    1)
        read -p "Enter a hex string (e.g., 0x3c2f7469746c653e): " hex_string
        hex_to_ascii "$hex_string"
        ;;
    2)
        read -p "Enter an ASCII string (e.g., </title>): " ascii_string
        ascii_to_hex "$ascii_string"
        ;;
    *)
        echo "Invalid choice. Please select 1 or 2."
        exit 1
        ;;
esac