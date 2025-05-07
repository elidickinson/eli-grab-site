# Use Python 3.8 as base image
FROM python:3.8-slim

# Install system dependencies for lxml and other libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libxml2-dev libxslt1-dev libssl-dev \
    iputils-ping curl git pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -m -s /bin/bash grabsite

# Switch to the non-root user
USER grabsite
WORKDIR /home/grabsite

# Install grab-site (using prebuilt wheel for lxml)
RUN pip install --user git+https://github.com/ArchiveTeam/grab-site
RUN pip install --user curl-cffi

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
