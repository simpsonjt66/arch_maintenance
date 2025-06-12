#!/usr/bin/bash

colorize() {
  # prefer terminal safe colored and bold text when tput is supported
  if tput setaf 0 &>/dev/null; then
    ALL_OFF="$(tput sgr0)"
    BOLD="$(tput bold)"
    BLUE="${BOLD}$(tput setaf 4)"
    GREEN="${BOLD}$(tput setaf 2)"
    RED="${BOLD}$(tput setaf 1)"
    YELLOW="${BOLD}$(tput setaf 3)"
  else
    ALL_OFF="\e[0m"
    BOLD="\e[1m"
    BLUE="${BOLD}\e[34m"
    GREEN="${BOLD}\e[32m"
    RED="${BOLD}\e[31m"
    YELLOW="${BOLD}\e[33m"
  fi
  readonly ALL_OFF BOLD BLUE GREEN RED YELLOW
}

plain() {
  ((QUIET)) && return
  local mesg=$1
  shift
  printf "${BOLD}${mesg}${ALL_OFF}\n" "$@"
}

msg() {
  ((QUIET)) && return
  local mesg=$1
  shift
  printf "${GREEN}${BOLD}${mesg}${ALL_OFF}\n" "$@"
}

msg2() {
  ((QUIET)) && return
  local mesg=$1
  shift
  printf "${BLUE}${BOLD}${mesg}${ALL_OFF}\n" "$@"
}

ask() {
  local mesg=$1
  shift
  printf "${BLUE}${BOLD}${mesg}${ALL_OFF}" "$@"
}

warning() {
  local mesg=$1
  shift
  printf "${YELLOW}${mesg}${ALL_OFF}\n" "$@"
}

error() {
  ((QUIET)) && return
  local mesg=$1
  shift
  printf "${RED}${mesg}${ALL_OFF}\n" "$@"
}
