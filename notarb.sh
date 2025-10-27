#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

java_exe_path=""

install_java() {
  echo

  kernel=$(uname -s | tr '[:upper:]' '[:lower:]')

  if [[ "$kernel" == *"linux"* ]]; then
    os="linux"
  elif [[ "$kernel" == *"darwin"* ]]; then
    os="mac"
  else
    echo "Unsupported OS: $kernel"
    exit 1
  fi

  arch=$(uname -m | tr '[:upper:]' '[:lower:]')
  if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    arch="aarch64"
  else
    arch="x64"
  fi

  case "$os-$arch" in
  linux-aarch64)
    java_url="https://download.oracle.com/java/24/archive/jdk-24_linux-aarch64_bin.tar.gz"
    java_exe_path="jdk-24.0.2/bin/java"
    ;;
  linux-x64)
    java_url="https://download.oracle.com/java/24/archive/jdk-24_linux-x64_bin.tar.gz"
    java_exe_path="jdk-24.0.2/bin/java"
    ;;
  mac-aarch64)
    java_url="https://download.oracle.com/java/24/archive/jdk-24_macos-aarch64_bin.tar.gz"
    java_exe_path="jdk-24.0.2.jdk/Contents/Home/bin/java"
    ;;
  mac-x64)
    java_url="https://download.oracle.com/java/24/archive/jdk-24_macos-x64_bin.tar.gz"
    java_exe_path="jdk-24.0.2.jdk/Contents/Home/bin/java"
    ;;
  esac

  java_exe_path="$script_dir/$java_exe_path"

  if [ -f "$java_exe_path" ]; then
    "$java_exe_path" --version
    if [ $? -eq 0 ]; then
      echo "Java installation not required."
      return
    fi
    echo "Java exists but could not be ran, reinstalling..."
  else
    echo "Installing Java, please wait..."
  fi

  echo "$java_url"

  # Download and extract Java
  temp_file="$script_dir/java_download_temp.tar.gz"
  download_file "$java_url" "$temp_file"
  tar -xzf "$temp_file"
  rm -f "$temp_file"

  # Verify installed Java executable
  echo
  echo "Verifying Java installation..."
  "$java_exe_path" --version
  if [ $? -eq 0 ]; then
    echo "Java installation successful!"
  else
    echo "Warning: Java installation could not be verified!"
  fi
}

download_file() {
  local url="$1"
  local output="$2"

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -o "$output" "$url"
  else
    echo "Error: Neither wget nor curl is installed."
    exit 1
  fi
}

launch() {
  echo

  export NOTARB_LAUNCHER_SCRIPT_DIR="$script_dir"
  export NOTARB_LAUNCHER_CMD_FILE=$(mktemp)

  "$java_exe_path" -cp "notarb-launcher.jar" org.notarb.launcher.Main "$@"

  if [[ $? -eq 0 ]]; then
    cmd=$(cat "$NOTARB_LAUNCHER_CMD_FILE")
  fi

  rm -f "$NOTARB_LAUNCHER_CMD_FILE" || true

  if [[ $cmd ]]; then
    exec "$java_exe_path" $cmd
  fi
}

install_java
launch "$@"