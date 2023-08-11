#!/bin/bash
# Set environment variables
source /etc/profile
source ~/.bash_profile
# Check if the script is executed with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with 'sudo'."
    exit 1
fi

# Source directory to be backed up
source_dir="/home/<user name>/Desktop/desky/vpn"

# Destination directory for the backup
backup_dir="/home/<user name>/Desktop/backup"

# Backup timestamp
backup_date=$(date +%Y-%m-%d_%H-%M-%S)

# Create a backup directory if it doesn't exist
mkdir -p "$backup_dir"

# Perform the backup
echo "Performing backup..."
cp -r "$source_dir" "$backup_dir/backup_$backup_date"
echo "Backup completed."