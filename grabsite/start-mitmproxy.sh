#!/bin/bash
# Script to start mitmproxy with the curl_cffi addon

# Default values
PORT=8080
ADDON_PATH="/home/grabsite/mitmproxy_curl_cffi_addon.py"
IMPERSONATE="chrome"

# Parse command line arguments
while getopts "p:a:i:" opt; do
  case $opt in
    p) PORT="$OPTARG" ;;
    a) ADDON_PATH="$OPTARG" ;;
    i) IMPERSONATE="$OPTARG" ;;
    *) echo "Usage: $0 [-p port] [-a addon_path] [-i impersonate_type]" >&2
       exit 1 ;;
  esac
done

# Ensure the addon exists
if [ ! -f "$ADDON_PATH" ]; then
  echo "Error: Addon file not found at $ADDON_PATH"
  exit 1
fi

# Copy the addon to the container if it's in volume path
if [[ "$ADDON_PATH" != "/home/grabsite/"* ]]; then
  cp "$ADDON_PATH" /home/grabsite/mitmproxy_curl_cffi_addon.py
  ADDON_PATH="/home/grabsite/mitmproxy_curl_cffi_addon.py"
fi

# Set the impersonation type in the addon file
sed -i "s/self.impersonate_browser = \"chrome\"/self.impersonate_browser = \"$IMPERSONATE\"/" "$ADDON_PATH"

# Start mitmproxy
echo "Starting mitmproxy on port $PORT with $IMPERSONATE browser impersonation..."
mitmdump -p "$PORT" -s "$ADDON_PATH" --set block_global=false --ssl-insecure