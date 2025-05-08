"""
mitmproxy_curl_cffi_addon.py - A mitmproxy addon for browser impersonation using curl_cffi

This addon intercepts requests and processes them with curl_cffi with browser impersonation,
allowing for bypassing of anti-bot protections while using grab-site.
"""

from mitmproxy import http, ctx
import json
from curl_cffi import requests as curl_requests

class CurlCffiAddon:
    def __init__(self):
        self.impersonate_browser = "chrome"  # Default browser: chrome, firefox, safari
        self.verbose = False                  # Default to non-verbose mode
        ctx.log.info(f"CurlCffiAddon loaded with {self.impersonate_browser} impersonation")

    def configure(self, updates):
        # Allow configuration changes via mitmproxy options
        if "impersonate_browser" in ctx.options:
            self.impersonate_browser = ctx.options.impersonate_browser
            ctx.log.info(f"Set impersonation browser to: {self.impersonate_browser}")
            
        if "verbose" in ctx.options:
            self.verbose = ctx.options.verbose
            if self.verbose:
                ctx.log.info("Verbose mode enabled")

    def request(self, flow: http.HTTPFlow) -> None:
        # Skip CONNECT requests (HTTPS tunneling)
        if flow.request.method == "CONNECT":
            return

        # Log intercepted request in verbose mode
        if self.verbose:
            ctx.log.info(f"Intercepting: {flow.request.method} {flow.request.url}")
            
        # Process the request with curl_cffi
        flow.response = self.fetch_with_curl_cffi(flow)

    def fetch_with_curl_cffi(self, flow: http.HTTPFlow) -> http.Response:
        """Process the request using curl_cffi with browser impersonation"""
        url = flow.request.url
        method = flow.request.method
        headers = dict(flow.request.headers)
        data = flow.request.content if flow.request.content else None

        # Only keep important cookies and referer headers
        # Let curl_cffi handle the browser-specific headers
        filtered_headers = {}
        for header in ['cookie', 'referer']:
            if header.lower() in headers:
                filtered_headers[header.lower()] = headers[header.lower()]

        try:
            # Make the request with curl_cffi with browser impersonation
            resp = curl_requests.request(
                method=method,
                url=url,
                headers=filtered_headers,
                data=data,
                impersonate=self.impersonate_browser,
                verify=False,  # Always disable SSL verification for compatibility
                timeout=30,
            )

            # Log response details in verbose mode
            if self.verbose:
                ctx.log.info(f"Response: {resp.status_code} from {url}")

            # Create a mitmproxy response object
            response_headers = dict(resp.headers)
            
            # Remove content-encoding to avoid double decompression
            if 'content-encoding' in response_headers:
                del response_headers['content-encoding']

            return http.Response.make(
                status_code=resp.status_code,
                content=resp.content,
                headers=response_headers
            )

        except Exception as e:
            # Log and return error response
            error_message = f"Error with curl_cffi: {str(e)}"
            ctx.log.error(error_message)
            return http.Response.make(
                status_code=500,
                content=error_message.encode(),
                headers={"Content-Type": "text/plain"}
            )

# Register the addon
addons = [CurlCffiAddon()]
