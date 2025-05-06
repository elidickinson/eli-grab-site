# Use Ubuntu 20.04 (Focal) base image for better Python 3.8 support
FROM ubuntu:focal

# Install basic dependencies including Python 3.8, ping, and curl
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates git build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libffi-dev libxml2-dev \
    libxslt1-dev libre2-dev pkg-config iputils-ping curl \
    python3.8 python3.8-dev python3.8-venv python3.8-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -m -s /bin/bash grabsite

# Switch to the non-root user
USER grabsite
WORKDIR /home/grabsite/output

# Set up Python virtual environment
RUN python3.8 -m venv /home/grabsite/gs-venv

# Upgrade pip and install wheel first
RUN /home/grabsite/gs-venv/bin/pip install --upgrade pip wheel

# Install grab-site
RUN /home/grabsite/gs-venv/bin/pip install --no-binary lxml --upgrade git+https://github.com/ArchiveTeam/grab-site

# Add to PATH
ENV PATH="/home/grabsite/gs-venv/bin:${PATH}"

# Start the dashboard server by default
CMD ["gs-server"]
