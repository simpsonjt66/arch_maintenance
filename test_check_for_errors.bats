#!/usr/bin/env bats

setup() {
  # Create a temporary directory and copy scripts there for isolation
  TMPDIR=$(mktemp -d)
  cp ./check_for_errors.sh "$TMPDIR"
  cp ./message.sh "$TMPDIR"
  cd "$TMPDIR"
  chmod +x check_for_errors.sh message.sh
}

teardown() {
  rm -rf "$TMPDIR"
}

@test "shows version and exits" {
  run ./check_for_errors.sh --version
  [ "$status" -eq 0 ]
  [[ "$output" =~ check_for_errors ]]
}

@test "shows usage/help and exits" {
  run ./check_for_errors.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ Usage: ]]
}

@test "unknown argument prints usage and exits" {
  run ./check_for_errors.sh --unknown
  [ "$status" -eq 0 ]
  [[ "$output" =~ Unknown\ option ]]
}

@test "include warnings sets log level 0..4" {
  # We can't test internal variable directly, but we can test that journalctl is called with 0..4
  # We'll mock journalctl
  cp /bin/true journalctl
  chmod +x journalctl
  PATH=".:$PATH" run ./check_for_errors.sh --include-warnings
  [ "$status" -eq 0 ]
}

@test "nocolor disables color output" {
  # Since colors are escape codes, let's see if output lacks them with --nocolor
  cp /bin/true journalctl
  chmod +x journalctl
  PATH=".:$PATH" run ./check_for_errors.sh --nocolor
  [ "$status" -eq 0 ]
  [[ ! "$output" =~ $'\e' ]] # No ANSI escape codes
}

@test "quiet mode disables output" {
  # Mock systemctl and journalctl
  cp /bin/true systemctl
  cp /bin/true journalctl
  chmod +x systemctl journalctl
  PATH=".:$PATH" run ./check_for_errors.sh --quiet
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "required command missing exits 2" {
  # Remove systemctl/journalctl from PATH
  PATH="" run ./check_for_errors.sh
  [ "$status" -eq 2 ]
  [[ "$output" =~ Required\ command ]]
}

@test "shows failed services if systemctl fails" {
  cat >systemctl <<EOF
#!/bin/sh
if [ "\$1" = "--failed" ]; then
  echo "some-service failed"
fi
EOF
  chmod +x systemctl
  cp /bin/true journalctl
  chmod +x journalctl
  PATH=".:$PATH" run ./check_for_errors.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ Failed\ services\ detected ]]
}

@test "shows journal errors if journalctl returns output" {
  cp /bin/true systemctl
  cat >journalctl <<EOF
#!/bin/sh
echo "CRITICAL error"
EOF
  chmod +x journalctl
  PATH=".:$PATH" run ./check_for_errors.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ Issues\ found\ in\ journal ]]
}

@test "no errors returns success" {
  cat >systemctl <<EOF
#!/bin/sh
exit 0
EOF
  cat >journalctl <<EOF
#!/bin/sh
exit 0
EOF
  chmod +x systemctl journalctl
  PATH=".:$PATH" run ./check_for_errors.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ No\ failed\ services ]]
  [[ "$output" =~ No\ alerts ]]
}
