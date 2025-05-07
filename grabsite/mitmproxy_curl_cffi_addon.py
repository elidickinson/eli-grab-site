"""
mitmproxy_curl_cffi_addon.py - A mitmproxy addon for browser impersonation using curl_cffi

This addon intercepts requests and processes them with curl_cffi with browser impersonation,
allowing for bypassing of anti-bot protections while using grab-site.
"""

from mitmproxy import http, ctx
from curl_cffi import requests as curl_requests
import json

class CurlCffiAddon:
    def __init__(self):
        self.impersonate_browser = "chrome"
        self.verify_ssl = False
        self.verbose = False

    def load(self, loader):
        # This will be called when the addon is loaded
        ctx.log.info(f"CurlCffiAddon loaded with {self.impersonate_browser} impersonation")

    def configure(self, updates):
        # Allow configuration changes at runtime
        if "impersonate_browser" in ctx.options:
            self.impersonate_browser = ctx.options.impersonate_browser
            ctx.log.info(f"Set impersonation browser to: {self.impersonate_browser}")
            
        if "verify_ssl" in ctx.options:
            self.verify_ssl = ctx.options.verify_ssl
            
        if "verbose" in ctx.options:
            self.verbose = ctx.options.verbose

    def request(self, flow: http.HTTPFlow) -> None:
        # For CONNECT requests (HTTPS tunneling), we need to pass them through
        if flow.request.method == "CONNECT":
            if self.verbose:
                ctx.log.info(f"CONNECT request to {flow.request.host}:{flow.request.port}")
            # Let mitmproxy handle the CONNECT tunneling natively
            return
            
        # Handle the request using curl_cffi with browser impersonation
        if self.verbose:
            ctx.log.info(f"Intercepting request: {flow.request.method} {flow.request.url}")
        flow.response = self.fetch_with_curl_cffi(flow)

    def fetch_with_curl_cffi(self, flow: http.HTTPFlow) -> http.Response:
        """Process the request using curl_cffi with browser impersonation"""
        url = flow.request.url
        method = flow.request.method
        headers = dict(flow.request.headers)
        data = flow.request.content if flow.request.content else None
        
        # Remove headers that curl_cffi will set with browser impersonation
        # to avoid conflicts with the browser profiles
        headers_to_remove = [
            'user-agent', 'accept', 'accept-language', 'accept-encoding',
            'upgrade-insecure-requests', 'sec-fetch-dest', 'sec-fetch-mode',
            'sec-fetch-site', 'sec-fetch-user'
        ]
        
        for header in headers_to_remove:
            if header in headers:
                if self.verbose:
                    ctx.log.debug(f"Removing header: {header}")
                del headers[header]

        # Log the request details if in verbose mode
        if self.verbose:
            ctx.log.info(f"Making request to {url} with {self.impersonate_browser} impersonation")
            ctx.log.debug(f"Headers: {json.dumps(headers)}")
            
        try:
            # Make the request with curl_cffi with browser impersonation
            resp = curl_requests.request(
                method=method,
                url=url,
                headers=headers,
                data=data,
                impersonate=self.impersonate_browser,
                verify=self.verify_ssl,
            )
            
            # Log the response if in verbose mode
            if self.verbose:
                ctx.log.info(f"Response: {resp.status_code}")
                ctx.log.debug(f"Response headers: {json.dumps(dict(resp.headers))}")

            # Create a response object for mitmproxy
            # mitmproxy will handle decompression when clients access
            # the .content property of the response
            headers = dict(resp.headers)
            
            # Remove content-encoding to avoid double decompression
            if 'content-encoding' in headers:
                del headers['content-encoding']
                
            response = http.Response.make(
                status_code=resp.status_code,
                content=resp.content,
                headers=headers
            )
            return response
            
        except Exception as e:
            # Handle errors
            error_message = f"Error making request with curl_cffi: {str(e)}"
            ctx.log.error(error_message)
            return http.Response.make(
                status_code=500,
                content=error_message.encode(),
                headers={"Content-Type": "text/plain"}
            )

# Register the addon
addons = [CurlCffiAddon()]