#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with 'sudo'."
    echo "Example sudo ./monitor.sh wlan0"
    exit 1
else
	airmon-ng check kill
	ifconfig $1 down && iwconfig $1 mode monitor && ifconfig $1 up
	airodump-ng wlan0
fi