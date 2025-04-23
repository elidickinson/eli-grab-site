# Use a Debian 11 (Bullseye) base image
FROM debian:bullseye-slim

# Install basic dependencies including Python 3.8 and ping
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates git build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libffi-dev libxml2-dev \
    libxslt1-dev libre2-dev pkg-config python3.8 python3.8-dev python3.8-venv \
    python3.8-distutils iputils-ping \
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
