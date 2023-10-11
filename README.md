# Some scripts i write when i was teatching kali linux

## Backup scripts for youre favorite folder

/backup-script-work-with-crontab/backup.sh

## Simple file manager list and navigate and serach

/files-manager-script/manager


## generate good passwords and evaluate them

/password-evaluator/evaluator.sh and /password-generator/generator.sh passwords.txt

## Translate popular commands from linux to powershell

/basic-bash2powershell-translator/basictranslator.sh curl ipinfo.io/52.156.12.167


## Offline mac research

/offline-mac-research/search.sh 50:46:5D:6E:8C:20

## Searc ip address from mac address in youre local network

/search-local-ip-from-mac/search.sh 50:46:5D:6E:8C:20


## turn you wireless card to mode monitor or managed


Example 1

/monitor/monitor.sh wlan0

Example 2

/monitor/unmonitor.sh wlan0


## Obfuscating a script using python and deobfuscating it and executing it or output it on the shell


## Obfuscating
Obfuscating using base64

    ## Example

        python3 /obfs_python/obfs.py example.py obfs.py

## DeObfuscating and executing
Deobfuscating using base64

    ## Example

        python3 /obfs_python/deobfs.py obfs.py --execute

## DeObfuscating and saving
Deobfuscating using base64

    ## Example

        python3 /obfs_python/deobfs.py obfs.py --output=reveal.py
## Kali linux staring configuration

    ## Example
    ./configure/configure.sh

    output:
        [+] Update and upgrade machine
        [OK]


## REDHCP

/redhcp/redhcp.sh

# -----------------------


Ideas and what i need to do:

-Make all the scripts in one script like the lazy script

-in monitor script i should add more scripts minimonitor (no kill) pidimonoitor (Just monitor)

-a script to chmod all the scripts



