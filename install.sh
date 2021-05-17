#!/bin/bash

# This script installs go-c8y-cli on your Linux, macOS or Windows computer.
# It should be run as root, and can be run directly from a GitHub
# release, for example as:
#
#   curl https://github.com/reubenmiller/go-c8y-cli/releases/download/v2.0.0/install.sh | sudo bash
#
# From github
#   git clone https://github.com/reubenmiller/go-c8y-cli-addons.git "$HOME/.go-c8y-cli"
#   sudo -E "$HOME/.go-c8y-cli/shell/install.sh"
#
#   # Or force downloading of the binary for another OS and architecture
#   sudo -E PLATFORM_TUPLE=windows_amd64 "$HOME/.go-c8y-cli/shell/install.sh"
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
GO_C8Y_CLI_VERSION=latest
CURL_AUTH_HEADER=
GITHUB_TOKEN=${GITHUB_TOKEN:-}
INSTALL_PATH=${INSTALL_PATH:-}
SUDO_USER=${SUDO_USER:-}
SCRIPT_DIR=$( dirname "$0" )

if [[ "$GITHUB_TOKEN" != "" ]]; then
  CURL_AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

CURL_USER_AGENT=${CURL_USER_AGENT:-go-c8y-cli-installer}

OS=
ARCH=
WORK_DIR=

PLATFORM_TUPLE=${PLATFORM_TUPLE:-}

error() {
  if [ $# != 0 ]; then
    echo -e "\033[0;31m""$@""\033[0m" >&2
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
  PLATFORM_TUPLE="${OS}_${ARCH}"
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
  type -p jq > /dev/null || fail "E_JQ_MISSING" "Please install jq(1)."
  type -p xargs > /dev/null || fail "E_XARGS_MISSING" "Please install xargs(1)."
}

set_install_path() {
  if [[ -n "$INSTALL_PATH" ]]; then
    return
  fi
  uid=`id -u`
  if [ "$uid" != 0 ]; then
    INSTALL_PATH="$HOME/bin"
  else
    INSTALL_PATH=/usr/local/bin
  fi
}

assert_uid_zero() {
  uid=`id -u`
  if [ "$uid" != 0 ]; then
    fail "E_UID_NONZERO" "go-c8y-cli install.sh must run as root; please try running with sudo or running\n\`curl <todo> | sudo bash\`."
  fi
}

get_latest_tag () {
  local resp=$( curl https://api.github.com/repos/$OWNER/$REPO/releases -H "Accept: application/vnd.github.v3+json" -H "$CURL_AUTH_HEADER" -sL )
  local tag_name=$( echo "$resp" | grep tag_name | head -1 | cut -d '"' -f 4 )
  local url=$( echo "$resp" | grep browser_download_url | grep releases | head -1 | cut -d '"' -f 4 )
  
  # tag can be different to actual tag name (i.e. draft releases)
  local browser_url="${url%/*}"
  local real_tag_name="${browser_url##*/}"
  echo "$tag_name $real_tag_name $browser_url"
}

get_architecture () {
  # if [[ $(command -v dpkg) ]]; then
  #   dpkg --print-architecture    
  # fi
  case "$( uname -m )" in
      x86_64|amd64)
        echo amd64;;
      i?86)
        echo i386;;
      armv5)
        echo "armv5";;
      armv6)
        echo "armv6";;
      armv7)
        echo "armv7";;
      arm*)
        echo "arm64";;
    esac
}

get_os () {
  local osname="linux"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    osname=linux
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    osname=macOS
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

install_binary () {
  bold="\033[1m"
  normal="\033[0m"
  red="\033[31m"
  green="\033[32m"

  VERSION=${1:-latest}

  current_version=
  if [[ $(command -v c8y) ]]; then
    # TODO: Check if the c8y command is really a binary, if not then delete it

    current_version=$( c8y version --select version --output csv 2> /dev/null || true | tail -1 )
    if [[ "$current_version" == "" ]]; then
      current_version=$( c8y version 2> /dev/null | tail -1 | cut -d'-' -f1 | xargs )
    fi
  fi
  # echo "Getting latest version"

  RELEASE_BASE_URL="https://github.com/$OWNER/$REPO/releases/download/$VERSION"
  if [[ "$VERSION" == "latest" ]]; then
    local LATEST_VERSION=$( get_latest_tag )
    VERSION=$( echo "$LATEST_VERSION" | cut -d ' ' -f 1 )
    TAG=$( echo "$LATEST_VERSION" | cut -d ' ' -f 2 )
    RELEASE_BASE_URL=$( echo "$LATEST_VERSION" | cut -d ' ' -f 3 )
  fi

  if [[ "$VERSION" != "$TAG" ]]; then
    echo "Latest version: $VERSION (tag=$TAG)"
  else
    echo "Latest version: $TAG"
  fi

  if [[ "${current_version#v}" == "${VERSION#v}" ]]; then
    echo -e "${green}c8y is already up to date: ${VERSION}${normal}"
    return 0
  fi

  if [[ "$current_version" == "" ]]; then
    echo "installing $VERSION"
  else
    echo "updating from $current_version to $VERSION"
  fi

  install_binary_release $RELEASE_BASE_URL $VERSION $TAG

  if [[ ! ":$PATH:" == *":$INSTALL_PATH:"* ]]; then
    echo ""
    echo "*** WARNING ***"
    echo -e "\nThe PATH variable (\$PATH) is missing the install directory: $INSTALL_PATH\n\nPlease add it using\n\n    export PATH=$INSTALL_PATH:\$PATH\n\n"
  fi

  if [[ ! $(command -v c8y) ]]; then
    export PATH=${PATH}:$INSTALL_PATH
  fi

  # show new version
  "$INSTALL_PATH/c8y" version
}

install_binary_release() {
  # Get binary name based on os type
  local base_url=${1:-}
  local version=${2:-}
  local tag=${3:-}
  local PACKAGE="c8y_${version#v}_${PLATFORM_TUPLE}"
  local ARCHIVE="$PACKAGE.tar.gz"
  local BINARY_NAME="c8y"
  if [[ $PLATFORM_TUPLE == *"windows"* ]]; then
    ARCHIVE="$PACKAGE.zip"
    BINARY_NAME="c8y.exe"
  fi

  local URL="$base_url/$ARCHIVE"

  tmp=$( mktemp -d -t go-c8y-cli-XXXXXXXXXX )
  download_asset $TAG $ARCHIVE "$tmp/$ARCHIVE"
  
  tar zxf "$tmp/$ARCHIVE" -C "$tmp"

  echo "Installing c8y to $INSTALL_PATH"
  if [ "$(id -u)" != 0 ]; then
    # non-root
    [ -d "$INSTALL_PATH" ] || install -d "$INSTALL_PATH"
    install "$tmp/$PACKAGE/bin/"c8y* $INSTALL_PATH
  else
    # root
    [ -d "$INSTALL_PATH" ] || install -o 0 -g 0 -d "$INSTALL_PATH"
    install -o 0 -g 0 "$tmp/$PACKAGE/bin/"c8y* $INSTALL_PATH
  fi

  rm -Rf $tmp
}

download_asset () {
  local tag=${1:-}
  local FILE=${2:-}
  local ARCHIVE=${3:-}
  release_info=$( curl "https://api.github.com/repos/$OWNER/$REPO/releases/tags/$tag" -H "Accept: application/vnd.github.v3+json" -H "$CURL_AUTH_HEADER" -fsL )

  parser=".assets | map(select(.name == \"$FILE\"))[0].id"
  asset_id=$( echo "$release_info" | jq "$parser" )
  local URL="https://api.github.com/repos/$OWNER/$REPO/releases/assets/$asset_id"
  echo "Downloading:" $URL
  curl -A "$CURL_USER_AGENT" -H 'Accept: application/octet-stream' -H "$CURL_AUTH_HEADER" -fsL "$URL" > "$ARCHIVE"
}

install_addons () {
  git clone https://github.com/$OWNER/${ADDON_REPO}.git
}

install_profile_fish () {
  if ! command -v fish &> /dev/null; then
    return
  fi

  local profile="$HOME/.config/fish/config.fish"

  echo "adding fish plugin"
  mkdir -p "$HOME/.config/fish/"
  if [[ ! -f "$profile" ]]; then
    touch $profile

    if [[ -n "$SUDO_USER" ]]; then
      chown -R $SUDO_USER "$HOME/.config/fish/"
    fi
  fi

  local plugin_name=c8y.plugin.fish

  if [ -d "$HOME/.cumulocity" ]; then
    if ! grep -q "C8Y_SESSION_HOME" "$profile"; then
      echo "adding C8Y_SESSION_HOME variable to $profile"
      echo 'set -gx C8Y_SESSION_HOME "$HOME/.cumulocity"' >> "$profile"
    fi
  fi

  if ! grep -q "$plugin_name" "$profile"; then
    echo 'source "$HOME/.go-c8y-cli/shell/'"$plugin_name\"" >> "$HOME/.config/fish/config.fish"
  fi
}

install_profile_zsh () {
  if ! command -v zsh &> /dev/null; then
    return
  fi

  local profile="$HOME/.zshrc"
  local plugin_name=c8y.plugin.zsh

  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    # TODO: Handle vanilla zsh (without oh-my-zsh)
    local custom_completion="$HOME/.go-c8y-cli/completions-zsh"

    if [[ ! -d "$custom_completion" ]]; then
      mkdir -p "$custom_completion"
      if [[ -n "$SUDO_USER" ]]; then
        chown -R $SUDO_USER "$custom_completion"
      fi
    fi

    if [[ ! -f "$profile" ]]; then
      # create zshrc profile 
      touch "$profile"

      if [[ -n "$SUDO_USER" ]]; then
        chown -R $SUDO_USER "$profile"
      fi
    fi

    if ! grep -q "PROMPT=" "$profile"; then
      echo "PROMPT='%(?.%F{green}√.%F{red}?%?)%f %B%F{240}%1~%f%b %# '" >> "$profile"
    fi

    c8y completion zsh > "$custom_completion/_c8y"

    if ! grep -q "$plugin_name" "$profile"; then
      echo "fpath=($custom_completion \$fpath)" >> "$profile"
      
      echo "autoload -U compinit; compinit" >> "$profile"      
      echo 'source "$HOME/.go-c8y-cli/shell/'"$plugin_name\"" >> "$profile"
    fi

    if [ -d "$HOME/.cumulocity" ]; then
      if ! grep -q "C8Y_SESSION_HOME" "$profile"; then
        echo "adding C8Y_SESSION_HOME variable to $profile"
        echo 'export C8Y_SESSION_HOME="$HOME/.cumulocity"' >> "$profile"
      fi
    fi

    return
  fi
  
  echo "adding zsh plugin"

  if [ -d "$HOME/.cumulocity" ]; then
    if ! grep -q "C8Y_SESSION_HOME" "$profile"; then
      echo "adding C8Y_SESSION_HOME variable to $profile"
      echo 'export C8Y_SESSION_HOME="$HOME/.cumulocity"' >> "$profile"
    fi
  fi

  mkdir -p "$HOME/.oh-my-zsh/custom/plugins/c8y/"
  cp "$SCRIPT_DIR/shell/c8y.plugin.zsh" "$HOME/.oh-my-zsh/custom/plugins/c8y/"
  if [[ -n "$SUDO_USER" ]]; then
    chown -R $SUDO_USER "$HOME/.oh-my-zsh/custom/plugins/c8y/"
  fi

  if ! grep -q "c8y" "$profile"; then
    sed -iE 's/^plugins=(\(.*\))/plugins=(\1 c8y)/' $profile
  fi
}

install_profile_bash () {
  local profile="$HOME/.bashrc"
  local plugin_name=c8y.plugin.sh

  echo "adding bash plugin"
  if [ -d "$HOME/.cumulocity" ]; then
    if ! grep -q "C8Y_SESSION_HOME" "$profile"; then
      echo "adding C8Y_SESSION_HOME variable to $profile"
      echo 'export C8Y_SESSION_HOME="$HOME/.cumulocity"' >> "$profile"
    fi
  fi

  if ! grep -q $plugin_name $profile; then
    echo 'source "$HOME/.go-c8y-cli/shell/'"$plugin_name\"" >> "$profile"
  fi
}

assert_no_old_version () {
  if [[ -n $(command -v c8y) ]]; then

    if ! c8y version --select version --output csv 2> /dev/null > /dev/null; then
      c8y_path=$( which c8y )
      fail "E_INVALID_V1_VERSION" "an old version of c8y go-c8y-cli was detected. path=$c8y_path; please remove it and try again."
    fi
  fi
}

detect_platform
assert_dependencies
set_install_path
assert_no_old_version
install_binary
install_profile_bash
install_profile_zsh
install_profile_fish

}

_ "$0" "$@"
