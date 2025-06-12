#!/bin/bash
# set -euo pipefail

EXIT_CODE=0
LOG_LEVEL="0..3"
USE_COLOR='y'
QUIET=0

declare -r myname='pac_update'
declare -r myver='0.1'

source "./message.sh"

usage() {
  cat <<EOF
  ${myname} v${myver}

  Usage: $myname [options]

  General Options:
    -i, --include-warnings       Include warnings in Journal log
    -q, --quiet                  Silence text output
    -n, --nocolor                Do not colorize output
    -V, --version                Display version information
EOF
}

version() {
  printf "%s %s\n" "$myname" "$myver"
}

# Check required commands
check_for_commands() {
  for cmd in systemctl journalctl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "❌ Required command '$cmd' not found. Exiting"
      exit 2
    fi
  done
}

# Check for failed systemd services
check_for_errors() {

  if [[ -t 2 && $USE_COLOR != "n" ]]; then
    colorize
  else
    unset ALL_OFF BOLD BLUE GREEN RED YELLOW
  fi

  plain "=== $(date): Checking for failed systemd services ==="
  FAILED_SERVICES=$(systemctl --failed --no-legend)
  if [[ -n "$FAILED_SERVICES" ]]; then
    error "❌ Failed services detected:"
    plain "$FAILED_SERVICES"
    EXIT_CODE=1
  else
    msg "✅ No failed services."
  fi

  echo ""

  # Check journal for alerts, critical, errors, and for the current boot
  # To add in warnings change 0..3 to 0..4
  plain "=== $(date): Checking journal for ALERT, CRIT, and ERR messages (current boot) ==="
  JOURNAL_OUTPUT=$(journalctl -p "$LOG_LEVEL" -b -q --no-pager)
  if [[ -n "$JOURNAL_OUTPUT" ]]; then
    error "⚠️ Issues found in journal:"
    plain "$JOURNAL_OUTPUT"
    EXIT_CODE=1
  else
    msg "✅ No alerts, or critical errors."
  fi

  echo ""

  exit $EXIT_CODE
}

if [[ $# -eq 0 ]]; then
  check_for_errors
fi

while [[ "$1" ]]; do
  case "$1" in
  -V | --version)
    version
    exit 0
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -i | --include-warnings)
    LOG_LEVEL="0..4"
    ;;
  -q | --quiet)
    QUIET=1
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 0
    ;;
  esac
  shift
done

check_for_errors
