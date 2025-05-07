from mitmproxy import http, ctx
from curl_cffi import requests as curl_requests

class CurlCffiAddon:
    def __init__(self):
        self.impersonate_browser = "chrome"

    def request(self, flow: http.HTTPFlow) -> None:
        # Skip CONNECT requests
        if flow.request.method == "CONNECT":
            return

        # Handle the request ourselves
        ctx.log.info(f"Intercepting request to {flow.request.url}")
        flow.response = self.fetch_with_curl_cffi(flow)

    def fetch_with_curl_cffi(self, flow: http.HTTPFlow):
        url = flow.request.url
        method = flow.request.method
        headers = dict(flow.request.headers)
        data = flow.request.content if flow.request.content else None

        try:
            # Make the request with curl_cffi with Chrome impersonation
            resp = curl_requests.request(
                method=method,
                url=url,
                headers=headers,
                data=data,
                impersonate=self.impersonate_browser,
                verify=False,

            )

            # Create a response object for mitmproxy
            # mitmproxy will automatically handle decompression when clients access
            # the .content property of the response
            headers = dict(resp.headers)
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