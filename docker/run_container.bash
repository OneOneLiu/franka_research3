IMAGE=franka_docker
CONTAINER_NAME=franka_docker

if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "本地没有镜像「${IMAGE}」。请先在 docker 目录执行: bash build.bash" >&2
    exit 1
fi

# 同名容器已存在时 docker run 会失败（例如上次异常退出未删容器）
docker rm -f "$CONTAINER_NAME" &>/dev/null || true

xhost +
XAUTH=/tmp/.docker.xauth
docker run -it \
    --name="$CONTAINER_NAME" \
    --env="DISPLAY=$DISPLAY" \
    --env="QT_X11_NO_MITSHM=1" \
    --env="XAUTHORITY=$XAUTH" \
    --volume="/dev/bus/usb:/dev/bus/usb" \
    --volume="/tmp/.docker.xauth:/tmp/.docker.xauth:rw" \
    --net=host \
    --device=/dev/ttyUSB0 \
    -v /dev:/dev \
    --privileged \
    --volume="/home/$USER/.ssh_docker:/root/.ssh/" \
    --volume="/home/$USER/.gitconfig:/root/.gitconfig:rw" \
    -e "ACCEPT_EULA=Y" \
    --runtime=nvidia \
    --gpus all \
    -e "PRIVACY_CONSENT=Y" \
    -e "OMNI_ENV_PRIVACY_CONSENT=1" \
    -e "OMNI_KIT_ALLOW_ROOT=1" \
    -v ~/docker/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw \
    -v ~/docker/isaac-sim/cache/ov:/root/.cache/ov:rw \
    -v ~/docker/isaac-sim/cache/pip:/root/.cache/pip:rw \
    -v ~/docker/isaac-sim/cache/glcache:/root/.cache/nvidia/GLCache:rw \
    -v ~/docker/isaac-sim/cache/computecache:/root/.nv/ComputeCache:rw \
    -v ~/docker/isaac-sim/logs:/root/.nvidia-omniverse/logs:rw \
    -v ~/docker/isaac-sim/data:/root/.local/share/ov/data:rw \
    -v ~/docker/isaac-sim/documents:/root/Documents:rw \
    "$IMAGE"

echo "Done."
