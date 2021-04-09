#!/bin/bash

# This script installs go-c8y-cli on your Linux, macOS or Windows computer.
# It should be run as root, and can be run directly from a GitHub
# release, for example as:
#
#   curl https://github.com/reubenmiller/go-c8y-cli/releases/download/v2.0.0/install.sh | sudo bash
#
# From github
#   git clone https://github.com/reubenmiller/go-c8y-cli-addons.git ~/.go-c8y-cli
#   ~/.go-c8y-cli/shell/install.sh
#
#   # Or force downloading of the binary for another OS and architecture
#   sudo PLATFORM_TUPLE=windows-amd64 ~/.go-c8y-cli/shell/install.sh
#
# All downloads occur over HTTPS from the Github releases page.

if test -z "$BASH_VERSION"; then
  echo "Please run this script using bash, not sh or any other shell." >&2
  exit 1
fi

_() {

set -euo pipefail

OWNER=reubenmiller
REPO=go-c8y-cli
ADDON_REPO=go-c8y-cli-addons
GO_C8Y_CLI_VERSION=0.25.1
RELEASES_BASE_URL=https://github.com/$OWNER/$REPO/releases/download/v"$GO_C8Y_CLI_VERSION"
INSTALL_URL=$RELEASES_BASE_URL/install.sh

CURL_USER_AGENT=${CURL_USER_AGENT:-go-c8y-cli-installer}

OS=
ARCH=
WORK_DIR=

PLATFORM_TUPLE=${PLATFORM_TUPLE:-}

error() {
  if [ $# != 0 ]; then
    echo -e "\e[0;31m""$@""\e[0m" >&2
  fi
}

fail() {
  local error_code="$1"
  shift
  echo "*** INSTALLATION FAILED ***" >&2
  echo "" >&2
  error "$@"
  echo "" >&2
  exit 1
}

detect_platform() {
  if [[ "$PLATFORM_TUPLE" != "" ]]; then
    return
  fi
  OS=$( get_os )
  ARCH=$( get_architecture )
  PLATFORM_TUPLE=$OS-$ARCH
}

assert_dependencies() {
  type -p curl > /dev/null || fail "E_CURL_MISSING" "Please install curl(1)."
  type -p tar > /dev/null || fail "E_TAR_MISSING" "Please install tar(1)."
  type -p uname > /dev/null || fail "E_UNAME_MISSING" "Please install uname(1)."
  type -p install > /dev/null || fail "E_INSTALL_MISSING" "Please install install(1)."
  type -p mktemp > /dev/null || fail "E_MKTEMP_MISSING" "Please install mktemp(1)."
  type -p grep > /dev/null || fail "E_GREP_MISSING" "Please install grep(1)."
  type -p cut > /dev/null || fail "E_CUT_MISSING" "Please install cut(1)."
  type -p git > /dev/null || fail "E_GIT_MISSING" "Please install git(1)."
}

assert_uid_zero() {
  uid=`id -u`
  if [ "$uid" != 0 ]; then
    fail "E_UID_NONZERO" "go-c8y-cli install.sh must run as root; please try running with sudo or running\n\`curl $INSTALL_URL | sudo bash\`."
  fi
}

get_latest_tag () {
    curl https://api.github.com/repos/$OWNER/$REPO/releases/latest -H "Accept: application/vnd.github.v3+json" --silent | grep tag_name | cut -d '"' -f 4
}

get_architecture () {
  if [[ $(command -v dpkg) ]]; then
    dpkg --print-architecture
  else
    case "$( uname -i )" in
      x86_64|amd64)
        echo amd64;;
      i?86)
        echo i386;;
      armv5|armv6|armv7)
        echo "armel";;
      arm*)
        echo "arm64";;
    esac
  fi
}

get_os () {
  local osname="linux"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      osname=linux
  elif [[ "$OSTYPE" == "darwin"* ]]; then
      osname=macos
  elif [[ "$OSTYPE" == "cygwin" ]]; then
      osname=windows
  elif [[ "$OSTYPE" == "msys" ]]; then
      osname=windows
  elif [[ "$OSTYPE" == "linux"* ]]; then
      osname=linux
  else
      # assume windows
      osname=windows
  fi
  echo $osname
}

install_c8y_binary () {
    bold="\e[1m"
    normal="\e[0m"
    red="\e[31m"
    green="\e[32m"

    VERSION=${1:-latest}
    INSTALL_PATH=${2:-/usr/local/bin}

    if [ ! -d "$INSTALL_PATH" ]; then
        mkdir -p "$INSTALL_PATH"
    fi

    current_version=
    if [[ $(command -v c8y) ]]; then
      current_version=$(c8y version 2> /dev/null | tail -1)
    fi

    if [[ "$VERSION" = "latest" ]]; then
        VERSION=$( get_latest_tag )
    fi

    if [[ "$current_version" = "$VERSION" ]]; then
        echo "Already up to date"
        return
    fi

    # Get binary name based on os type
    BINARY_SUFFIX=

    if [[ $PLATFORM_TUPLE == *"windows"* ]]; then
        BINARY_SUFFIX=".exe"
    fi

    BINARY_NAME="c8y.$PLATFORM_TUPLE$BINARY_SUFFIX"

    # try to download latest c8y version
    if [[ "$current_version" == "" ]]; then
      echo -n "downloading ($BINARY_NAME $VERSION)..."
    else
      echo -n "updating ($BINARY_NAME) from $current_version to $VERSION..."
    fi

    c8ytmp=./.c8y.tmp
    BINARY_URL="https://github.com/$OWNER/$REPO/releases/download/$VERSION/$BINARY_NAME"
    if curl -A "$CURL_USER_AGENT" -fsL $BINARY_URL -o $c8ytmp
    then
      echo -e "${green}OK${normal}"
    else
      echo -e "${red}ERROR\nURL: $BINARY_URL${normal}"
      return
    fi

    chmod +x $c8ytmp

    new_version=$($c8ytmp version 2>/dev/null | tail -1)

    if [ "$new_version" = "" ]; then
        if [[ $(cat $c8ytmp | head -1 | grep ELF) ]]; then
            echo -e "${red}Failed download latest version: err=Unknown binary error${normal}"
        else
            echo -e "${red}Failed download latest version: err=$(cat .c8y.tmp | head -1)${normal}"
        fi
        rm -f .c8y.tmp
        return 1
    else
        echo -e "${green}ok${normal}"
        mv $c8ytmp $INSTALL_PATH/c8y
    fi

    if [[ ! $(command -v c8y) ]]; then
        echo "Adding install path ($INSTALL_PATH) to PATH variable"
        export PATH=${PATH}:$INSTALL_PATH
    fi

    if [[ "$current_version" == "$new_version" ]]; then
        echo -e "${green}c8y is already up to date: ${current_version}${normal}"
        return 0
    fi

    # show new version to user
    c8y version
}

install_addons () {
    git clone https://github.com/$OWNER/${ADDON_REPO}.git
}

detect_platform
assert_dependencies
assert_uid_zero
install_c8y_binary

}

_ "$0" "$@"
