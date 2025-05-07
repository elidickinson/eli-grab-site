# grab-site with Docker Setup

This setup runs [grab-site](https://github.com/ArchiveTeam/grab-site) within a Docker container with VPN routing through [gluetun](https://github.com/qdm12/gluetun), a multi-provider VPN client.

To avoid dependency issues, the grab-site container explicitly uses the platform `linux/amd64` so it will use emulation on ARM devices like Apple Silicon Macs.

## Quick Start

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

3. The grab-site dashboard will be available at `http://localhost:29000`

## Running Crawls

To start a crawl:
```bash
# When running WITH VPN (default):
docker compose exec grabsite grab-site http://example.com

# When running WITHOUT VPN:
docker compose -f docker-compose.novpn.yml exec grabsite grab-site http://example.com
```

### Browser Impersonation

For sites that require a modern browser or have anti-bot measures, you can use the browser impersonation feature. This routes all HTTP requests through a proxy that uses curl_cffi to impersonate legitimate browser traffic:

```bash
# With VPN and Chrome impersonation (default browser):
docker compose exec grabsite /home/grabsite/grab-site-with-browser.sh http://example.com

# Specify a different browser type (chrome, firefox, safari):
docker compose exec grabsite /home/grabsite/grab-site-with-browser.sh --browser=firefox http://example.com

# With VPN, Chrome impersonation, and additional grab-site options:
docker compose exec grabsite /home/grabsite/grab-site-with-browser.sh http://example.com --concurrency=3 --1

# Enable verbose logging to see all requests:
docker compose exec grabsite /home/grabsite/grab-site-with-browser.sh --verbose http://example.com
```

This uses a custom HTTP proxy with curl_cffi to impersonate browser requests for all traffic, which can help bypass many anti-bot protections and CAPTCHAs without requiring a full headless browser.

The output (WARC files, logs, etc) will be saved to `./output/example.com-DATE-HASH/` style directories.

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

## Debugging Tools

Network utility containers for debugging are available in a separate compose file. To use them:

```bash
# Start debugging tools WITH VPN (default)
docker compose -f docker-compose.yml -f docker-compose.debug.yml run --rm -it netutils bash

# Start debugging tools WITHOUT VPN
docker compose -f docker-compose.novpn.yml -f docker-compose.debug.yml run --rm -it netutils-direct bash
```

You can also start them as services if needed:

```bash
# Start debugging container WITH VPN (default)
docker compose -f docker-compose.yml -f docker-compose.debug.yml up -d netutils
docker compose exec netutils bash

# Start debugging container WITHOUT VPN
docker compose -f docker-compose.novpn.yml -f docker-compose.debug.yml up -d netutils-direct
docker compose exec netutils-direct bash
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
VPN_COUNTRY=US                        # Optional: Country for server selection
```

See the [gluetun wiki](https://github.com/qdm12/gluetun-wiki) for provider-specific configuration details.

## Notes

- By default, the setup runs WITH a VPN for privacy and bypassing geo-restrictions
- For local/development use, you can run without VPN using the docker-compose.novpn.yml file
- The dashboard runs on port 29000 by default
- All output (WARC files, logs, etc) is saved to `./output` in subdirectories
- Built to support both amd64 and arm64 architectures (through emulation when needed)
- The grabsite container includes curl for testing connectivity from inside the container