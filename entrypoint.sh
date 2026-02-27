#!/bin/bash
set -e

# Source ROS
source /opt/ros/noetic/setup.bash

# Source the Pepper workspace
if [ -f /root/workspace/pepper_rob_ws/devel/setup.bash ]; then
    source /root/workspace/pepper_rob_ws/devel/setup.bash
fi

# Software rendering
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=3.3
export GALLIUM_DRIVER=llvmpipe

# --- Detect native X11 (Linux) vs headless (Mac/Windows) ---------------------
DISPLAY_NUM="${DISPLAY#*:}"
DISPLAY_NUM="${DISPLAY_NUM%%.*}"

if [ -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ]; then
    # Linux — use host display, Gazebo GUI works natively
    echo "Using host X11 display (DISPLAY=$DISPLAY)"
    echo ""
    echo "  Run:  roslaunch pepper_gazebo_plugin pepper_gazebo_plugin_Y20.launch"
    echo ""
else
    # Mac/Windows — start Xvfb (needed by gzserver plugins) + gzweb for viewing
    echo "Starting Xvfb..."
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null
    Xvfb :1 -screen 0 1280x1024x24 +extension GLX +render -noreset &
    sleep 2
    export DISPLAY=:1

    # Start gzweb (browser-based 3D viewer)
    if [ -d /gzweb ]; then
        echo "Starting gzweb..."
        cd /gzweb && npm start &>/dev/null &
        cd /root/workspace/pepper_rob_ws 2>/dev/null || cd /root
        sleep 1
    fi

    echo ""
    echo "============================================================"
    echo "  gzweb ready! After launching Gazebo, open in your browser:"
    echo "    http://localhost:8080"
    echo ""
    echo "  Launch the simulation (headless, no gzclient):"
    echo "    roslaunch pepper_gazebo_plugin pepper_gazebo_plugin_Y20.launch gui:=false"
    echo "============================================================"
    echo ""
fi

exec "$@"
