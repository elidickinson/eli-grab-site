# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a Docker-based setup for running [grab-site](https://github.com/ArchiveTeam/grab-site) through a Private Internet Access VPN. Grab-site is a web archiving tool that creates WARC (Web ARChive) files of websites. This setup routes all traffic through a VPN for privacy and to avoid IP-based blocking.

## Architecture

The system consists of three main components:

1. **VPN Container**: Based on `qmcgaw/private-internet-access` which creates a secure VPN tunnel for all traffic.
   
2. **Grabsite Container**: A custom Docker container based on Ubuntu that runs the grab-site web archiving tool. All traffic is routed through the VPN container.
   
3. **Netutils Container** (optional): A container with network troubleshooting tools.

The architecture uses Docker's networking features to route all grab-site traffic through the VPN container.

## Commands

### Setup and Configuration

```bash
# Copy the sample environment file and edit with your PIA credentials
cp sample.env .env

# Start all services
docker compose up -d
```

### Running Web Archives

```bash
# Start a web archive crawl
docker compose exec grabsite grab-site http://example.com

# The output is saved to ./output/example.com-DATE-HASH/ directories
```

### Accessing and Monitoring

```bash
# Access grab-site dashboard (available at http://localhost:29000)

# Access the grab-site container shell
docker compose exec grabsite bash

# View logs
docker compose logs -f
```

### Debugging

```bash
# Start and access the netutils container for network troubleshooting
docker compose run --rm -it netutils bash

# Alternative way to start netutils
docker compose --profile manual up -d netutils
docker compose exec netutils bash
```

### Building and Pushing Docker Images

```bash
# Build and push multi-architecture image to GitHub Container Registry
./push-image.sh
```

## Notes

- All WARC files and logs are stored in the `./output` directory
- The grab-site dashboard runs on port 29000 by default
- The Docker setup is configured to use platform `linux/amd64` to ensure compatibility with ARM devices through emulation
- When modifying the Dockerfile, remember to build for both amd64 and arm64 architectures