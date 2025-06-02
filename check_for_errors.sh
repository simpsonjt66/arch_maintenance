#!/bin/bash

EXIT_CODE=0

# Check required commands
for cmd in systemctl journalctl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Required command '$cmd' not found. Exiting"
    exit 2
  fi
done

# Check for failed systemd services
echo "=== $(date): Checking for failed systemd services ==="
FAILED_SERVICES=$(systemctl --failed --no-legend)

if [[ -n "$FAILED_SERVICES" ]]; then
  echo "❌ Failed services detected:"
  echo "$FAILED_SERVICES"
  EXIT_CODE=1
else
  echo "✅ No failed services."
fi

echo ""

# Check journal for alerts, critical, errors, and for the current boot
# To add in warnings change 0..3 to 0..4
echo "=== $(date): Checking journal for ALERT, CRIT, and ERR messages (current boot) ==="
JOURNAL_OUTPUT=$(journalctl -p 0..3 -b -q --no-pager)

if [[ -n "$JOURNAL_OUTPUT" ]]; then
  echo "⚠️  Issues found in journal:"
  echo "$JOURNAL_OUTPUT"
  EXIT_CODE=1
else
  echo "✅ No alerts, or critical errors."
fi

echo ""

exit $EXIT_CODE
