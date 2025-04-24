# Grab-Site with VPN Docker Setup

This setup runs grab-site through a Private Internet Access VPN for secure web archiving.

## Quick Start

1. Copy `sample.env` to `.env` and fill in your PIA credentials
2. Start the services:
   ```bash
   docker compose up -d
   ```
3. The grab-site dashboard will be available at `http://localhost:29000`

## Running Crawls

To start a crawl:
```bash
docker compose exec grabsite grab-site http://example.com
```

The output (WARC files, logs, etc) will be saved to `./output/example.com-2025-04-24-ebe776d2/` style directories.

## Additional Commands

- Access the grab-site shell:
  ```bash
  docker compose exec grabsite bash
  ```

- Start the netutils container (for debugging):
  ```bash
  docker compose run --rm -it netutils bash
  ```
  or
  ```bash
  docker compose --profile manual up -d netutils
  docker compose exec netutils bash
  ```

- View logs:
  ```bash
  docker compose logs -f grabsite
  ```

## Configuration

- Edit `.env` to change VPN region/encryption
- All output (WARC files, logs, etc) is saved to `./output` in subdirectories

## Notes

- All traffic is routed through the VPN container
- The dashboard runs on port 29000 by default
