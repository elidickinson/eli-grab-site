#!/bin/bash
# Wrapper script for grab-site with browser impersonation via standalone mitmproxy container

# Default values
PROXY_HOST="mitmproxy"
PROXY_PORT=8080
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --proxy-host=*)
            PROXY_HOST="${1#*=}"
            shift
            ;;
        --proxy-port=*)
            PROXY_PORT="${1#*=}"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options] URL [grab-site options]"
            echo
            echo "Options:"
            echo "  --proxy-host=HOST             Proxy host to use (default: mitmproxy)"
            echo "  --proxy-port=PORT             Proxy port to use (default: 8080)"
            echo "  --verbose                     Enable verbose logging"
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

# Configure verbose output
if [ "$VERBOSE" = true ]; then
    echo "Using mitmproxy at $PROXY_HOST:$PROXY_PORT for browser impersonation..."
fi

# Store original arguments
ORIGINAL_ARGS=("$@")

# Run grab-site with proxy settings
PYTHONWARNINGS=ignore \
grab-site --wpull-args="--http-proxy=$PROXY_HOST:$PROXY_PORT --https-proxy=$PROXY_HOST:$PROXY_PORT --no-check-certificate" "${ORIGINAL_ARGS[@]}"

exit $?