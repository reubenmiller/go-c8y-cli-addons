#!/bin/bash

# This script installs go-c8y-cli on your Linux or macOS computer.
# It should be run as root, and can be run directly from a GitHub
# release, for example as:
#
#   curl https://github.com/reubenmiller/go-c8y-cli/releases/download/v2.0.0/install.sh | sudo bash
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

PLATFORM_TUPLE=

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

assert_linux_or_macos() {
  OS=`uname`
  ARCH=`uname -m`
  if [ "$OS" != Linux -a "$OS" != Darwin ]; then
    fail "E_UNSUPPORTED_OS" "dolt install.sh only supports macOS and Linux."
  fi
  if [ "$ARCH" != x86_64 -a "$ARCH" != i386 -a "$ARCH" != i686 ]; then
    fail "E_UNSUPPOSED_ARCH" "dolt install.sh only supports installing dolt on x86_64 or x86."
  fi

  if [ "$OS" == Linux ]; then
    PLATFORM_TUPLE=linux
  else
    PLATFORM_TUPLE=darwin
  fi
  if [ "$ARCH" == x86_64 ]; then
    PLATFORM_TUPLE=$PLATFORM_TUPLE-amd64
  else
    PLATFORM_TUPLE=$PLATFORM_TUPLE-386
  fi
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

create_workdir() {
  WORK_DIR=`mktemp -d -t dolt-installer.XXXXXX`
  cleanup() {
    rm -rf "$WORK_DIR"
  }
  trap cleanup EXIT
  cd "$WORK_DIR"
}

install_binary_release() {
  local FILE=dolt-$PLATFORM_TUPLE.tar.gz
  local URL=$RELEASES_BASE_URL/$FILE
  echo "Downloading:" $URL
  curl -A "$CURL_USER_AGENT" -fsL "$URL" > "$FILE"
  tar zxf "$FILE"
  echo "Installing go-c8y-cli to /usr/local/bin."
  [ -d /usr/local/bin ] || install -o 0 -g 0 -d /usr/local/bin
  install -o 0 -g 0 dolt-$PLATFORM_TUPLE/bin/{c8y} /usr/local/bin
}

get-latest-tag () {
    curl https://api.github.com/repos/$OWNER/$REPO/releases/latest -H "Accept: application/vnd.github.v3+json" --silent | grep tag_name | cut -d '"' -f 4
}

c8y-update () {
    bold="\e[1m"
    normal="\e[0m"
    red="\e[31m"
    green="\e[32m"

    VERSION=${1:-latest}
    INSTALL_PATH=${2:-/usr/local/bin}

    if [ ! -d "$INSTALL_PATH" ]; then
        mkdir -p "$INSTALL_PATH"
    fi

    current_version=$(c8y version 2> /dev/null | tail -1)
    

    if [[ "$VERSION" = "latest" ]]; then
        VERSION=$( get-latest-tag )
    fi

    if [[ "$current_version" = "$VERSION" ]]; then
        echo "Already up to date"
        return
    fi

    # Get binary name based on os type
    BINARY_NAME=c8y.linux

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        BINARY_NAME=c8y.linux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        BINARY_NAME=c8y.macos
    elif [[ "$OSTYPE" == "cygwin" ]]; then
        BINARY_NAME=c8y.windows.exe
    elif [[ "$OSTYPE" == "msys" ]]; then
        BINARY_NAME=c8y.windows.exe
    elif [[ "$OSTYPE" == "linux"* ]]; then
        BINARY_NAME=c8y.linux
    else
        # assume windows
        BINARY_NAME=c8y.windows.exe
    fi

    # try to download latest c8y version
    echo -n "downloading ($BINARY_NAME)..."

    c8ytmp=./.c8y.tmp
    curl -A "$CURL_USER_AGENT" -fsL https://github.com/$OWNER/$REPO/releases/download/$VERSION/$BINARY_NAME -o $c8ytmp
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

    if [ "$current_version" = "$new_version"]; then
        echo -e "${green}c8y is already up to date: $(current_version)${normal}"
        return 0
    fi

    # show new version to user
    c8y version
}

install_addons () {
    git clone https://github.com/$OWNER/${ADDON_REPO}.git
}

assert_linux_or_macos
assert_dependencies
assert_uid_zero
create_workdir
c8y-update
# install_binary_release

}

_ "$0" "$@"
