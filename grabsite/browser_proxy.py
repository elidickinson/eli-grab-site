#!/usr/bin/env python3
"""
Browser Impersonation Proxy for grab-site

This proxy intercepts HTTP/HTTPS requests and forwards them using
curl_cffi with browser impersonation capability. It allows grab-site
to benefit from browser impersonation for all requests.
"""

import argparse
import http.server
import socketserver
import urllib.parse
import sys
import os
import ssl
import json
import threading
import time
import logging
from http import HTTPStatus
from curl_cffi import requests as curl_requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger('browser_proxy')

class BrowserImpersonationProxy(http.server.BaseHTTPRequestHandler):
    """HTTP request handler that forwards requests with browser impersonation"""

    # Class-level settings - overridden via command line
    browser_type = "chrome"
    verbose = False
    allow_insecure_ssl = True

    def log_message(self, format, *args):
        """Override to use our logger"""
        if self.verbose:
            try:
                # Safely format the message
                if args:
                    logger.info(format % args)
                else:
                    logger.info(format)
            except Exception as e:
                # Log formatting error but don't crash
                logger.error(f"Log formatting error: {e}")
                logger.info(format)

    def do_GET(self):
        """Handle GET requests"""
        self._handle_request("GET")

    def do_POST(self):
        """Handle POST requests"""
        self._handle_request("POST")

    def do_HEAD(self):
        """Handle HEAD requests"""
        self._handle_request("HEAD")

    def do_PUT(self):
        """Handle PUT requests"""
        self._handle_request("PUT")

    def do_DELETE(self):
        """Handle DELETE requests"""
        self._handle_request("DELETE")

    def do_OPTIONS(self):
        """Handle OPTIONS requests"""
        self._handle_request("OPTIONS")

    def do_CONNECT(self):
        """
        Handle HTTPS CONNECT requests by establishing a tunnel to the target server
        """
        self.log_message("Received CONNECT request for %s", self.path)

        # Parse target address
        host_port = self.path.split(':')
        if len(host_port) != 2:
            self.send_error(400, "Bad Request: Invalid host:port format")
            return
            
        target_host, target_port = host_port
        target_port = int(target_port)
        
        # Create a connection to the target server
        import socket
        target_conn = None
        try:
            target_conn = socket.create_connection((target_host, target_port), timeout=10)
            
            # Tell the client we've established the connection
            self.send_response(200, "Connection established")
            self.end_headers()
            
            # Log the connection
            if self.verbose:
                logger.info("CONNECT tunnel established for %s" % self.path)

            # Set socket timeout to prevent hanging
            self.connection.settimeout(0.5)
            target_conn.settimeout(0.5)
            
            # Start forwarding data between client and target
            self._tunnel_data(target_conn)
                
        except Exception as e:
            if target_conn:
                target_conn.close()
            self.send_error(502, "Bad Gateway: %s" % str(e))
            logger.error("CONNECT tunnel error for %s: %s", self.path, str(e))
            
    def _tunnel_data(self, target_conn):
        """Tunnel data between client and target server"""
        import select
        
        # Use select to wait for data on either socket
        sockets = [self.connection, target_conn]
        while True:
            try:
                # Wait for data on either socket
                readable, _, exceptional = select.select(sockets, [], sockets, 10)
                
                if exceptional:
                    break  # Any exceptional event, break the loop
                
                for sock in readable:
                    # Determine source and destination sockets
                    if sock is self.connection:  # Data from client
                        data = sock.recv(8192)
                        if not data:
                            return  # Client closed connection
                        target_conn.sendall(data)
                    else:  # Data from target
                        data = sock.recv(8192)
                        if not data:
                            return  # Target closed connection
                        self.connection.sendall(data)
                        
            except (ConnectionResetError, BrokenPipeError, TimeoutError) as e:
                logger.error("Tunnel connection error: %s", str(e))
                break
            except Exception as e:
                logger.error("Unexpected tunnel error: %s", str(e))
                break

    def _handle_request(self, method):
        """Process and forward HTTP requests with browser impersonation"""
        try:
            # Parse the URL
            url = self.path
            if not url.startswith(('http://', 'https://')):
                # For CONNECT (HTTPS), the path is just hostname:port
                if ':' in self.path:
                    host, port = self.path.split(':')
                    url = f"https://{host}:{port}"
                else:
                    url = f"http://{self.path}"

            # Log request - Use string concatenation to avoid potential formatting issues
            self.log_message("%s %s" % (method, url))

            # Get request headers
            headers = {k: v for k, v in self.headers.items()}

            # Read request body for methods that might have one
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None

            # Forward the request with browser impersonation
            start_time = time.time()
            response = self._forward_request(method, url, headers, body)
            elapsed = time.time() - start_time

            # Send response back to client
            self.send_response(response.status_code)

            # Send headers
            for header, value in response.headers.items():
                # Skip sensitive headers that the http.server doesn't allow
                if header.lower() not in ('transfer-encoding', 'connection'):
                    self.send_header(header, value)

            # End headers
            self.end_headers()

            # Send response body
            if response.content:
                self.wfile.write(response.content)

            # Log response details
            if self.verbose:
                logger.info("Response: %d in %.2fs, size: %d bytes", 
                           response.status_code, elapsed, len(response.content))

        except Exception as e:
            # Log the error safely with proper string formatting
            logger.error("Error handling request: %s", str(e))
            # Try to send an error response
            try:
                # Use a simpler error message approach
                self.send_error(
                    HTTPStatus.INTERNAL_SERVER_ERROR,
                    "Error handling request"
                )
            except Exception:
                # If we can't even send the error, just pass
                pass

    def _forward_request(self, method, url, headers, data=None):
        """Forward the request using curl_cffi with browser impersonation"""
        try:
            # Filter headers to keep only essential ones and let curl-cffi handle the rest
            # This way, the browser impersonation headers from curl-cffi won't be overridden
            filtered_headers = {}
            
            # Only keep essential headers that shouldn't be overridden by impersonation
            # Cookies are important to maintain sessions
            if 'Cookie' in headers:
                filtered_headers['Cookie'] = headers['Cookie']
            
            # If there's an authorization header, keep it
            if 'Authorization' in headers:
                filtered_headers['Authorization'] = headers['Authorization']
                
            # Keep any custom headers that might be needed (prefixed with X-)
            for header, value in headers.items():
                if header.lower().startswith('x-'):
                    filtered_headers[header] = value
            
            # Handle Referer separately - sometimes needed for anti-bot checks
            if 'Referer' in headers:
                filtered_headers['Referer'] = headers['Referer']
                
            # Log filtered headers
            if self.verbose:
                # Convert dictionaries to strings safely for logging
                logger.info("Original headers: %s", str(headers))
                logger.info("Filtered headers: %s", str(filtered_headers))
            
            # Make the request with curl_cffi with browser impersonation
            response = curl_requests.request(
                method=method,
                url=url,
                headers=filtered_headers,  # Use the filtered headers
                data=data,
                impersonate=self.browser_type,
                verify=not self.allow_insecure_ssl,
            )

            # Return the response
            return response

        except Exception as e:
            # Log the error safely
            logger.error("Error in _forward_request: %s", str(e))
            # Create a minimal response for error cases
            raise

def run_proxy(port=8080, browser_type="chrome", verbose=False, allow_insecure=True):
    """Run the browser impersonation proxy server"""
    # Set class-level settings
    BrowserImpersonationProxy.browser_type = browser_type
    BrowserImpersonationProxy.verbose = verbose
    BrowserImpersonationProxy.allow_insecure_ssl = allow_insecure

    # Create the server
    server = socketserver.ThreadingTCPServer(('', port), BrowserImpersonationProxy)

    try:
        # Print startup message
        logger.info("Starting browser impersonation proxy on port %d", port)
        logger.info("Browser type: %s", browser_type)
        logger.info("Allow insecure SSL: %s", str(allow_insecure))
        logger.info("Verbose logging: %s", str(verbose))
        logger.info("Press Ctrl+C to stop the server")

        # Run the server
        server.serve_forever()

    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received, shutting down...")

    except Exception as e:
        logger.error("Error running proxy server: %s", str(e))

    finally:
        # Shut down the server
        server.server_close()
        logger.info("Proxy server has been shut down")

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Browser Impersonation Proxy for grab-site')
    parser.add_argument('--port', '-p', type=int, default=8080, help='Port to run the proxy server on')
    parser.add_argument('--browser', '-b', default='chrome', help='Browser to impersonate (chrome, firefox, safari)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose logging')
    parser.add_argument('--allow-insecure', '-k', action='store_true', help='Allow insecure SSL connections (skip verification)')

    args = parser.parse_args()

    # Run the proxy server
    run_proxy(
        port=args.port,
        browser_type=args.browser,
        verbose=args.verbose,
        allow_insecure=args.allow_insecure
    )

if __name__ == "__main__":
    main()
