#!/bin/sh

ROOT_DIR=${ROOT_DIR:-"$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )"}

set -eu

# Username for the administrator at the router.
NIGHTHAWK_USERNAME=${NIGHTHAWK_USERNAME:-"admin"}

# Password for the administrator at the router. See command-line option -f to
# minimise password leakage at the host.
NIGHTHAWK_PASSWORD=${NIGHTHAWK_PASSWORD:-}

# Set this to 1 for more verbosity.
NIGHTHAWK_VERBOSE=${NIGHTHAWK_VERBOSE:-0}

# Binary/path to perform web operations, empty to discover (curl or wget, curl
# preferred)
NIGHTHAWK_WEBCLI=${NIGHTHAWK_WEBCLI:-}

NIGHTHAWK_PAGE_START=start.htm
NIGHTHAWK_PAGE_ADVANCED=ADVANCED_home2.htm

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

# Discover web CLI client when none was specified
_init() {
  if [ -z "$NIGHTHAWK_WEBCLI" ]; then
    if command -v curl >&2 >/dev/null; then
      NIGHTHAWK_WEBCLI=curl
    elif command -v wget >&2 >/dev/null; then
      NIGHTHAWK_WEBCLI=wget
    else
      _error "Can neither find curl, nor wget for Web operations"
    fi
  fi
}

_web() {
  _url=$1; shift
  _verbose "Requesting $_url"

  if printf %s\\n "$NIGHTHAWK_WEBCLI" | grep -q "curl"; then
    curl -sSL -u "${NIGHTHAWK_USERNAME}:${NIGHTHAWK_PASSWORD}" "$@" "$_url"
  elif printf %s\\n "$NIGHTHAWK_WEBCLI" | grep -q "wget"; then
    wget -q -O - --header "Authorization: Basic $(printf %s:%s\\n "$NIGHTHAWK_USERNAME" "$NIGHTHAWK_PASSWORD" | base64)" "$@" "$_url"
  else
    _error "Cannot understand type of Web CLI client at $NIGHTHAWK_WEBCLI"
  fi
}

_post() {
  _url=$1; _dta=$2; shift 2
  _verbose "POSTing $_dta to $_url"
  if printf %s\\n "$NIGHTHAWK_WEBCLI" | grep -q "curl"; then
    _web "$_url" -F "$_dta" "$@"
  elif printf %s\\n "$NIGHTHAWK_WEBCLI" | grep -q "wget"; then
    _web "$_url" --post-data "$_dta" "$@"
  else
    _error "Cannot understand type of Web CLI client at $NIGHTHAWK_WEBCLI"
  fi
}


reboot() {
  _verbose "Logging in at $1"
  _web "${1%/}/${NIGHTHAWK_PAGE_START}" --header "Referer: ${1%/}/" >/dev/null
  dst=$(  _web "${1%/}/${NIGHTHAWK_PAGE_ADVANCED}" |
            grep -E '<form.*action\s*=' |
            grep -Eo 'action\s*=\s*"[^"]+"' |
            sed -E -e 's/^action\s*=\s*"//' -e 's/"$//' )
  if printf %s\\n "$dst" | grep -q "adv"; then
    _verbose "Discovered form destination as $dst, rebooting"
    _post "${1%/}/${dst}" \
        "buttonSelect=2" \
        --header "Referer: ${1%/}/${NIGHTHAWK_PAGE_ADVANCED}" | grep -qi "progress"
  else
    _web "${1%/}/${NIGHTHAWK_PAGE_ADVANCED}"
    _error "Wrong form, authorised elsewhere?"
  fi
}

if [ "$#" -lt "1" ]; then
  cmd=reboot
else
  cmd=$1
  shift
fi

_init
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
