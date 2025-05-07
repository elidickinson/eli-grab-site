#!/bin/bash
# Script to run grab-site with Chrome browser impersonation via our custom proxy

# Default values
PROXY_PORT=8080
BROWSER_TYPE="chrome"
PROXY_PID=""
VERBOSE=""
ALLOW_INSECURE="--allow-insecure"

# Function to clean up proxy process on exit
cleanup() {
    if [ -n "$PROXY_PID" ]; then
        echo "Stopping browser proxy (PID: $PROXY_PID)..."
        kill $PROXY_PID
    fi
    exit 0
}

# Register the cleanup function for script exit
trap cleanup EXIT INT TERM

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --browser=*)
            BROWSER_TYPE="${1#*=}"
            shift
            ;;
        --proxy-port=*)
            PROXY_PORT="${1#*=}"
            shift
            ;;
        --verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --secure)
            ALLOW_INSECURE=""
            shift
            ;;
        --help)
            echo "Usage: $0 [options] grab-site-args..."
            echo
            echo "Options:"
            echo "  --browser=TYPE       Browser to impersonate (chrome, firefox, safari)"
            echo "  --proxy-port=PORT    Port for the browser proxy (default: 8080)"
            echo "  --verbose            Enable verbose logging for the proxy"
            echo "  --secure             Enable SSL verification (default: disabled)"
            echo "  --help               Show this help message"
            echo
            echo "All other arguments are passed directly to grab-site"
            echo
            echo "Examples:"
            echo "  $0 http://example.com"
            echo "  $0 --browser=firefox http://example.com --concurrency=3 --1"
            exit 0
            ;;
        *)
            # All other arguments will be passed to grab-site
            break
            ;;
    esac
done

# Check if there are any arguments left for grab-site
if [ $# -eq 0 ]; then
    echo "Error: No grab-site arguments provided"
    $0 --help
    exit 1
fi

echo "Starting browser impersonation proxy on port $PROXY_PORT..."
echo "Browser type: $BROWSER_TYPE"

# Start the proxy in the background
/home/grabsite/gs-venv/bin/python3.8 /home/grabsite/browser_proxy.py \
    --port $PROXY_PORT \
    --browser $BROWSER_TYPE \
    $VERBOSE \
    $ALLOW_INSECURE \
    &

PROXY_PID=$!

# Give the proxy time to start
sleep 2

# Check if proxy started successfully
if ! kill -0 $PROXY_PID 2>/dev/null; then
    echo "Error: Failed to start browser proxy. Exiting."
    PROXY_PID=""
    exit 1
fi

echo "Browser proxy started successfully with PID: $PROXY_PID"

# Configure grab-site to use our proxy
echo "Running grab-site through browser impersonation proxy..."
echo "Command: grab-site --wpull-args=\"--http-proxy=http://localhost:$PROXY_PORT\" $@"

# Run grab-site with wpull-args first to configure the proxy, then user arguments
grab-site --wpull-args="--http-proxy=http://localhost:$PROXY_PORT" "$@"

# Capture grab-site exit code
RESULT=$?

# Stop the proxy
if [ -n "$PROXY_PID" ]; then
    echo "Stopping browser proxy (PID: $PROXY_PID)..."
    kill $PROXY_PID
    PROXY_PID=""
fi

# Return grab-site exit code
exit $RESULT