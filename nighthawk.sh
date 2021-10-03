#!/bin/sh

ROOT_DIR=${ROOT_DIR:-"$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )"}

set -eu

NIGHTHAWK_USERNAME=${NIGHTHAWK_USERNAME:-"admin"}
NIGHTHAWK_PASSWORD=${NIGHTHAWK_PASSWORD:-}

# Set this to 1 for more verbosity.
NIGHTHAWK_VERBOSE=${NIGHTHAWK_VERBOSE:-0}

usage() {
  # This uses the comments behind the options to show the help. Not extremly
  # correct, but effective and simple.
  echo "$0 is a binenv wrapper with following options:" && \
    grep "[[:space:]].)\ #" "$0" |
    sed 's/#//' |
    sed -r 's/([a-z])\)/-\1/'
  exit "${1:-0}"
}

while getopts "u:p:f:vh-" opt; do
  case "$opt" in
    u) # Username for administration login
      NIGHTHAWK_USERNAME=$OPTARG;;
    p) # Password for administrator user
      NIGHTHAWK_PASSWORD=$OPTARG;;
    f) # File containing password for administrator user
      NIGHTHAWK_PASSWORD=$(cat "$OPTARG");;
    v) # Turn on verbosity
      NIGHTHAWK_VERBOSE=1;;
    h)
      usage;;
    -)
      break;;
    *)
      usage 1;;
  esac
done
shift $((OPTIND-1))


_verbose() {
  if [ "$NIGHTHAWK_VERBOSE" = "1" ]; then
    printf %s\\n "$1" >&2
  fi
}

_error() {
  printf %s\\n "$1" >&2
  exit 1
}

_web() {
  _url=$1; shift
  _verbose "Requesting $_url"

  if command -v curl >&2 >/dev/null; then
    curl -sSL -u "${NIGHTHAWK_USERNAME}:${NIGHTHAWK_PASSWORD}" "$@" "$_url"
  elif command -v wget >&2 >/dev/null; then
    wget -q -O - --header "Authorization: Basic $(printf %s:%s\\n "$NIGHTHAWK_USERNAME" "$NIGHTHAWK_PASSWORD" | base64)" "$@" "$_url"
  else
    _error "Can neither find curl, nor wget for downloading"
  fi
}

_post() {
  _url=$1; _dta=$2; shift 2
  _verbose "POSTing $_dta to $_url"
  if command -v curl >&2 >/dev/null; then
    _web "$_url" -F "$_dta" "$@"
  elif command -v wget >&2 >/dev/null; then
    _web "$_url" --post-data "$_dta" "$@"
  else
    _error "Can neither find curl, nor wget for downloading"
  fi
}


reboot() {
  _verbose "Logging in at $1"
  _web "$1" --header "Referer: ${1%/}/" >/dev/null
  _verbose "Discovering session at $1"
  dst=$(  _web "${1%/}/ADVANCED_home2.htm" |
            grep -E '<form.*action\s*=' |
            grep -Eo 'action\s*=\s*"[^"]+"' |
            sed -E -e 's/^action\s*=\s*"//' -e 's/"$//' )
  _verbose "Rebooting router at $1"
  _post "${1%/}/${dst}" \
      "buttonSelect=2" \
      --header "Referer: ${1%/}/ADVANCED_home2.htm" | grep -qi "progress"
}

if [ "$#" -lt "1" ]; then
  cmd=reboot
else
  cmd=$1
  shift
fi

case "$cmd" in
  reboot)
    [ "$#" -lt "1" ] && _error "Need at least the local URL to a rooter"
    for router; do
      if reboot "$router"; then
        _verbose "Router at $router restarted"
      else
        _error "Could not restart router at $router"
      fi
    done
    ;;
  h*)
    usage
    ;;

  *)
    _error "$1 is an unknown command, should be one of install, versions, distributions"
    ;;
esac
