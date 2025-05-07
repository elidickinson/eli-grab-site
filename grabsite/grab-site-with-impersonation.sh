#!/bin/bash
# Wrapper script for grab-site with optional Chrome impersonation via mitmproxy

# Default values
IMPERSONATE=""
IMPERSONATE_TYPE="chrome"
PROXY_PORT=8080
ADDON_PATH="/home/grabsite/mitmproxy_curl_cffi_addon.py"
PROXY_PID=""

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
        --impersonate)
            IMPERSONATE="yes"
            shift
            ;;
        --impersonate-type)
            IMPERSONATE_TYPE="$2"
            shift 2
            ;;
        --proxy-port)
            PROXY_PORT="$2"
            shift 2
            ;;
        --addon-path)
            ADDON_PATH="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options] URL [grab-site options]"
            echo
            echo "Options:"
            echo "  --impersonate           Enable browser impersonation using mitmproxy"
            echo "  --impersonate-type TYPE Set impersonation type (default: chrome)"
            echo "  --proxy-port PORT       Set mitmproxy port (default: 8080)"
            echo "  --addon-path PATH       Path to mitmproxy addon (default: /home/grabsite/mitmproxy_curl_cffi_addon.py)"
            echo "  --help                  Show this help message"
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
    /home/grabsite/start-mitmproxy.sh -p $PROXY_PORT -a $ADDON_PATH -i $IMPERSONATE_TYPE &
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
    # Note: We save the original arguments to pass to grab-site
    ORIGINAL_ARGS=("$@")
    
    # Run grab-site with proxy settings
    HTTP_PROXY=http://localhost:$PROXY_PORT \
    HTTPS_PROXY=http://localhost:$PROXY_PORT \
    NO_PROXY="" \
    PYTHONWARNINGS=ignore \
    grab-site "${ORIGINAL_ARGS[@]}"
    
    RESULT=$?
    
    # Stop mitmproxy
    if [ -n "$PROXY_PID" ]; then
        echo "Stopping mitmproxy (PID: $PROXY_PID)..."
        kill $PROXY_PID
        PROXY_PID=""
    fi
    
    exit $RESULT
else
    # Run grab-site normally without proxy
    exec grab-site "$@"
fi