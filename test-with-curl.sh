#!/bin/bash
# Script to test a proxy with curl

# Default values
PROXY_HOST="localhost"
PROXY_PORT="8080"
URL="https://example.com"
VERBOSE=false
INSECURE=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --proxy=*)
            PROXY="${1#*=}"
            # Split host:port
            PROXY_HOST=$(echo "$PROXY" | cut -d':' -f1)
            PROXY_PORT=$(echo "$PROXY" | cut -d':' -f2)
            shift
            ;;
        --url=*)
            URL="${1#*=}"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --secure)
            INSECURE=false
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --proxy=HOST:PORT  Proxy to use (default: localhost:8080)"
            echo "  --url=URL          URL to fetch (default: https://example.com)"
            echo "  --verbose          Enable verbose output"
            echo "  --secure           Enable SSL verification (default: disabled)"
            echo "  --help             Show this help message"
            echo
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Build curl command
CURL_CMD="curl -x ${PROXY_HOST}:${PROXY_PORT}"

if [ "$VERBOSE" = true ]; then
    CURL_CMD="$CURL_CMD -v"
fi

if [ "$INSECURE" = true ]; then
    CURL_CMD="$CURL_CMD --insecure"
fi

CURL_CMD="$CURL_CMD $URL"

# Run the curl command
echo "Testing proxy with curl..."
echo "Command: $CURL_CMD"
echo "-----------------------------------"

# Execute the command
eval "$CURL_CMD"
RESULT=$?

echo "-----------------------------------"
if [ $RESULT -eq 0 ]; then
    echo "Test succeeded!"
else
    echo "Test failed with exit code: $RESULT"
fi