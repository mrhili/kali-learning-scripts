# Some scripts i write when i was teatching kali linux

## Backup scripts for youre favorite folder

/backup-script-work-with-crontab/backup.sh

## Simple file manager list and navigate and serach

/files-manager-script/manager

## generate good passwords and evaluate them

/password-evaluator/evaluator.sh and /password-generator/generator.sh passwords.txt

## Regenerate machine id

sudo /machine-id-regenaration/re.sh

## Regenerate machine id

sudo /hostname-change/change.sh


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


## DIOS FOR SQL INJECTION

/dios-ascii-hex/dios.sh



# AUtomatic analyzer for WFUZZ

First
Change the variable for common variables then lunch the script

col2_value=200
col3_value=29
col5_value=190
col7_min=3700
col7_max=380

Example

./analyze.sh



# Simple brute force script using curl with automation


Example

./login-bruteforce.sh -u "http://secb/api/Auth/Login" -U "adomin@ssrd.io" -P /usr/share/wordlists/rockyou.txt

output:

    Failed login with Username: adomin@ssrd.io Password: matthew (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: robert (HTTP status: 400)
    Success! Username: adomin@ssrd.io Password: snailmail
    Failed login with Username: adomin@ssrd.io Password: eminem (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: matthew (HTTP status: 400)
    Failed login with Username: adomin@ssrd.io Password: robert (HTTP status: 400)



## Proof of concept of localStorage Stealer

    ## Usage
    git clone https://github.com/mrhili/demo-localStorage-stealer

## CTF GAME : HACKSIM GAME

    ## Usage
    git clone https://github.com/mrhili/HackSim && cd HackSim && python3 -m pip install -r requirements.txt && python3 main.py

## Real GAME HACKED : Guess this code by mansour code

    git clone https://github.com/mrhili/guessthiscode.com-userscript
    addit to temper-monkey and visit guessthiscode.com and play the hack

## Play with cryptography :VGNR

    git clone https://github.com/mrhili/vgnr && cd vgnr && python3 -m pip install -e
# -----------------------






Ideas and what i need to do:

-Make all the scripts in one script like the lazy script

-in monitor script i should add more scripts minimonitor (no kill) pidimonoitor (Just monitor)

-a script to chmod all the scripts



