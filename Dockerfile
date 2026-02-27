FROM --platform=linux/amd64 ghcr.io/00ducky13/pepper_stage1_ros:latest

ENV DEBIAN_FRONTEND=noninteractive

# VNC stack + gzweb build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    fluxbox \
    xterm \
    x11-apps \
    mesa-utils \
    curl \
    pkg-config \
    libjansson-dev \
    libboost-dev \
    imagemagick \
    build-essential \
    python2 \
    && rm -rf /var/lib/apt/lists/*

# Node.js 12 (required by gzweb 1.4.1 — newer versions break the native bridge)
RUN curl -fsSL https://nodejs.org/dist/v12.22.12/node-v12.22.12-linux-x64.tar.gz \
    | tar -xz -C /usr/local --strip-components=1

# gzweb — browser-based 3D Gazebo viewer (renders via WebGL, no OpenGL needed)
RUN git clone --depth 1 --branch gzweb_1.4.1 https://github.com/osrf/gzweb /gzweb

RUN /bin/bash -c "\
    source /usr/share/gazebo/setup.sh && \
    cd /gzweb && \
    npm run deploy -- -m local \
    "

ENV DISPLAY=:1
EXPOSE 6080 8080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
