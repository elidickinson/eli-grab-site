# Use Ubuntu 22.04 (Jammy) base image
FROM ubuntu:jammy

# Install basic dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates git build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libffi-dev libxml2-dev \
    libxslt1-dev libre2-dev pkg-config iputils-ping curl \
    python3-apt python3-pip \
    lsb-release gnupg \
    rustc cargo \
    software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add deadsnakes PPA for multiple Python versions
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.8 python3.8-venv python3.8-dev \
                       python3.12 python3.12-venv python3.12-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up a non-root user
RUN useradd -m -s /bin/bash grabsite

# Switch to the non-root user
USER grabsite
WORKDIR /home/grabsite

# Create directories for virtual environments
RUN mkdir -p /home/grabsite/.venv/grabsite
RUN mkdir -p /home/grabsite/.venv/mitmproxy

# Create Python virtual environments with specific versions
RUN python3.8 -m venv /home/grabsite/.venv/grabsite
RUN python3.12 -m venv /home/grabsite/.venv/mitmproxy

# Install grab-site in the Python 3.8 environment
RUN /home/grabsite/.venv/grabsite/bin/pip install --no-binary lxml git+https://github.com/ArchiveTeam/grab-site
RUN /home/grabsite/.venv/grabsite/bin/pip install curl-cffi
# List installed scripts to verify location
RUN ls -la /home/grabsite/.venv/grabsite/bin/

# Install mitmproxy and curl-cffi in the Python 3.12 environment
RUN /home/grabsite/.venv/mitmproxy/bin/pip install mitmproxy curl-cffi

# Create wrapper scripts to activate the correct environment
COPY start-mitmproxy.sh /home/grabsite/
COPY grab-site-with-impersonation.sh /home/grabsite/
COPY mitmproxy_curl_cffi_addon.py /home/grabsite/

# Setup workspace directory
WORKDIR /home/grabsite/output

# Make scripts executable
USER root
RUN chmod +x /home/grabsite/grab-site-with-impersonation.sh
RUN chmod +x /home/grabsite/start-mitmproxy.sh
USER grabsite

# Start the dashboard server by default
CMD ["/home/grabsite/.venv/grabsite/bin/gs-server"]
