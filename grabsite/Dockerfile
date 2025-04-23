# Use amd64 Debian 11 (Bullseye) base image
FROM --platform=linux/amd64 debian:bullseye-slim

# Install basic dependencies including Python 3.8 and ping
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates git build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libffi-dev libxml2-dev \
    libxslt1-dev libre2-dev pkg-config iputils-ping gnupg2 \
    && apt-get install -y --no-install-recommends software-properties-common \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 \
    && add-apt-repository -y "deb http://ppa.launchpad.net/deadsnakes/ppa/ubuntu focal main" \
    && apt-get update \
    && apt-get install -y --no-install-recommends python3.8 python3.8-dev python3.8-venv python3.8-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -m -s /bin/bash grabsite

# Switch to the non-root user
USER grabsite
WORKDIR /home/grabsite

# Set up Python virtual environment
RUN python3.8 -m venv /home/grabsite/gs-venv

# Install grab-site
RUN /home/grabsite/gs-venv/bin/pip install --no-binary lxml --upgrade git+https://github.com/ArchiveTeam/grab-site

# Add to PATH
ENV PATH="/home/grabsite/gs-venv/bin:${PATH}"

# Start the dashboard server by default
CMD ["gs-server"]
