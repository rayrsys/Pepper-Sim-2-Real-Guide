FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# ── 1. Base tools ────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    lsb-release \
    gnupg2 \
    sudo \
    build-essential \
    python3-pip \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# ── 2. ROS Noetic ───────────────────────────────────────────────────────────
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu focal main" \
    > /etc/apt/sources.list.d/ros-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc \
    | apt-key add - && \
    apt-get update && apt-get install -y \
    ros-noetic-desktop-full \
    python3-rosdep \
    python3-rosinstall \
    python3-rosinstall-generator \
    python3-wstool \
    python3-catkin-tools \
    ros-noetic-gazebo-ros-pkgs \
    ros-noetic-gazebo-ros-control \
    ros-noetic-ros-control \
    ros-noetic-ros-controllers \
    ros-noetic-effort-controllers \
    ros-noetic-joint-trajectory-controller \
    && rm -rf /var/lib/apt/lists/*

RUN rosdep init && rosdep update

# ── 3. Pepper catkin workspace ───────────────────────────────────────────────
RUN mkdir -p /root/workspace/pepper_rob_ws/src
WORKDIR /root/workspace/pepper_rob_ws/src

# Pepper packages (ros-naoqi)
RUN git clone --depth 1 https://github.com/ros-naoqi/pepper_virtual.git && \
    git clone --depth 1 https://github.com/ros-naoqi/pepper_robot.git && \
    git clone --depth 1 https://github.com/ros-naoqi/pepper_moveit_config.git && \
    git clone --depth 1 https://github.com/ros-naoqi/pepper_dcm_robot.git

# pepper_meshes requires license agreement
RUN git clone --depth 1 https://github.com/ros-naoqi/pepper_meshes.git

# Gazebo plugin dependencies
RUN git clone --depth 1 https://github.com/pal-robotics/pal_msgs.git && \
    git clone --depth 1 https://github.com/pal-robotics/pal_gazebo_plugins.git && \
    git clone --depth 1 https://github.com/roboticsgroup/roboticsgroup_gazebo_plugins.git

# ── 4. Install rosdep dependencies & build ───────────────────────────────────
WORKDIR /root/workspace/pepper_rob_ws

RUN /bin/bash -c "\
    source /opt/ros/noetic/setup.bash && \
    export I_AGREE_TO_PEPPER_MESHES_LICENSE=1 && \
    rosdep install --from-paths src --ignore-src -r -y \
    " || true

RUN /bin/bash -c "\
    source /opt/ros/noetic/setup.bash && \
    export I_AGREE_TO_PEPPER_MESHES_LICENSE=1 && \
    catkin_make \
    "

# ── 5. VNC stack + gzweb dependencies ───────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    fluxbox \
    xterm \
    x11-apps \
    mesa-utils \
    pkg-config \
    libjansson-dev \
    libboost-dev \
    imagemagick \
    python2 \
    && rm -rf /var/lib/apt/lists/*

# ── 6. Node.js 12 (required by gzweb 1.4.1) ────────────────────────────────
RUN curl -fsSL https://nodejs.org/dist/v12.22.12/node-v12.22.12-linux-x64.tar.gz \
    | tar -xz -C /usr/local --strip-components=1

# ── 7. gzweb — browser-based 3D Gazebo viewer ───────────────────────────────
RUN git clone --depth 1 --branch gzweb_1.4.1 https://github.com/osrf/gzweb /gzweb

RUN /bin/bash -c "\
    source /usr/share/gazebo/setup.sh && \
    cd /gzweb && \
    npm run deploy -- -m local \
    "

# ── 8. Entrypoint ───────────────────────────────────────────────────────────
ENV DISPLAY=:1
WORKDIR /root/workspace/pepper_rob_ws
EXPOSE 6080 8080

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
