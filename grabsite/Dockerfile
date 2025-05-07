# Use Python 3.8 as base image
FROM python:3.8-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential pkg-config libxml2-dev libxslt1-dev libssl-dev \
    zlib1g-dev iputils-ping curl git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -m -s /bin/bash grabsite

# Switch to the non-root user
USER grabsite
WORKDIR /home/grabsite

# Install lxml from source first to ensure consistent libxml2 version
RUN pip install --user --no-binary lxml lxml

# Install grab-site
RUN pip install --user git+https://github.com/ArchiveTeam/grab-site

# Setup workspace directory first
WORKDIR /home/grabsite/output

# Copy impersonation script with proper ownership
USER root
COPY grab-site-with-impersonation.sh /home/grabsite/
RUN chmod +x /home/grabsite/grab-site-with-impersonation.sh && \
    chown grabsite:grabsite /home/grabsite/grab-site-with-impersonation.sh
USER grabsite

# Add user's local bin to PATH
ENV PATH="/home/grabsite/.local/bin:${PATH}"

# Start the dashboard server by default
CMD ["gs-server"]
