#!/bin/bash
# This script sets up a minimal grab-site environment with prebuilt Docker images

# Ask user if they want VPN support
echo "Do you want to set up grab-site with VPN support? (y/n)"
read -r use_vpn

# Create directory structure
mkdir -p grab-site-minimal/output
cd grab-site-minimal || exit 1

if [ "$use_vpn" = "y" ] || [ "$use_vpn" = "Y" ]; then
  echo "Setting up grab-site with VPN support..."
  
  # Download necessary files
  curl -O https://raw.githubusercontent.com/elidickinson/eli-grab-site/main/docker-compose.yml
  curl -O https://raw.githubusercontent.com/elidickinson/eli-grab-site/main/sample.env
  curl -O https://raw.githubusercontent.com/elidickinson/eli-grab-site/main/mitmproxy-entrypoint.sh
  curl -O https://raw.githubusercontent.com/elidickinson/eli-grab-site/main/mitmproxy_curl_cffi_addon.py
  
  # Copy and remind to edit .env
  cp sample.env .env
  echo ""
  echo "Please edit the .env file with your VPN credentials before running docker compose up -d"
  echo "You can do this with any text editor (e.g., nano .env)"
  echo ""
  echo "After editing .env, run: docker compose up -d"
else
  echo "Setting up grab-site without VPN support..."
  
  # Download just the no-VPN docker-compose file
  curl -O https://raw.githubusercontent.com/elidickinson/eli-grab-site/main/docker-compose.novpn.yml
  
  # Start containers
  docker compose -f docker-compose.novpn.yml up -d
  
  echo ""
  echo "Grab-site is now running! Access the dashboard at http://localhost:29000"
  echo ""
  echo "To start a crawl: docker compose -f docker-compose.novpn.yml exec grabsite grab-site http://example.com"
fi

echo ""
echo "Output files will be saved to the ./output directory"