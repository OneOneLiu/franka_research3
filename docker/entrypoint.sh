#!/bin/bash
set -e
if [ -f /opt/ros/jazzy/setup.bash ]; then
    # shellcheck source=/dev/null
    source /opt/ros/jazzy/setup.bash
fi
if [ -f /franka_ros2_ws/install/setup.bash ]; then
    # shellcheck source=/dev/null
    source /franka_ros2_ws/install/setup.bash
fi
exec "$@"
