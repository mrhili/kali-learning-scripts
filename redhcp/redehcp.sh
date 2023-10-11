#!/bin/bash

# Release the DHCP lease for eth0
sudo dhclient -r eth0

# Renew the DHCP lease for eth0
sudo dhclient eth0


ping duckduckgo.com