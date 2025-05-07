#!/bin/bash
# Script to test mitmproxy with curl

# Start a container with mitmproxy running
echo "Starting a container with mitmproxy..."
docker run --rm -it -p 8080:8080 --name test-mitmproxy mitmproxy/mitmproxy:latest \
  mitmdump --listen-port 8080 --mode regular --ssl-insecure --set connection_strategy=lazy

# To test with curl, open a new terminal and run:
# curl -x http://localhost:8080 http://example.com
# curl -x http://localhost:8080 https://example.com --insecure