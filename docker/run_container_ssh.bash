#!/usr/bin/env bash
# 真机请用 run_container.bash（--net=host）。本脚本用于 Antigravity Remote-SSH：映射 SSH 端口，不用 host 网络。
IMAGE=franka_docker
CONTAINER_NAME=franka_docker_ssh
SSH_PORT="${SSH_PORT:-7522}"
# 可选：启动前设置 root 密码，Antigravity 用密码登录时无需再进容器 passwd（勿把密码写进仓库）
# 例：ROOT_PASSWORD='你的密码' bash run_container_ssh.bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
WORKSPACE_HOST="$(cd "${SCRIPT_DIR}/.." && pwd)"
PKG_NAME="$(basename "${WORKSPACE_HOST}")"
MOUNT_DST="/ros2_ws/src/${PKG_NAME}"

if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "本地没有镜像「${IMAGE}」。请先在 docker 目录执行: bash build.bash" >&2
    exit 1
fi

xhost +
XAUTH=/tmp/.docker.xauth
docker run -it \
    --name="$CONTAINER_NAME" \
    -p "${SSH_PORT}:22" \
    --ipc=host \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="XAUTHORITY=$XAUTH" \
    --volume="/dev/bus/usb:/dev/bus/usb" \
    --volume="/tmp/.docker.xauth:/tmp/.docker.xauth:rw" \
    -v /dev:/dev \
    --privileged \
    --volume="/home/$USER/.ssh_docker:/root/.ssh/" \
    --volume="/home/$USER/.gitconfig:/root/.gitconfig:rw" \
    --volume="/home/$USER/catkin_ws/src/moveit_robot_control:/ros2_ws/src/moveit_robot_control:rw" \
    --volume="${WORKSPACE_HOST}:${MOUNT_DST}:rw" \
    -e "ACCEPT_EULA=Y" \
    --runtime=nvidia \
    --gpus all \
    -e "PRIVACY_CONSENT=Y" \
    -e "OMNI_ENV_PRIVACY_CONSENT=1" \
    -e "OMNI_KIT_ALLOW_ROOT=1" \
    -e "DEV_GIT_SAFE_DIR=${MOUNT_DST}" \
    -e "ROOT_PASSWORD=${ROOT_PASSWORD:-}" \
    "$IMAGE" \
    bash -c 'mkdir -p /var/run/sshd; [ -n "${ROOT_PASSWORD:-}" ] && echo "root:${ROOT_PASSWORD}" | chpasswd; /usr/sbin/sshd && exec env -u ROOT_PASSWORD bash -il'

echo "Done."
