#!/bin/bash
set -e

# run_container 传入 DEV_GIT_SAFE_DIR=挂载点；解决 git「dubious ownership」
# 写入 system 级（/etc/gitconfig），避免 /root/.gitconfig 若为 bind-mount 文件时的 EBUSY
if [ -n "${DEV_GIT_SAFE_DIR:-}" ] && [ -d "${DEV_GIT_SAFE_DIR}/.git" ] && command -v git >/dev/null 2>&1; then
    git config --system --add safe.directory "$(cd "${DEV_GIT_SAFE_DIR}" && pwd)" || true
fi

# [ -e /ros2_ws/src/ur5_robot_gripper ] || git clone -b ros2 git@github.com:OneOneLiu/ur5_robot_gripper.git /ros2_ws/src/ur5_robot_gripper || true

if [ -f /opt/ros/jazzy/setup.bash ]; then
    # shellcheck source=/dev/null
    source /opt/ros/jazzy/setup.bash
fi
if [ -f /ros2_ws/install/setup.bash ]; then
    # shellcheck source=/dev/null
    source /ros2_ws/install/setup.bash
fi
exec "$@"
