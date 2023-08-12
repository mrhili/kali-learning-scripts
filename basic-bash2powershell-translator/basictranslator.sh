#!/bin/bash

# Translate Linux commands to PowerShell

# curl command
function linux_curl {
    url="$1"
    echo Invoke-RestMethod -Uri $url
}

# ls command
function linux_ls {
    dir="$1"
    echo Get-ChildItem $dir
}

# df command
function linux_df {
    echo Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace
}

# ping command
function linux_ping {
    host="$1"
    echo Test-Connection -ComputerName $host
}

# Main script
command="$1"

#Delete first arg
shift

case "$command" in
    curl)
        linux_curl "$@"
        ;;
    ls)
        linux_ls "$@"
        ;;
    df)
        linux_df
        ;;
    ping)
        linux_ping "$@"
        ;;
    *)
        echo "Unsupported command: $command"
        exit 1
        ;;
esac