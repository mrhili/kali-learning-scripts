# Kali Linux Teaching Scripts

This repository contains a collection of Bash and Python scripts I created while teaching Kali Linux and exploring offensive security and automation.

---

## Bug Bounty Scripts

### Recon with MassDNS

```bash
/recon-massdns/recon-massdns.sh <long_domain> <keyword_to_start_with>
```

### Domain Tree Visualization

```bash
/domain_tree/domain_tree.sh <input_file> > <output_file>
```

### Sort Domains

```bash
/sort_domains/sort_domains.sh <input_file> <output_file>
```

### Separate Domains by Main Domain

```bash
/domains_separate/separate.sh <input_file> <main_domain>
```

### Split Domains by HTTP Status

```bash
./split.sh <file>
./split.sh <file1> <file2> <file3>
```

### Port Lookup

```bash
./port_lookup/port_lookup.sh
```

### Python Web Server

```bash
python python_server/serve.py
```

### Redirector (Bypass IP Filters)

```bash
python redirector/redirector.py
```

### Weasy PDF Payload Reader

```bash
python weasy/weasy.py
```

This script reads WeasyPrint-generated PDFs with payloads such as:

```html
<link rel="attachment" href="file:///etc/passwd" />
<iframe src="http://localhost/local.txt" height="800px" width="800px"></iframe>
```

---

## Kali Linux Scripts

### Backup Script (cron-compatible)

```bash
/backup-script-work-with-crontab/backup.sh
```

### File Manager with Search & Navigation

```bash
/files-manager-script/manager
```

### Translate Bash to PowerShell

```bash
/basic-bash2powershell-translator/basictranslator.sh curl ipinfo.io/52.156.12.167
```

### IP Generator

```bash
./ipgen/ipgen.sh 192.168.1.1-6 output.txt
```

Output:

```
192.168.1.1
192.168.1.2
...
192.168.1.6
```

---

## Security Scripts

### Password Generation & Evaluation

```bash
/password-generator/generator.sh passwords.txt
/password-evaluator/evaluator.sh passwords.txt
```

### Regenerate Machine ID

```bash
sudo /machine-id-regenaration/re.sh
```

### Change Hostname

```bash
sudo /hostname-change/change.sh
```

---

## Uncategorized Scripts

### Offline MAC Address Research

```bash
/offline-mac-research/search.sh 50:46:5D:6E:8C:20
```

### Find Local IP from MAC

```bash
/search-local-ip-from-mac/search.sh 50:46:5D:6E:8C:20
```

### Monitor Mode Scripts

```bash
/monitor/monitor.sh wlan0
/monitor/unmonitor.sh wlan0
```

---

## Obfuscation & Execution (Python)

### Obfuscate Python Script

```bash
python3 /obfs_python/obfs.py example.py obfs.py
```

### Deobfuscate and Execute

```bash
python3 /obfs_python/deobfs.py obfs.py --execute
```

### Deobfuscate and Output

```bash
python3 /obfs_python/deobfs.py obfs.py --output=reveal.py
```

---

## Initial Kali Configuration

```bash
./configure/configure.sh
```

Output:

```
[+] Update and upgrade machine
[OK]
```

---

## Tools & Utilities

### RedHCP (Dynamic DHCP Script)

```bash
/redhcp/redhcp.sh
```

### DIOS (SQLi Payload Generator)

```bash
/dios-ascii-hex/dios.sh
```

### WFuzz Analyzer

Edit these variables inside the script first:

```bash
col2_value=200
col3_value=29
col5_value=190
col7_min=3700
col7_max=380
```

Then run:

```bash
./analyze.sh
```

### Python Brute-force Login

```bash
python ./py-login-bruteforce/bruteforce_v3.py --url <login_url> --cookie "session=..." --userlist <userlist.txt> --passlist <passwords.txt> --mode both --threads 10
```

### cURL Brute-force Login

```bash
./login-bruteforce.sh -u "http://example/api/Auth/Login" -U "admin@example.com" -P /usr/share/wordlists/rockyou.txt
```

Output:

```
Failed login... Success! Username: ... Password: ...
```

### Domain Iteration Generator

```bash
/iterate/iterate.sh template§§.com 5 7
```

---

## Projects & Games

### LocalStorage Stealer PoC

```bash
git clone https://github.com/mrhili/demo-localStorage-stealer
```

### HackSim CTF Game

```bash
git clone https://github.com/mrhili/HackSim
cd HackSim
python3 -m pip install -r requirements.txt
python3 main.py
```

### GuessThisCode by mansour Hack Game

```bash
git clone https://github.com/mrhili/guessthiscode.com-userscript
```

Add to Tampermonkey and visit guessthiscode.com to play.

### VGNR Crypto Game

```bash
git clone https://github.com/mrhili/vgnr
cd vgnr
python3 -m pip install -e
```

---

## To-Do & Ideas

* Combine all scripts into a single LazyScript-style menu.
* Improve monitor script with additional modes: `mini-monitor` (non-kill) and `pidi-monitor` (passive).
* Add script to `chmod +x` all scripts and install all Python dependencies automatically.
