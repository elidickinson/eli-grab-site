#!/bin/sh
# Install curl-cffi
pip install curl-cffi

# Start mitmproxy with our addon
exec mitmdump --listen-port 8080 --mode regular --ssl-insecure --set connection_strategy=lazy --set block_global=false -s /mitmproxy_curl_cffi_addon.py "$@"