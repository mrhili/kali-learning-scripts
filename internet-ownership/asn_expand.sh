#!/usr/bin/env bash

# Experimental Lab: ASN Expansion Pipeline
# Goal: Expand ASNs into CIDRs, normalize targets, and (optionally) expand to IPs.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASN_LIST=""
CIDR_OUT="$BASE_DIR/cidrs.txt"
TARGETS_OUT="$BASE_DIR/targets.txt"
USE_BGPHE="false"
USE_IPINFO="false"
IPINFO_TOKEN=""
NO_EXPAND="false"
AUTO_YES="false"
DEBUG="false"

print_help() {
  cat <<'EOF'
Usage:
  asn_expand.sh -a "AS13335,AS15169" [options]

Options:
  -a, --asn "AS123,AS456"   Comma-separated ASN list (required)
  --cidr-out <file>         Output file for CIDRs (default: ./cidrs.txt)
  --targets-out <file>      Output file for targets (default: ./targets.txt)
  --use-bgphe               Also query bgp.he.net (best-effort HTML parsing)
  --use-ipinfo              Also query ipinfo (requires --ipinfo-token)
  --ipinfo-token <token>    ipinfo token
  --no-expand               Do not expand CIDRs into IPs
  --yes                     Auto-approve large expansions
  --debug                   Keep raw outputs and print extra info
  -h, --help                Show help

Examples:
  ./asn_expand.sh -a "AS13335,AS15169"
  ./asn_expand.sh -a "AS13335" --no-expand
  ./asn_expand.sh -a "AS13335" --use-ipinfo --ipinfo-token "$TOKEN"
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd"
    return 1
  fi
  return 0
}

log() {
  if [[ "$DEBUG" == "true" ]]; then
    echo "[DEBUG] $*"
  fi
}

normalize_asn() {
  local asn="$1"
  asn="$(echo "$asn" | tr '[:lower:]' '[:upper:]')"
  if [[ "$asn" =~ ^AS[0-9]+$ ]]; then
    echo "$asn"
  elif [[ "$asn" =~ ^[0-9]+$ ]]; then
    echo "AS$asn"
  else
    echo ""
  fi
}

fetch_whois() {
  local asn="$1"
  local out_file="$2"
  local servers=("whois.radb.net" "whois.ris.ripe.net" "whois.ripe.net")
  for srv in "${servers[@]}"; do
    log "Querying whois server: $srv for $asn"
    # Collect raw output for debugging
    whois -h "$srv" -- "-i origin $asn" >> "$out_file" || true
  done
  awk '/^route6?:/{print $2}' "$out_file"
}

fetch_bgphe() {
  local asn="$1"
  # Best-effort HTML parsing
  curl -s "https://bgp.he.net/$asn" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}' || true
  curl -s "https://bgp.he.net/$asn" | grep -oE '([0-9a-fA-F:]+)/[0-9]{1,3}' || true
}

fetch_ipinfo() {
  local asn="$1"
  local token="$2"
  curl -s "https://ipinfo.io/$asn?token=$token" | python3 - <<'PY'
import json, sys
data = json.load(sys.stdin)
for p in data.get("prefixes", []):
    cidr = p.get("netblock") or p.get("cidr")
    if cidr:
        print(cidr)
for p in data.get("prefixes6", []):
    cidr = p.get("netblock") or p.get("cidr")
    if cidr:
        print(cidr)
PY
}

estimate_total_ips() {
  local cidr_file="$1"
  python3 - <<'PY' "$cidr_file"
import ipaddress, sys
total = 0
with open(sys.argv[1], "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        try:
            net = ipaddress.ip_network(line, strict=False)
            total += net.num_addresses
        except ValueError:
            pass
print(total)
PY
}

expand_to_targets() {
  local cidr_file="$1"
  local targets_file="$2"
  python3 - <<'PY' "$cidr_file" "$targets_file"
import ipaddress, sys
cidr_file, out_file = sys.argv[1], sys.argv[2]
with open(cidr_file, "r", encoding="utf-8") as f, open(out_file, "w", encoding="utf-8") as out:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        try:
            net = ipaddress.ip_network(line, strict=False)
        except ValueError:
            continue
        for ip in net.hosts():
            out.write(str(ip) + "\n")
PY
}

if [[ $# -eq 0 ]]; then
  echo "No arguments provided."
  print_help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--asn) ASN_LIST="$2"; shift 2 ;;
    --cidr-out) CIDR_OUT="$2"; shift 2 ;;
    --targets-out) TARGETS_OUT="$2"; shift 2 ;;
    --use-bgphe) USE_BGPHE="true"; shift ;;
    --use-ipinfo) USE_IPINFO="true"; shift ;;
    --ipinfo-token) IPINFO_TOKEN="$2"; shift 2 ;;
    --no-expand) NO_EXPAND="true"; shift ;;
    --yes) AUTO_YES="true"; shift ;;
    --debug) DEBUG="true"; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown option: $1"; print_help; exit 1 ;;
  esac
done

if [[ -z "$ASN_LIST" ]]; then
  echo "ASN list is required."
  print_help
  exit 1
fi

if ! require_cmd whois; then
  echo "Install with: sudo apt install -y whois"
  exit 1
fi
if [[ "$USE_BGPHE" == "true" ]] && ! require_cmd curl; then
  echo "Install with: sudo apt install -y curl"
  exit 1
fi
if [[ "$USE_IPINFO" == "true" && -z "$IPINFO_TOKEN" ]]; then
  echo "ipinfo token is required when --use-ipinfo is set."
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for normalization/expansion."
  echo "Install with: sudo apt install -y python3 python3-venv python3-pip"
  exit 1
fi

WORK_DIR="$(mktemp -d)"
CIDR_TMP="$WORK_DIR/cidrs_raw.txt"
> "$CIDR_TMP"
RAW_WHOIS="$WORK_DIR/whois_raw.txt"
> "$RAW_WHOIS"

IFS=',' read -r -a ASN_ARRAY <<< "$ASN_LIST"
for raw in "${ASN_ARRAY[@]}"; do
  asn="$(normalize_asn "$raw")"
  if [[ -z "$asn" ]]; then
    echo "Skipping invalid ASN: $raw"
    continue
  fi
  echo "[+] Fetching CIDRs for $asn (whois)"
  fetch_whois "$asn" "$RAW_WHOIS" >> "$CIDR_TMP" || true
  if [[ "$USE_BGPHE" == "true" ]]; then
    echo "[+] Fetching CIDRs for $asn (bgp.he.net)"
    fetch_bgphe "$asn" >> "$CIDR_TMP" || true
  fi
  if [[ "$USE_IPINFO" == "true" ]]; then
    echo "[+] Fetching CIDRs for $asn (ipinfo)"
    fetch_ipinfo "$asn" "$IPINFO_TOKEN" >> "$CIDR_TMP" || true
  fi
done

sort -u "$CIDR_TMP" | sed '/^$/d' > "$CIDR_OUT"
if [[ "$DEBUG" == "true" ]]; then
  echo "[DEBUG] Raw whois output saved to: $RAW_WHOIS"
  echo "[DEBUG] Raw CIDR list saved to: $CIDR_TMP"
  echo "[DEBUG] CIDR count: $(wc -l < "$CIDR_OUT" | tr -d ' ')"
fi
echo "[OK] CIDRs saved to: $CIDR_OUT"

if [[ "$NO_EXPAND" == "true" ]]; then
  echo "[OK] Expansion disabled. Done."
  exit 0
fi

echo "[*] Estimating total IPs..."
TOTAL_IPS="$(estimate_total_ips "$CIDR_OUT")"
echo "[*] Estimated IPs to write: $TOTAL_IPS"

if [[ "$TOTAL_IPS" -gt 5000000 && "$AUTO_YES" != "true" ]]; then
  echo "This will create a very large targets file."
  read -r -p "Continue? [y/N]: " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Canceled."
    exit 0
  fi
fi

expand_to_targets "$CIDR_OUT" "$TARGETS_OUT"
echo "[OK] Targets saved to: $TARGETS_OUT"
