#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with 'sudo'."
    exit 1
fi

# Backup the /etc/hosts file
cp /etc/hosts /etc/hosts.bak
if [ $? -eq 0 ]; then
    echo "Backup of /etc/hosts created at /etc/hosts.bak"
else
    echo "Failed to create backup of /etc/hosts. Exiting."
    exit 1
fi

# Store the current hostname
old_hostname=$(hostname)
echo "Your current hostname is: $old_hostname"

# Prompt the user for a new hostname
read -p "Enter the new hostname: " new_hostname

# Change the hostname using hostnamectl
hostnamectl set-hostname "$new_hostname"
if [ $? -eq 0 ]; then
    echo "Hostname successfully changed to: $new_hostname"
else
    echo "Failed to change hostname. Exiting."
    exit 1
fi

# Update /etc/hosts without corrupting it
# Check if the old hostname exists in the file and replace it with the new one
if grep -q "$old_hostname" /etc/hosts; then
    sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts
else
    # If the old hostname is not found, append the new hostname with its IP
    echo "$(hostname -I | cut -d' ' -f1) $new_hostname" | sudo tee -a /etc/hosts > /dev/null
fi

# Recheck if /etc/hosts was updated correctly
if grep -q "$new_hostname" /etc/hosts; then
    echo "/etc/hosts has been successfully updated with the new hostname."
else
    echo "Failed to update /etc/hosts. Restoring from backup."
    cp /etc/hosts.bak /etc/hosts
    exit 1
fi

# Show the user the old and new hostnames
echo "Old Hostname: $old_hostname"
echo "New Hostname: $new_hostname"

# Inform the user to reboot for changes to take full effect
echo "Please reboot the system to apply the new hostname."

exit 0
