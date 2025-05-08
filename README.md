# grab-site with Docker plus optional VPN & browser impersonation

This setup runs [grab-site](https://github.com/ArchiveTeam/grab-site) within a Docker container with VPN routing through [gluetun](https://github.com/qdm12/gluetun), a multi-provider VPN client. It also includes browser impersonation using mitmproxy and [curl_cffi](https://github.com/lexiforest/curl_cffi) to impersonate Chrome more effectively. It should work on amd64 or arm64 (Apple M-series) platforms.


## Quick Start

### Using Prebuilt Image (Recommended)

1. Copy `sample.env` to `.env` and configure your VPN credentials:
   ```bash
   cp sample.env .env
   nano .env  # Edit with your preferred editor
   ```

2. Start the services:
   ```bash
   # Run WITH VPN (default)
   docker compose up -d

   # Run WITHOUT VPN
   docker compose -f docker-compose.novpn.yml up -d
   ```

   This will automatically pull the prebuilt image from GitHub Container Registry (`ghcr.io/elidickinson/grabsite:latest`).

### Building Locally (Optional)

If you prefer to build the image locally:

```bash
# Run WITH VPN and build locally
docker compose up -d --build

# Run WITHOUT VPN and build locally
docker compose -f docker-compose.novpn.yml up -d --build
```

3. The grab-site server should be running and a dashboard will be available at `http://localhost:29000`

## Running Crawls

To start a standard crawl:
```bash
# When running WITH VPN (default):
docker compose exec grabsite grab-site http://example.com

# When running WITHOUT VPN:
docker compose -f docker-compose.novpn.yml exec grabsite grab-site http://example.com
```

### Browser Impersonation

For rescusing sites that check headers and SSL ciphers to block automated traffic, you can use the browser impersonation feature. This routes all HTTP requests through a proxy that uses curl_cffi to impersonate legitimate browser traffic:

```bash
# With VPN and Chrome impersonation (default browser):
docker compose exec grabsite ../grab-site-with-impersonation.sh http://example.com

# Specify a different browser type (chrome, firefox, safari):
docker compose exec grabsite ../grab-site-with-impersonation.sh --browser=firefox http://example.com

# With VPN, Chrome impersonation, and additional grab-site options:
docker compose exec grabsite ../grab-site-with-impersonation.sh http://example.com --concurrency=3 --1

# Enable verbose logging to see all requests:
docker compose exec grabsite ../grab-site-with-impersonation.sh --verbose http://example.com
```

This uses a custom HTTP proxy with curl_cffi to impersonate browser requests for all traffic, which can help bypass many anti-bot protections and CAPTCHAs without requiring a full headless browser.

The output (WARC files, logs, etc) will be saved to `./output/example.com-DATE-HASH/` directories.

## Additional Commands

- Access a shell within the grab-site container:
  ```bash
  # When running WITH VPN (default):
  docker compose exec grabsite bash

  # When running WITHOUT VPN:
  docker compose -f docker-compose.novpn.yml exec grabsite bash
  ```

- View logs:
  ```bash
  docker compose logs -f
  ```

- Test the mitmproxy from within the grabsite container:
  ```bash
  docker compose exec grabsite curl -k -v -x http://localhost:8080/ https://example.com/
  ```

## Debugging

For debugging network issues, you can use the built-in tools in the grabsite container:

```bash
# Access shell in the grabsite container (with VPN)
docker compose exec grabsite bash

# Access shell in the grabsite container (without VPN)
docker compose -f docker-compose.novpn.yml exec grabsite bash

# Test connectivity to a site
docker compose exec grabsite curl -v https://example.com

# Test with mitmproxy browser impersonation
docker compose exec grabsite curl -k -v -x http://localhost:8080/ https://example.com/
```

## VPN Configuration

This setup uses [gluetun](https://github.com/qdm12/gluetun) which supports multiple VPN providers:

- Private Internet Access
- NordVPN
- Surfshark
- ExpressVPN
- Mullvad
- And many others (see [gluetun wiki](https://github.com/qdm12/gluetun-wiki/tree/main/setup#vpn-providers))

To configure your VPN, edit the `.env` file:

```
VPN_PROVIDER=private internet access  # Change to your provider
VPN_TYPE=openvpn                      # or wireguard for supported providers
VPN_USERNAME=your_username            # Your VPN username
VPN_PASSWORD=your_password            # Your VPN password

# For Private Internet Access, use REGION instead of COUNTRY:
VPN_REGION=US East                    # Example: US East, US West, UK London, etc.

# For other providers, you may use:
# VPN_COUNTRY=US                      # Optional: Country for server selection
# VPN_CITY=New York                   # Optional: City for server selection
```

See the [gluetun wiki](https://github.com/qdm12/gluetun-wiki) for provider-specific configuration details.

## Architecture

The system consists of these main components:

1. **VPN Container**: Based on `qmcgaw/gluetun` which creates a secure VPN tunnel for all traffic.

2. **Mitmproxy Container**: Runs a proxy server with browser impersonation capabilities using curl_cffi.

3. **Grabsite Container**: A custom Docker container that runs the grab-site web archiving tool.

4. **Netutils Container** (optional): A container with network troubleshooting tools.

All traffic from mitmproxy and grab-site is routed through the VPN container using Docker's networking features.

## Quick Start Without Repository Clone

If you don't want to clone the entire repository but still want to use the prebuilt image, use our quickstart script:

```bash
curl -s https://raw.githubusercontent.com/elidickinson/eli-grab-site/main/quickstart.sh | bash
```

This interactive script will:
- Set up a minimal environment with or without VPN support (your choice)
- Download only the necessary files
- Guide you through configuration
- Start the containers automatically

## Notes

- By default, the setup runs WITH a VPN for privacy and bypassing geo-restrictions
- For local/development use, you can run without VPN using the docker-compose.novpn.yml file
- The dashboard runs on port 29000 by default
- All output (WARC files, logs, etc) is saved to `./output` in subdirectories
- Built to support both amd64 and arm64 architectures (through emulation when needed)
- The grabsite container includes curl for testing connectivity from inside the container
- Browser impersonation uses mitmproxy with curl_cffi to mimic real browser traffic
- The prebuilt image is available at `ghcr.io/elidickinson/grabsite:latest`
