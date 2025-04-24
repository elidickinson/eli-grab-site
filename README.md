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

The WARC files will be saved to the `./warc` directory.

## Additional Commands

- Access the grab-site shell:
  ```bash
  docker compose exec grabsite bash
  ```

- Start the netutils container (for debugging):
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
- Crawler configurations go in `./sites`
- WARC files are saved to `./warc`
- Logs are stored in `./logs`

## Notes

- All traffic is routed through the VPN container
- The dashboard runs on port 29000 by default
