# grab-site with Docker Setup

This setup runs [grab-site](https://github.com/ArchiveTeam/grab-site) within a Docker container with optional VPN routing through [gluetun](https://github.com/qdm12/gluetun), a multi-provider VPN client.

To avoid dependency issues, the grab-site container explicitly uses the platform `linux/amd64` so it will use emulation on ARM devices like Apple Silicon Macs.

## Quick Start

1. Copy `sample.env` to `.env` and configure your VPN credentials:
   ```bash
   cp sample.env .env
   nano .env  # Edit with your preferred editor
   ```

2. Start the services:
   ```bash
   # Run WITHOUT VPN (default)
   docker compose up -d

   # Run WITH VPN
   docker compose --profile vpn up -d
   ```

3. The grab-site dashboard will be available at `http://localhost:29000`

## Running Crawls

To start a crawl:
```bash
# When running WITHOUT VPN (default):
docker compose exec grabsite-direct grab-site http://example.com

# When running WITH VPN:
docker compose exec grabsite grab-site http://example.com
```

The output (WARC files, logs, etc) will be saved to `./output/example.com-DATE-HASH/` style directories.

## Additional Commands

- Access a shell within the grab-site container:
  ```bash
  # When running WITHOUT VPN (default):
  docker compose exec grabsite-direct bash

  # When running WITH VPN:
  docker compose exec grabsite bash
  ```

- Start the netutils container (for debugging):
  ```bash
  # When running WITHOUT VPN (default):
  docker compose run --rm -it netutils-direct bash
  # or
  docker compose --profile manual up -d netutils-direct
  docker compose exec netutils-direct bash

  # When running WITH VPN:
  docker compose --profile vpn run --rm -it netutils bash
  # or
  docker compose --profile vpn,manual up -d netutils
  docker compose exec netutils bash
  ```

- View logs:
  ```bash
  docker compose logs -f
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

- By default, the setup runs WITHOUT a VPN for simplicity
- When using the VPN (with `--profile vpn`), all traffic is routed through the VPN container
- The dashboard runs on port 29000 by default
- All output (WARC files, logs, etc) is saved to `./output` in subdirectories
- Built to support both amd64 and arm64 architectures (through emulation when needed)