#!/usr/bin/env bash
set -euo pipefail

# KIRCT-focused Kali web-red-team baseline.
# Keeps kali-learning-scripts philosophy: simple, direct, repeatable.

PROFILE="core"
DRY_RUN=0
WITH_HEAVY=0
SKIP_UPGRADE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --profile=core) PROFILE="core" ;;
    --profile=extended) PROFILE="extended" ;;
    --with-heavy) WITH_HEAVY=1 ;;
    --skip-upgrade) SKIP_UPGRADE=1 ;;
    *)
      echo "[!] Unknown argument: $arg"
      echo "[i] Usage: ./kirct-web-profile.sh [--dry-run] [--profile=core|extended] [--with-heavy] [--skip-upgrade]"
      exit 1
      ;;
  esac
done

TS="$(date +%Y%m%d-%H%M%S)"
WORK_BASE="${HOME}/Desktop/targets"
KIRCT_BASE="${WORK_BASE}/kirct"
LOG_DIR="${KIRCT_BASE}/logs"
LOG_FILE="${LOG_DIR}/reach-kirct-web-${TS}.log"
PROFILE_FILE="${LOG_DIR}/kirct-web-profile-${TS}.txt"
GO_BIN="${HOME}/go/bin"

mkdir -p "${WORK_BASE}" "${KIRCT_BASE}" "${LOG_DIR}" "${GO_BIN}"

log() {
  echo "$1" | tee -a "${LOG_FILE}"
}

run_cmd() {
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "[DRY-RUN] $*"
    return 0
  fi
  log "[RUN] $*"
  eval "$@" 2>&1 | tee -a "${LOG_FILE}"
}

write_file() {
  local path="$1"
  shift || true
  if [[ "${DRY_RUN}" -eq 1 ]]; then
    log "[DRY-RUN] write ${path}"
    return 0
  fi
  printf "%s\n" "$@" > "${path}"
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
  run_cmd "sudo apt install -y ${pkg}"
}

pipx_has() {
  local name="$1"
  pipx list 2>/dev/null | grep -qiE "(^| )${name}( |$)"
}

pipx_install_if_missing() {
  local name="$1"
  local spec="$2"
  if ! command -v pipx >/dev/null 2>&1; then
    log "[SKIP] pipx package ${name} (pipx missing)"
    return 0
  fi
  if pipx_has "${name}"; then
    log "[SKIP] pipx ${name} (already installed)"
    return 0
  fi
  run_cmd "pipx install ${spec}"
}

go_tool_installed() {
  local bin_name="$1"
  command -v "${bin_name}" >/dev/null 2>&1 || [[ -x "${GO_BIN}/${bin_name}" ]]
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
  run_cmd "go install ${module}"
}

ensure_alias_line() {
  local alias_file="$1"
  local alias_key="$2"
  local alias_value="$3"
  run_cmd "touch \"${alias_file}\""
  run_cmd "grep -q \"alias ${alias_key}=\" \"${alias_file}\" || echo \"alias ${alias_key}='${alias_value}'\" >> \"${alias_file}\""
}

install_brain_wrappers() {
  local ops_dir="${KIRCT_BASE}/ops"
  run_cmd "mkdir -p \"${ops_dir}\""
  write_file "${ops_dir}/brain-note.sh" \
    "#!/usr/bin/env bash" \
    "set -euo pipefail" \
    "if [[ \$# -lt 1 ]]; then" \
    "  echo \"Usage: ./brain-note.sh <note text>\"" \
    "  exit 1" \
    "fi" \
    "kirct brain note \"\$*\""
  write_file "${ops_dir}/brain-ask.sh" \
    "#!/usr/bin/env bash" \
    "set -euo pipefail" \
    "if [[ \$# -lt 1 ]]; then" \
    "  echo \"Usage: ./brain-ask.sh <question text>\"" \
    "  exit 1" \
    "fi" \
    "kirct brain ask \"\$*\""
  run_cmd "chmod u+x \"${ops_dir}/brain-note.sh\" \"${ops_dir}/brain-ask.sh\""
}

log "[+] KIRCT Kali Web profile bootstrap"
log "[+] profile=${PROFILE} dry_run=${DRY_RUN} with_heavy=${WITH_HEAVY} skip_upgrade=${SKIP_UPGRADE}"
log "[+] log_file=${LOG_FILE}"

if [[ "${SKIP_UPGRADE}" -eq 0 ]]; then
  log "[+] Updating apt indexes / upgrading base system"
  run_cmd "sudo apt update -y"
  run_cmd "sudo apt full-upgrade -y"
fi

CORE_APT=(
  git curl wget jq unzip
  python3 python3-pip pipx
  golang-go
  nmap ffuf wfuzz sqlmap nuclei dirsearch subfinder httpx-toolkit
)

EXT_APT=(
  nikto zmap awscli httrack chromium
)

HEAVY_APT=(
  gvm
)

log "[+] Installing core web-red-team package set (idempotent)"
for pkg in "${CORE_APT[@]}"; do
  install_apt_if_missing "${pkg}"
done

if [[ "${PROFILE}" == "extended" ]]; then
  log "[+] Installing extended package set (idempotent)"
  for pkg in "${EXT_APT[@]}"; do
    install_apt_if_missing "${pkg}"
  done
fi

if [[ "${WITH_HEAVY}" -eq 1 ]]; then
  log "[+] Installing heavy package set (idempotent)"
  for pkg in "${HEAVY_APT[@]}"; do
    install_apt_if_missing "${pkg}"
  done
fi

log "[+] Ensuring pipx baseline utilities"
if command -v pipx >/dev/null 2>&1; then
  run_cmd "pipx ensurepath"
fi
pipx_install_if_missing "ghauri" "git+https://github.com/r0oth3x49/ghauri"
pipx_install_if_missing "interlace" "git+https://github.com/codingo/Interlace.git"

log "[+] Installing go-based web helpers (idempotent)"
go_install_if_missing "dalfox" "github.com/hahwul/dalfox/v2@latest"
go_install_if_missing "gau" "github.com/lc/gau/v2/cmd/gau@latest"
go_install_if_missing "katana" "github.com/projectdiscovery/katana/cmd/katana@latest"

log "[+] Preparing KIRCT working folders"
run_cmd "mkdir -p \"${KIRCT_BASE}/results/recon\" \"${KIRCT_BASE}/results/validation\" \"${KIRCT_BASE}/results/exploitation\" \"${KIRCT_BASE}/results/reporting\" \"${KIRCT_BASE}/wordlists\" \"${KIRCT_BASE}/loot\" \"${KIRCT_BASE}/brain\""

log "[+] Installing operator brain wrappers (non-blocking collaboration while KIRCT runs)"
install_brain_wrappers

log "[+] Optional shell aliases for repeatable web workflow"
ALIAS_FILE="${HOME}/.bash_aliases"
ensure_alias_line "${ALIAS_FILE}" "ktargets" "cd ${WORK_BASE}"
ensure_alias_line "${ALIAS_FILE}" "kkirct" "cd ${KIRCT_BASE}"

log "[+] Cleaning apt cache"
run_cmd "sudo apt autoremove -y || true"
run_cmd "sudo apt autoclean -y || true"
run_cmd "sudo apt clean -y || true"

if [[ "${DRY_RUN}" -eq 0 ]]; then
  {
    echo "timestamp=${TS}"
    echo "profile=${PROFILE}"
    echo "with_heavy=${WITH_HEAVY}"
    echo "skip_upgrade=${SKIP_UPGRADE}"
    echo "core_packages=${CORE_APT[*]}"
    echo "extended_packages=${EXT_APT[*]}"
    echo "heavy_packages=${HEAVY_APT[*]}"
    echo "workspace=${KIRCT_BASE}"
    echo "brain_wrappers=${KIRCT_BASE}/ops/brain-note.sh ${KIRCT_BASE}/ops/brain-ask.sh"
  } > "${PROFILE_FILE}"
  log "[+] Profile manifest saved: ${PROFILE_FILE}"
else
  log "[DRY-RUN] profile manifest skipped"
fi

log "[OK] KIRCT web profile configuration completed."
log "[i] Reload shell: source ~/.bashrc (or restart terminal)."
log "[i] Start workflow: cd ${KIRCT_BASE}"
