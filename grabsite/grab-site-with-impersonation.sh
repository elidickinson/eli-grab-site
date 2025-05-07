#!/bin/bash
# Wrapper script for grab-site with browser impersonation via mitmproxy

# Default values
IMPERSONATE="yes"
IMPERSONATE_TYPE="chrome"
PROXY_PORT=8080
ADDON_PATH="/home/grabsite/mitmproxy_curl_cffi_addon.py"
PROXY_PID=""
VERBOSE=""
VERIFY_SSL=""

# Function to clean up mitmproxy on exit
cleanup() {
    if [ -n "$PROXY_PID" ]; then
        echo "Stopping mitmproxy (PID: $PROXY_PID)..."
        kill $PROXY_PID
    fi
    exit 0
}

# Register the cleanup function for script exit
trap cleanup EXIT INT TERM

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-impersonate)
            IMPERSONATE="no"
            shift
            ;;
        --browser=*)
            IMPERSONATE_TYPE="${1#*=}"
            shift
            ;;
        --proxy-port=*)
            PROXY_PORT="${1#*=}"
            shift
            ;;
        --addon-path=*)
            ADDON_PATH="${1#*=}"
            shift
            ;;
        --verbose)
            VERBOSE="-v"
            shift
            ;;
        --secure)
            VERIFY_SSL="-s"
            shift
            ;;
        --help)
            echo "Usage: $0 [options] URL [grab-site options]"
            echo
            echo "Options:"
            echo "  --no-impersonate              Disable browser impersonation"
            echo "  --browser=TYPE                Set browser type to impersonate (default: chrome)"
            echo "  --proxy-port=PORT             Set mitmproxy port (default: 8080)"
            echo "  --addon-path=PATH             Path to mitmproxy addon (default: /home/grabsite/mitmproxy_curl_cffi_addon.py)"
            echo "  --verbose                     Enable verbose logging"
            echo "  --secure                      Verify SSL certificates"
            echo "  --help                        Show this help message"
            echo
            echo "All other options are passed directly to grab-site"
            exit 0
            ;;
        *)
            # Exit options parsing once we hit the URL or other grab-site options
            break
            ;;
    esac
done

# If no arguments left, show help
if [ $# -eq 0 ]; then
    $0 --help
    exit 1
fi

# If impersonation is enabled, start mitmproxy
if [ "$IMPERSONATE" = "yes" ]; then
    echo "Starting mitmproxy with $IMPERSONATE_TYPE browser impersonation on port $PROXY_PORT..."
    
    # Start mitmproxy in the background
    /home/grabsite/start-mitmproxy.sh -p "$PROXY_PORT" -a "$ADDON_PATH" -i "$IMPERSONATE_TYPE" $VERBOSE $VERIFY_SSL &
    PROXY_PID=$!
    
    # Give mitmproxy time to start
    sleep 3
    
    # Check if mitmproxy started successfully
    if ! kill -0 $PROXY_PID 2>/dev/null; then
        echo "Error: Failed to start mitmproxy. Exiting."
        PROXY_PID=""
        exit 1
    fi
    
    echo "Mitmproxy started successfully with PID: $PROXY_PID"
    
    # Configure grab-site to use the proxy
    ORIGINAL_ARGS=("$@")
    
    # Run grab-site with proxy settings through the Python 3.8 environment
    PYTHONWARNINGS=ignore \
    /home/grabsite/.venv/grabsite/bin/grab-site --wpull-args="--http-proxy=localhost:$PROXY_PORT --https-proxy=localhost:$PROXY_PORT --no-check-certificate" "${ORIGINAL_ARGS[@]}"
    
    RESULT=$?
    
    # Stop mitmproxy
    if [ -n "$PROXY_PID" ]; then
        echo "Stopping mitmproxy (PID: $PROXY_PID)..."
        kill $PROXY_PID
        PROXY_PID=""
    fi
    
    exit $RESULT
else
    # Run grab-site normally without proxy using the Python 3.8 environment
    exec /home/grabsite/.venv/grabsite/bin/grab-site "$@"
fi