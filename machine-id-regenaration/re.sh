#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with 'sudo'."
    exit 1
fi

old_machine_id=$(cat /var/lib/dbus/machine-id)


# Function to throw critical error and exit
critical_error() {
    echo "Critical Error: $1"
    echo "Please reboot and manually run the following commands:"
    echo "sudo dbus-uuidgen --ensure"
    echo "sudo dbus-uuidgen --ensure=/etc/machine-id"
    exit 1
}

# Inform the user about the process
echo "Regenerating machine ID..."

# Remove the current machine ID
rm -f /var/lib/dbus/machine-id
rm -f /etc/machine-id
echo "Removed /etc/machine-id and /var/lib/dbus/machine-id"

# Generate a new machine ID and use it for both files
new_machine_id=$(dbus-uuidgen)
echo $new_machine_id > /etc/machine-id
echo $new_machine_id > /var/lib/dbus/machine-id
echo "New machine ID has been generated and written to both files."

# Check if the IDs were written correctly
if [ ! -s /etc/machine-id ]; then
    critical_error "/etc/machine-id is empty after writing."
fi

if [ ! -s /var/lib/dbus/machine-id ]; then
    critical_error "/var/lib/dbus/machine-id is empty after writing."
fi

# Store both machine IDs in variables
etc_machine_id=$(cat /etc/machine-id)
varlib_machine_id=$(cat /var/lib/dbus/machine-id)

# Compare the two machine IDs
if [ "$etc_machine_id" == "$varlib_machine_id" ]; then
    echo "Machine ID successfully synchronized!"
else
    critical_error "Machine ID mismatch between /etc/machine-id and /var/lib/dbus/machine-id."
fi

# Display the old and new machine IDs
echo "OLD Machine ID: $old_machine_id"
echo "New Machine ID: $etc_machine_id"


hostnamecontrol_machine_id=$(hostnamectl | grep 'Machine ID' | cut -d ":" -f2 | cut -d " " -f2)


# Compare the two machine IDs
if [ "$etc_machine_id" == "$hostnamecontrol_machine_id" ]; then
    echo "Machine ID successfully put in the test"
else
    critical_error "Machine ID mismatch between /var/lib/dbus/machine-id and hostnamectl."
fi


echo "Old Machine ID (if any): $(hostnamectl | grep 'Machine ID')"
echo "New Machine ID (if any): $(echo hostnamecontrol_machine_id)"

# Print system information
hostnamectl

# Inform the user to reboot
echo "Machine ID has been regenerated. Please reboot the system to apply the changes."

# Advise the user to change the hostname
echo "For further anonymity, consider changing your hostname using 'sudo hostnamectl set-hostname NEW_HOSTNAME'."

exit 0
