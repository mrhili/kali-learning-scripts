#!/usr/bin/env bash

# Kali Learning Scripts - LazyScript-style dashboard
# This dashboard is intended to run on Kali Linux.

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors (safe if terminal supports it)
if [[ -t 1 ]]; then
  RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"
  YELLOW="$(printf '\033[33m')"
  BLUE="$(printf '\033[34m')"
  BOLD="$(printf '\033[1m')"
  RESET="$(printf '\033[0m')"
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi

print_header() {
  clear
  echo "${BOLD}Kali Learning Scripts - Dashboard${RESET}"
  echo "LazyScript-style menu to help beginners get started."
  echo
  if command -v groups >/dev/null 2>&1; then
    if groups | grep -q '\bsudo\b'; then
      echo "${GREEN}[OK]${RESET} User is in sudo group."
    else
      echo "${YELLOW}[WARN]${RESET} User is NOT in sudo group. Some tools will fail until sudo is configured."
      echo "      Tip: ask an admin to add your user to the sudo group."
    fi
  fi
  echo
}

pause() {
  echo
  read -r -p "Press Enter to continue..." _
}

ask_yes_no() {
  local prompt="$1"
  read -r -p "$prompt [y/N]: " reply
  [[ "${reply:-}" =~ ^[Yy]$ ]]
}

ensure_sh_executable() {
  local tool_path="$1"
  local tool_dir
  tool_dir="$(cd "$(dirname "$tool_path")" && pwd)"

  if [[ -f "$tool_path" && ! -x "$tool_path" ]]; then
    chmod +x "$tool_path"
  fi

  # Also chmod other .sh files in the same directory to avoid missing helpers
  shopt -s nullglob
  local sh_files=("$tool_dir"/*.sh)
  if [[ ${#sh_files[@]} -gt 0 ]]; then
    chmod +x "${sh_files[@]}"
  fi
  shopt -u nullglob
}

find_requirements_file() {
  local tool_dir="$1"
  if [[ -f "$tool_dir/requirements.txt" ]]; then
    echo "$tool_dir/requirements.txt"
    return 0
  fi
  if [[ -f "$tool_dir/req.txt" ]]; then
    echo "$tool_dir/req.txt"
    return 0
  fi
  return 1
}

print_venv_instructions() {
  local tool_dir="$1"
  local req_file="$2"
  local script_path="$3"
  echo "${YELLOW}Requirements file detected.${RESET}"
  echo "To keep things clean, open a NEW terminal tab and run:"
  echo
  echo "  cd \"$tool_dir\""
  echo "  python3 -m venv .venv"
  echo "  source .venv/bin/activate"
  echo "  python3 -m pip install -r \"$(basename "$req_file")\""
  echo "  python3 \"$(basename "$script_path")\" <args>"
  echo
  echo "This dashboard will not run the script automatically when requirements exist."
}

ensure_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    echo "python"
    return 0
  fi
  echo ""
  return 1
}

print_python_install_help() {
  echo "${YELLOW}Python is not installed.${RESET}"
  echo "On Kali, you can install it with:"
  echo "  sudo apt update"
  echo "  sudo apt install -y python3 python3-venv python3-pip"
}

print_password_evaluator_help() {
  local tool_dir="$BASE_DIR/password-evaluator"
  echo "${YELLOW}Password Evaluator uses an AWK script.${RESET}"
  echo "Run this in a terminal (adjust paths):"
  echo
  echo "  awk -f \"$tool_dir/evaluator.awk\" /path/to/passwords.txt > passwords_evaluation.txt"
  echo
  echo "To output only strong passwords:"
  echo "  awk -f \"$tool_dir/evaluator.awk\" /path/to/passwords.txt | grep \"Weak password\""
}

prompt_args() {
  local tool_name="$1"
  echo "Enter arguments for ${tool_name} (space-separated). Leave blank for none."
  read -r args
  echo "$args"
}

run_with_sudo_if_needed() {
  local needs_sudo="$1"
  shift
  if [[ "$needs_sudo" == "true" ]]; then
    if ask_yes_no "This action needs sudo. Continue?"; then
      sudo "$@"
    else
      echo "Canceled."
    fi
  else
    "$@"
  fi
}

run_sh_tool() {
  local tool_name="$1"
  local tool_path="$2"
  local needs_sudo="$3"
  local tool_dir
  tool_dir="$(cd "$(dirname "$tool_path")" && pwd)"

  ensure_sh_executable "$tool_path"

  local args
  args="$(prompt_args "$tool_name")"
  (
    cd "$tool_dir" || exit 1
    if [[ -n "$args" ]]; then
      # Respect quoted arguments by letting bash parse them.
      # This is interactive user input, so we keep it flexible.
      # shellcheck disable=SC2086
      eval "set -- $args"
      run_with_sudo_if_needed "$needs_sudo" bash "$tool_path" "$@"
    else
      run_with_sudo_if_needed "$needs_sudo" bash "$tool_path"
    fi
  )
}

run_py_tool() {
  local tool_name="$1"
  local tool_path="$2"
  local needs_sudo="$3"
  local tool_dir
  tool_dir="$(cd "$(dirname "$tool_path")" && pwd)"

  local req_file=""
  if req_file="$(find_requirements_file "$tool_dir")"; then
    print_venv_instructions "$tool_dir" "$req_file" "$tool_path"
    return 0
  fi

  local python_bin
  python_bin="$(ensure_python)"
  if [[ -z "$python_bin" ]]; then
    print_python_install_help
    return 1
  fi

  local args
  args="$(prompt_args "$tool_name")"
  (
    cd "$tool_dir" || exit 1
    if [[ -n "$args" ]]; then
      read -r -a _args <<< "$args"
      run_with_sudo_if_needed "$needs_sudo" "$python_bin" "$tool_path" "${_args[@]}"
    else
      run_with_sudo_if_needed "$needs_sudo" "$python_bin" "$tool_path"
    fi
  )
}

install_terminator() {
  echo "This will install Terminator using apt."
  if ask_yes_no "Proceed with installation?"; then
    sudo apt update
    sudo apt install -y terminator
  else
    echo "Canceled."
  fi
}

menu_fresh_install() {
  while true; do
    print_header
    echo "${BOLD}Fresh Install Essentials${RESET}"
    echo "1. Install Terminator (recommended)"
    echo "2. Run Initial Configure Script"
    echo "3. Back"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) install_terminator; pause ;;
      2) run_sh_tool "Initial Configure" "$BASE_DIR/configure/configure.sh" "true"; pause ;;
      3) return ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

menu_recon_domains() {
  while true; do
    print_header
    echo "${BOLD}Recon & Domains${RESET}"
    echo "1. Recon with MassDNS"
    echo "2. Domain Tree Visualization"
    echo "3. Sort Domains"
    echo "4. Advanced Sort Domains"
    echo "5. Separate Domains by Main Domain"
    echo "6. Split Domains by HTTP Status"
    echo "7. Domain Iteration Generator"
    echo "8. Port Lookup"
    echo "9. Back"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) run_sh_tool "Recon with MassDNS" "$BASE_DIR/recon-massdns/recon-massdns.sh" "false"; pause ;;
      2) run_sh_tool "Domain Tree" "$BASE_DIR/domain_tree/domain_tree.sh" "false"; pause ;;
      3) run_sh_tool "Sort Domains" "$BASE_DIR/sort_domains/sort_domains.sh" "false"; pause ;;
      4) run_sh_tool "Advanced Sort Domains" "$BASE_DIR/sort_domains/adv_sort_domains.sh" "false"; pause ;;
      5) run_sh_tool "Separate Domains" "$BASE_DIR/domains_separate/separate.sh" "false"; pause ;;
      6) run_sh_tool "Split Domains by Status" "$BASE_DIR/status_split/split.sh" "false"; pause ;;
      7) run_sh_tool "Domain Iteration Generator" "$BASE_DIR/iterate/iterate.sh" "false"; pause ;;
      8) run_sh_tool "Port Lookup" "$BASE_DIR/port_lookup/port_lookup.sh" "false"; pause ;;
      9) return ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

menu_web_tools() {
  while true; do
    print_header
    echo "${BOLD}Web & HTTP Tools${RESET}"
    echo "1. Python Web Server"
    echo "2. Redirector (Bypass IP Filters)"
    echo "3. Weasy PDF Payload Reader"
    echo "4. Wfuzz Analyzer"
    echo "5. cURL Login Bruteforce"
    echo "6. Python Login Bruteforce (choose version)"
    echo "7. Webshell Race Condition (antirace.py)"
    echo "8. Back"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) run_py_tool "Python Web Server" "$BASE_DIR/python_server/serve.py" "false"; pause ;;
      2) run_py_tool "Redirector" "$BASE_DIR/redirector/redirector.py" "false"; pause ;;
      3) run_py_tool "Weasy PDF Payload Reader" "$BASE_DIR/weasy/weasy.py" "false"; pause ;;
      4) run_sh_tool "Wfuzz Analyzer" "$BASE_DIR/wfuzz-analyzer/analyze.sh" "false"; pause ;;
      5) run_sh_tool "cURL Login Bruteforce" "$BASE_DIR/login-bruteforce/login-bruteforce.sh" "false"; pause ;;
      6) menu_py_login_bruteforce ;;
      7) run_py_tool "Webshell Race Condition" "$BASE_DIR/py-webshell-race-condition/antirace.py" "false"; pause ;;
      8) return ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

menu_py_login_bruteforce() {
  while true; do
    print_header
    echo "${BOLD}Python Login Bruteforce${RESET}"
    echo "Requirements file exists in this folder. The dashboard will print venv instructions."
    echo "1. v1.py"
    echo "2. v2.py"
    echo "3. v3.py"
    echo "4. v4-xforward-4.py"
    echo "5. v5-bypass-ipblock.py"
    echo "6. v6-enumetare-user.py"
    echo "7. v7-2auth.py"
    echo "8. v8-steps-2auth.py"
    echo "9. v9-staylogged-cookie.py"
    echo "10. v10-bruteforce-pass-change.py"
    echo "11. v11-sign-overflow.py"
    echo "12. v12-infinity-money.py"
    echo "13. v13-generate-pass-mutation-graphql.py"
    echo "14. Back"
    echo
    read -r -p "Choose a version: " choice
    case "$choice" in
      1) run_py_tool "v1.py" "$BASE_DIR/py-login-bruteforce/v1.py" "false"; pause ;;
      2) run_py_tool "v2.py" "$BASE_DIR/py-login-bruteforce/v2.py" "false"; pause ;;
      3) run_py_tool "v3.py" "$BASE_DIR/py-login-bruteforce/v3.py" "false"; pause ;;
      4) run_py_tool "v4-xforward-4.py" "$BASE_DIR/py-login-bruteforce/v4-xforward-4.py" "false"; pause ;;
      5) run_py_tool "v5-bypass-ipblock.py" "$BASE_DIR/py-login-bruteforce/v5-bypass-ipblock.py" "false"; pause ;;
      6) run_py_tool "v6-enumetare-user.py" "$BASE_DIR/py-login-bruteforce/v6-enumetare-user.py" "false"; pause ;;
      7) run_py_tool "v7-2auth.py" "$BASE_DIR/py-login-bruteforce/v7-2auth.py" "false"; pause ;;
      8) run_py_tool "v8-steps-2auth.py" "$BASE_DIR/py-login-bruteforce/v8-steps-2auth.py" "false"; pause ;;
      9) run_py_tool "v9-staylogged-cookie.py" "$BASE_DIR/py-login-bruteforce/v9-staylogged-cookie.py" "false"; pause ;;
      10) run_py_tool "v10-bruteforce-pass-change.py" "$BASE_DIR/py-login-bruteforce/v10-bruteforce-pass-change.py" "false"; pause ;;
      11) run_py_tool "v11-sign-overflow.py" "$BASE_DIR/py-login-bruteforce/v11-sign-overflow.py" "false"; pause ;;
      12) run_py_tool "v12-infinity-money.py" "$BASE_DIR/py-login-bruteforce/v12-infinity-money.py" "false"; pause ;;
      13) run_py_tool "v13-generate-pass-mutation-graphql.py" "$BASE_DIR/py-login-bruteforce/v13-generate-pass-mutation-graphql.py" "false"; pause ;;
      14) return ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

menu_system_tools() {
  while true; do
    print_header
    echo "${BOLD}System & Utilities${RESET}"
    echo "1. Backup Script (cron-compatible)"
    echo "2. File Manager (manager)"
    echo "3. Bash to PowerShell Translator"
    echo "4. IP Generator"
    echo "5. Password Generator"
    echo "6. Password Evaluator (instructions)"
    echo "7. Regenerate Machine ID (sudo)"
    echo "8. Change Hostname (sudo)"
    echo "9. Monitor Mode (sudo)"
    echo "10. Unmonitor Mode (sudo)"
    echo "11. Offline MAC Research"
    echo "12. Find Local IP from MAC"
    echo "13. RedHCP (sudo)"
    echo "14. DIOS (SQLi Payload Generator)"
    echo "15. Obfuscate Python Script"
    echo "16. Deobfuscate Python Script"
    echo "17. Crack ZIP"
    echo "18. Test XRCP (test.sh)"
    echo "19. Test XRCP (test2.sh)"
    echo "20. Back"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) run_sh_tool "Backup Script" "$BASE_DIR/backup-script-work-with-crontab/backup.sh" "false"; pause ;;
      2) run_sh_tool "File Manager" "$BASE_DIR/files-manager-script/manager.sh" "false"; pause ;;
      3) run_sh_tool "Bash2PowerShell Translator" "$BASE_DIR/basic-bash2powershell-translator/basictranslator.sh" "false"; pause ;;
      4) run_sh_tool "IP Generator" "$BASE_DIR/ipgen/ipgen.sh" "false"; pause ;;
      5) run_sh_tool "Password Generator" "$BASE_DIR/password-generator/generator.sh" "false"; pause ;;
      6) print_password_evaluator_help; pause ;;
      7) run_sh_tool "Regenerate Machine ID" "$BASE_DIR/machine-id-regenaration/re.sh" "true"; pause ;;
      8) run_sh_tool "Change Hostname" "$BASE_DIR/hostname-change/change.sh" "true"; pause ;;
      9) run_sh_tool "Monitor Mode" "$BASE_DIR/monitor/monitor.sh" "true"; pause ;;
      10) run_sh_tool "Unmonitor Mode" "$BASE_DIR/monitor/unmonitor.sh" "true"; pause ;;
      11) run_sh_tool "Offline MAC Research" "$BASE_DIR/offline-mac-research/search.sh" "false"; pause ;;
      12) run_sh_tool "Find Local IP from MAC" "$BASE_DIR/search-local-ip-from-mac/search.sh" "false"; pause ;;
      13) run_sh_tool "RedHCP" "$BASE_DIR/redhcp/redehcp.sh" "true"; pause ;;
      14) run_sh_tool "DIOS" "$BASE_DIR/dios-ascii-hex/dios.sh" "false"; pause ;;
      15) run_py_tool "Obfuscate Python Script" "$BASE_DIR/obfs_python/obfs.py" "false"; pause ;;
      16) run_py_tool "Deobfuscate Python Script" "$BASE_DIR/obfs_python/deobfs.py" "false"; pause ;;
      17) run_sh_tool "Crack ZIP" "$BASE_DIR/crackzip/crackzip.sh" "false"; pause ;;
      18) run_sh_tool "Test XRCP" "$BASE_DIR/test_xrpc/test.sh" "false"; pause ;;
      19) run_sh_tool "Test XRCP 2" "$BASE_DIR/test_xrpc/test2.sh" "false"; pause ;;
      20) return ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

main_menu() {
  while true; do
    print_header
    echo "${BOLD}Main Menu${RESET}"
    echo "1. Fresh Install Essentials"
    echo "2. Recon & Domains"
    echo "3. Web & HTTP Tools"
    echo "4. System & Utilities"
    echo "5. Internet Ownership (ASN Lab)"
    echo "6. Exit"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) menu_fresh_install ;;
      2) menu_recon_domains ;;
      3) menu_web_tools ;;
      4) menu_system_tools ;;
      5) menu_internet_ownership ;;
      6) exit 0 ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

menu_internet_ownership() {
  while true; do
    print_header
    echo "${BOLD}Internet Ownership (ASN Lab)${RESET}"
    echo "Goal: Build ASN expansion pipeline (CIDRs -> targets.txt)"
    echo "1. ASN Expansion Pipeline"
    echo "2. Back"
    echo
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) run_asn_expand_tool; pause ;;
      2) return ;;
      *) echo "Invalid choice."; pause ;;
    esac
  done
}

run_asn_expand_tool() {
  local tool_path="$BASE_DIR/internet-ownership/asn_expand.sh"
  ensure_sh_executable "$tool_path"

  echo "${BOLD}ASN Expansion Pipeline Helper${RESET}"
  echo "Example ASNs: AS13335,AS15169"
  read -r -p "Enter ASN list (comma-separated): " asn_list
  if [[ -z "${asn_list// }" ]]; then
    echo "No ASN list provided. Try again with something like: AS13335,AS15169"
    return 0
  fi

  local use_bgphe="false"
  local use_ipinfo="false"
  local ipinfo_token=""
  local no_expand="false"

  if ask_yes_no "Use bgp.he.net (best-effort HTML parsing)?"; then
    use_bgphe="true"
  fi
  if ask_yes_no "Use ipinfo (requires token)?"; then
    use_ipinfo="true"
    read -r -p "Enter ipinfo token: " ipinfo_token
  fi
  if ask_yes_no "Skip IP expansion (CIDRs only)?"; then
    no_expand="true"
  fi

  local args=("-a" "$asn_list")
  if [[ "$use_bgphe" == "true" ]]; then
    args+=("--use-bgphe")
  fi
  if [[ "$use_ipinfo" == "true" && -n "$ipinfo_token" ]]; then
    args+=("--use-ipinfo" "--ipinfo-token" "$ipinfo_token")
  fi
  if [[ "$no_expand" == "true" ]]; then
    args+=("--no-expand")
  fi

  run_with_sudo_if_needed "false" bash "$tool_path" "${args[@]}"
}

main_menu
