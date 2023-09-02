#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with 'sudo'."
    echo "Example sudo ./unmonitor.sh wlan0"
    exit 1
else
	ifconfig $1 down && iwconfig $1 mode managed && ifconfig $1 up
    service NetworkManger start
    sudo service NetworkManger restart
fi