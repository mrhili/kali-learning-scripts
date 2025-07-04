#!/usr/bin/env bash
# port_lookup.sh - Enhanced bug hunting helper for port lookup and recon suggestions
# Usage:
#   ./port_lookup.sh [-h] [-v] [-u] [-p ports] [-f file] [-t target] [-e]
# Options:
#   -h            Show help and exit
#   -v            Show version and exit
#   -u            Force update of local CSV cache
#   -p ports      Comma-separated list of ports to lookup
#   -f file       File containing ports (one per line)
#   -t target     Target IP/hostname for recon suggestions (default: none)
#   -e            Export results to JSON file

VERSION="1.1.0"
CSV_URL="https://raw.githubusercontent.com/maraisr/ports-list/main/all.csv"
CSV_FILE="ports.csv"
JSON_OUTPUT="port_lookup_$(date +%Y%m%d%H%M%S).json"
PORTS=()
TARGET=""
FORCE_UPDATE=false
EXPORT_JSON=false

# Color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

show_help() {
  cat <<EOF
Usage: $0 [options]
  -h            Show help
  -v            Show version
  -u            Force CSV refresh
  -p ports      Comma-separated ports
  -f file       File with one port per line
  -t target     Target host/IP (for recon tools)
  -e            Export output as JSON
EOF
}

# Parse options
while getopts ":hvu p:f:t:e" opt; do
  case $opt in
    h) show_help; exit 0 ;; 
    v) echo "$0 version $VERSION"; exit 0 ;; 
    u) FORCE_UPDATE=true ;; 
    p) IFS=',' read -r -a PORTS <<< "$OPTARG" ;; 
    f) mapfile -t PORTS < "$OPTARG" ;; 
    t) TARGET="$OPTARG" ;; 
    e) EXPORT_JSON=true ;; 
    :) echo -e "${RED}Error:${NC} -$OPTARG requires an argument."; exit 1 ;; 
    \?) echo -e "${RED}Invalid option:${NC} -$OPTARG"; show_help; exit 1 ;; 
  esac
done
shift $((OPTIND -1))

# Ensure dependencies
for cmd in curl awk getent jq; do
  command -v $cmd >/dev/null 2>&1 || { echo -e "${RED}Missing dependency:${NC} $cmd is required."; exit 1; }
done

# Download or update CSV
if [[ ! -f "$CSV_FILE" || "$FORCE_UPDATE" == true ]]; then
  echo -e "${BLUE}Fetching port list...${NC}"
  curl -sSL "$CSV_URL" -o "$CSV_FILE" || { echo -e "${RED}Failed to download CSV.${NC}"; exit 1; }
  echo -e "${GREEN}Port list updated.${NC}"
fi

# Prompt if no ports
if [[ ${#PORTS[@]} -eq 0 ]]; then
  read -rp "Enter ports (comma-separated): " input
  IFS=',' read -r -a PORTS <<< "$input"
fi

# Prepare JSON array
if [[ "$EXPORT_JSON" == true ]]; then
  echo "[]" > "$JSON_OUTPUT"
fi

# Lookup loop
echo -e "${YELLOW}Lookup results:${NC}\n"
for port in "${PORTS[@]}"; do
  port=${port//[[:space:]]/}
  # Extract protocol, desc
  protocol=$(awk -F',' -v p="$port" '$2==p {gsub(/"/,"", $1); print tolower($1)}' "$CSV_FILE" | head -n1)
  desc=$(awk -F',' -v p="$port" '$2==p {gsub(/"/,"", $3); print $3}' "$CSV_FILE" | head -n1)
  [[ -z "$protocol" ]] && protocol="tcp"

  # Service lookup
  service=$(getent services "$port/$protocol" 2>/dev/null | awk '{print $1}' | cut -d'/' -f1)
  [[ -z "$service" ]] && service="unknown"
  [[ -z "$desc" ]] && desc="No description available"

  title="Port: $port/$protocol"
  echo -e "${GREEN}$title${NC}"
  echo "Service: $service"
  echo "Description: $desc"

  # Recon suggestions
  suggestion="nmap -sV -p $port/$protocol -sC"
  case "$service" in
    http|www-http)
        suggestion="nmap -sV -p $port/$protocol --script=http-enum,http-methods,http-vhosts,vuln ${TARGET:+-Pn} $TARGET";;
    https)
        suggestion="nikto -h https://$TARGET:$port";;
    ssh)
        suggestion="hydra -L users.txt -P passlist.txt ssh://$TARGET -t 4";;
    ftp)
        suggestion="nmap -p $port --script=ftp-anon,ftp-brute ${TARGET:+$TARGET}";;
    dns)
        suggestion="dig @$TARGET axfr example.com";;
    smtp)
        suggestion="nmap -p $port --script=smtp-commands,smtp-enum-users ${TARGET:+-Pn} $TARGET";;
    pop3)
        suggestion="hydra -L users.txt -P passlist.txt pop3://$TARGET -t 4";;
    imap)
        suggestion="hydra -L users.txt -P passlist.txt imap://$TARGET -t 4";;
    smb|microsoft-ds)
        suggestion="nmap -p $port --script=smb-os-discovery,smb-enum-shares,smb-vuln* ${TARGET:+-Pn} $TARGET";;
    rdp)
        suggestion="nmap -p $port --script=rdp-enum-encryption,rdp-vuln-cve2019-0708 ${TARGET:+-Pn} $TARGET";;
    mysql)
        suggestion="nmap -p $port --script=mysql-info,mysql-brute ${TARGET:+-Pn} $TARGET";;
    postgresql)
        suggestion="nmap -p $port --script=pgsql-info,pgsql-brute ${TARGET:+-Pn} $TARGET";;
    ms-sql-s|mssql)
        suggestion="nmap -p $port --script=ms-sql-info,ms-sql-brute ${TARGET:+-Pn} $TARGET";;
    oracle)
        suggestion="nmap -p $port --script=oracle-sid-brute,oracle-brute ${TARGET:+-Pn} $TARGET";;
    snmp)
        suggestion="nmap -sU -p $port --script=snmp-info,snmp-brute ${TARGET:+-Pn} $TARGET";;
    ldap)
        suggestion="nmap -p $port --script=ldap-rootdse,ldap-search ${TARGET:+-Pn} $TARGET";;
    ntp)
        suggestion="ntpdc -n -c monlist $TARGET";;
    vnc)
        suggestion="nmap -p $port --script=vnc-info,vnc-brute ${TARGET:+-Pn} $TARGET";;
    mongodb)
        suggestion="nmap -p $port --script=mongodb-info,mongodb-brute ${TARGET:+-Pn} $TARGET";;
    redis)
        suggestion="nmap -p $port --script=redis-info ${TARGET:+-Pn} $TARGET";;
    memcached)
        suggestion="echo 'stats' | nc $TARGET $port";;
    rabbitmq)
        suggestion="nmap -p $port --script=rabbitmq-management ${TARGET:+-Pn} $TARGET";;
    elasticsearch)
        suggestion="curl -s http://$TARGET:$port/_cat/indices?v";;
    couchdb)
        suggestion="curl -s http://$TARGET:$port/_all_dbs";;
    docker)
        suggestion="curl --unix-socket /var/run/docker.sock http://localhost/containers/json";;
    x11)
        suggestion="x11vnc -display :0";;
    sip)
        suggestion="sipvicious svmap -M INVITE $TARGET";;
    minecraft)
        suggestion="nmap -p $port --script=minecraft-info ${TARGET:+-Pn} $TARGET";;
    * )
        suggestion="nmap -sV -p $port/$protocol -sC ${TARGET:+-Pn} $TARGET";;
  esac
  echo -e "Suggestion: ${YELLOW}$suggestion${NC}\n"

  # Append to JSON
  if [[ "$EXPORT_JSON" == true ]]; then
    jq ". += [{\"port\": $port, \"protocol\": \"$protocol\", \"service\": \"$service\", \"description\": \"$desc\", \"suggestion\": \"$suggestion\"}]" "$JSON_OUTPUT" > tmp.json && mv tmp.json "$JSON_OUTPUT"
  fi
  echo "----------------------------------------"
done

if [[ "$EXPORT_JSON" == true ]]; then
  echo -e "\nExported results to $JSON_OUTPUT"
fi