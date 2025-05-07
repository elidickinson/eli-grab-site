#!/usr/bin/env python3
"""
Chrome Browser Helper Script for grab-site

This script provides direct Chrome browser impersonation using curl_cffi
for use with grab-site. This allows bypassing some anti-bot measures
without needing a full headless browser environment.
"""

import argparse
import os
import sys
import urllib.parse
from curl_cffi import requests

def download_with_impersonation(url, output_path, browser_type="chrome"):
    """Download a URL while impersonating a browser and save to file"""
    
    try:
        print(f"Downloading {url} with {browser_type} impersonation...")
        
        # Make request with browser impersonation
        response = requests.get(
            url,
            impersonate=browser_type,
            timeout=30
        )
        
        # Check if request was successful
        response.raise_for_status()
        
        # Write response content to file
        with open(output_path, 'wb') as f:
            f.write(response.content)
            
        # Return HTTP status code and response headers
        return {
            'status_code': response.status_code,
            'headers': dict(response.headers),
            'content_type': response.headers.get('content-type', ''),
            'content_length': len(response.content)
        }
    
    except Exception as e:
        print(f"Error downloading URL: {e}", file=sys.stderr)
        return {
            'status_code': 0,
            'error': str(e)
        }

def create_cookie_file(cookies, output_path):
    """Create a cookies.txt file from cookies dictionary"""
    
    with open(output_path, 'w') as f:
        for domain, domain_cookies in cookies.items():
            for path, path_cookies in domain_cookies.items():
                for name, cookie in path_cookies.items():
                    f.write(f"{domain}\tTRUE\t{path}\tFALSE\t{cookie.get('expires', 0)}\t{name}\t{cookie['value']}\n")

def main():
    parser = argparse.ArgumentParser(description='Download URL with browser impersonation')
    parser.add_argument('url', help='URL to download')
    parser.add_argument('--output', '-o', required=True, help='Output file path')
    parser.add_argument('--browser', '-b', default='chrome', help='Browser to impersonate (chrome, firefox, safari, etc)')
    parser.add_argument('--cookie-output', help='Path to save cookies.txt file')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    
    # Download with impersonation
    result = download_with_impersonation(args.url, args.output, args.browser)
    
    if args.verbose:
        print(f"Download completed with status: {result['status_code']}")
        
        if 'headers' in result:
            print("\nResponse Headers:")
            for header, value in result['headers'].items():
                print(f"  {header}: {value}")
    
    # Save cookies if requested
    if args.cookie_output and 'cookies' in result:
        create_cookie_file(result.get('cookies', {}), args.cookie_output)
        print(f"Cookies saved to {args.cookie_output}")
    
    # Return success if status code is 200
    return 0 if result.get('status_code') == 200 else 1

if __name__ == "__main__":
    sys.exit(main())