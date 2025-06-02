#!/bin/bash

EXIT_CODE=0

# Check for failed systemd services
echo "=== Checking for failed systemd services ==="
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
echo "=== Checking journal for ALERT, CRIT,  and ERR, messages (current boot) ==="
JOURNAL_OUTPUT=$(journalctl -p 0..3 -b --no-pager)

# Strip whitespace for comaprison
JOURNAL_OUTPUT_STRIPPED=$(echo "$JOURNAL_OUTPUT" | xargs)

if [[ -n "$JOURNAL_OUTPUT" && "$JOURNAL_OUTPUT_STRIPPED" != "-- No entries --" ]]; then
  echo "⚠️  Issues found in journal:"
  echo "$JOURNAL_OUTPUT"
  EXIT_CODE=1
else
  echo "✅ No alerts, critical errors, or warnings in journal."
fi

echo ""

exit $EXIT_CODE
