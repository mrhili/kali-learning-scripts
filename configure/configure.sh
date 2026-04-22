#!/usr/bin/env bash
set -euo pipefail

# Classic kali-learning-scripts configure, now idempotent.
# If package/tool already exists, it is skipped.

DRY_RUN=0
SKIP_UPGRADE=0
SKIP_PASSWORDS=0
SKIP_GVM=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --skip-upgrade) SKIP_UPGRADE=1 ;;
    --skip-passwords) SKIP_PASSWORDS=1 ;;
    --skip-gvm) SKIP_GVM=1 ;;
    *)
      echo "[!] Unknown argument: $arg"
      echo "[i] Usage: ./configure.sh [--dry-run] [--skip-upgrade] [--skip-passwords] [--skip-gvm]"
      exit 1
      ;;
  esac
done

log() {
  echo "$1"
}

run_cmd() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "[DRY-RUN] $*"
    return 0
  fi
  eval "$@"
}

pkg_installed() {
  dpkg -s "$1" >/dev/null 2>&1
}

install_apt_if_missing() {
  local pkg="$1"
  local bin_name="${2:-}"
  if [[ -n "${bin_name}" ]] && command -v "${bin_name}" >/dev/null 2>&1; then
    log "[SKIP] ${pkg} (binary exists: ${bin_name})"
    return 0
  fi
  if pkg_installed "${pkg}"; then
    log "[SKIP] ${pkg} (already installed)"
    return 0
  fi
  log "[+] Installing ${pkg}"
  run_cmd "sudo apt install -y ${pkg}"
}

ensure_alias_line() {
  local alias_file="$1"
  local alias_key="$2"
  local alias_value="$3"
  run_cmd "touch \"${alias_file}\""
  run_cmd "grep -q \"alias ${alias_key}=\" \"${alias_file}\" || echo \"alias ${alias_key}='${alias_value}'\" >> \"${alias_file}\""
}

pipx_has() {
  local name="$1"
  pipx list 2>/dev/null | grep -qiE "(^| )${name}( |$)"
}

pipx_install_if_missing() {
  local name="$1"
  local spec="$2"
  if ! command -v pipx >/dev/null 2>&1; then
    log "[SKIP] pipx ${name} (pipx missing)"
    return 0
  fi
  if pipx_has "${name}"; then
    log "[SKIP] pipx ${name} (already installed)"
    return 0
  fi
  log "[+] Installing pipx ${name}"
  run_cmd "pipx install ${spec}"
}

go_tool_installed() {
  local bin_name="$1"
  command -v "${bin_name}" >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/${bin_name}" ]]
}

go_install_if_missing() {
  local bin_name="$1"
  local module="$2"
  if go_tool_installed "${bin_name}"; then
    log "[SKIP] go tool ${bin_name} (already installed)"
    return 0
  fi
  if ! command -v go >/dev/null 2>&1; then
    log "[SKIP] go install ${bin_name} (go missing)"
    return 0
  fi
  log "[+] Installing go tool ${bin_name}"
  run_cmd "go install ${module}"
}

log "[+] configure.sh (idempotent mode)"

if [[ "${SKIP_UPGRADE}" -eq 0 ]]; then
  log "[+] Update and upgrade machine"
  run_cmd "sudo apt update -y"
  run_cmd "sudo apt full-upgrade -y"
  log "[OK]"
else
  log "[SKIP] upgrade (--skip-upgrade)"
fi

headers_pkg="linux-headers-$(uname -r)"
log "[+] Installing headers if missing"
install_apt_if_missing "${headers_pkg}"

if [[ "${SKIP_PASSWORDS}" -eq 0 ]]; then
  log "[+] CHANGING CURRENT PASS (interactive)"
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    sudo passwd
  else
    log "[DRY-RUN] sudo passwd"
  fi
  log "[+] CHANGING ROOT PASS (interactive)"
  if [[ "${DRY_RUN}" -eq 0 ]]; then
    sudo passwd root
  else
    log "[DRY-RUN] sudo passwd root"
  fi
else
  log "[SKIP] password changes (--skip-passwords)"
fi

log "[+] CONFIGURING SHARING FOLDER (vboxsf group)"
if id -nG "$USER" | grep -qw vboxsf; then
  log "[SKIP] user already in vboxsf"
else
  run_cmd "sudo usermod -aG vboxsf ${USER}"
fi

log "[+] ZSH shell"
if command -v zsh >/dev/null 2>&1; then
  current_shell="$(getent passwd "${USER}" | awk -F: '{print $7}')"
  if [[ "${current_shell}" == *"/zsh" ]]; then
    log "[SKIP] zsh already default shell"
  else
    run_cmd "sudo chsh -s /bin/zsh ${USER}"
  fi
else
  install_apt_if_missing "zsh" "zsh"
  run_cmd "sudo chsh -s /bin/zsh ${USER}"
fi

APT_TOOLS=(
  pipx
  terminator
  bloodhound
  empire
  xsstrike
  nuclei
  dirsearch
  cmseek
  gitxray
  chisel
  rubeus
  paramspider
  arjun
  subfinder
  golang
  zmap
  awscli
  s3scanner
  httrack
)

for pkg in "${APT_TOOLS[@]}"; do
  install_apt_if_missing "${pkg}"
done

log "[+] Installing go tools if missing"
go_install_if_missing "dalfox" "github.com/hahwul/dalfox/v2@latest"
go_install_if_missing "gau" "github.com/lc/gau/v2/cmd/gau@latest"

log "[+] Installing kiterunner if missing"
if command -v kr >/dev/null 2>&1; then
  log "[SKIP] kiterunner already installed (kr exists)"
else
  run_cmd "mkdir -p \"${HOME}/Downloads/tools\""
  if [[ -d "${HOME}/Downloads/tools/kiterunner/.git" ]]; then
    run_cmd "(cd \"${HOME}/Downloads/tools/kiterunner\" && git pull --ff-only || true)"
  else
    run_cmd "git clone https://github.com/assetnote/kiterunner.git \"${HOME}/Downloads/tools/kiterunner\""
  fi
  run_cmd "(cd \"${HOME}/Downloads/tools/kiterunner\" && sudo make build)"
  run_cmd "sudo ln -sf \"${HOME}/Downloads/tools/kiterunner/dist/kr\" /usr/local/bin/kr"
fi

if command -v pipx >/dev/null 2>&1; then
  run_cmd "pipx ensurepath"
fi
pipx_install_if_missing "interlace" "git+https://github.com/codingo/Interlace.git"
pipx_install_if_missing "ghauri" "git+https://github.com/r0oth3x49/ghauri"

log "[+] Installing DorksEye if missing"
if [[ -f "${HOME}/Downloads/tools/dorks-eye/dorks-eye.py" ]]; then
  log "[SKIP] dorks-eye already present"
else
  run_cmd "mkdir -p \"${HOME}/Downloads/tools\""
  run_cmd "git clone https://github.com/BullsEye0/dorks-eye.git \"${HOME}/Downloads/tools/dorks-eye\""
  run_cmd "(cd \"${HOME}/Downloads/tools/dorks-eye\" && python3 -m venv env && ./env/bin/pip install -r requirements.txt)"
fi

ALIAS_FILE="${HOME}/.bash_aliases"
ensure_alias_line "${ALIAS_FILE}" "dorks-eye" "${HOME}/Downloads/tools/dorks-eye/env/bin/python ${HOME}/Downloads/tools/dorks-eye/dorks-eye.py"

if [[ "${SKIP_GVM}" -eq 0 ]]; then
  log "[+] INSTALLING GVM if missing"
  if pkg_installed "gvm"; then
    log "[SKIP] gvm package already installed"
  else
    run_cmd "sudo apt install -y gvm"
  fi
  if command -v gvm-check-setup >/dev/null 2>&1; then
    run_cmd "sudo gvm-check-setup || true"
  fi
else
  log "[SKIP] gvm (--skip-gvm)"
fi

log "[+] CLEANING"
run_cmd "sudo apt clean && sudo apt autoclean && sudo apt autoremove -y"
log "[OK]"
