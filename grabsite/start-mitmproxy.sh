#!/bin/bash
# Script to start mitmproxy with the curl_cffi addon

# Default values
PORT=8080
ADDON_PATH="/home/grabsite/mitmproxy_curl_cffi_addon.py"
IMPERSONATE="chrome"
VERBOSE=false
VERIFY_SSL=false

# Parse command line arguments
while getopts "p:a:i:vsh" opt; do
  case $opt in
    p) PORT="$OPTARG" ;;
    a) ADDON_PATH="$OPTARG" ;;
    i) IMPERSONATE="$OPTARG" ;;
    v) VERBOSE=true ;;
    s) VERIFY_SSL=true ;;
    h) echo "Usage: $0 [-p port] [-a addon_path] [-i impersonate_type] [-v] [-s]"
       echo "  -p PORT        Port for mitmproxy (default: 8080)"
       echo "  -a ADDON_PATH  Path to addon (default: /home/grabsite/mitmproxy_curl_cffi_addon.py)"
       echo "  -i IMPERSONATE Browser to impersonate (default: chrome)"
       echo "  -v             Enable verbose logging"
       echo "  -s             Verify SSL certificates"
       echo "  -h             Display this help message"
       exit 0 ;;
    *) echo "Usage: $0 [-p port] [-a addon_path] [-i impersonate_type] [-v] [-s]" >&2
       exit 1 ;;
  esac
done

# Ensure the addon exists
if [ ! -f "$ADDON_PATH" ]; then
  echo "Error: Addon file not found at $ADDON_PATH"
  exit 1
fi

# Set configuration options
if [ "$VERBOSE" = true ]; then
  VERBOSE_OPTION="--set verbose=true"
else
  VERBOSE_OPTION=""
fi

if [ "$VERIFY_SSL" = true ]; then
  SSL_OPTION="--set verify_ssl=true"
else
  SSL_OPTION="--ssl-insecure"
fi

# Start mitmproxy with Python 3.12 environment and the addon
echo "Starting mitmproxy on port $PORT with $IMPERSONATE browser impersonation..."
/home/grabsite/.venv/mitmproxy/bin/mitmdump \
  -p "$PORT" \
  -s "$ADDON_PATH" \
  --set block_global=false \
  --set impersonate_browser="$IMPERSONATE" \
  --set ssl_insecure=true \
  --set connection_strategy=lazy \
  --mode regular \
  $VERBOSE_OPTION \
  $SSL_OPTION