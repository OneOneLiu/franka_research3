#!/usr/bin/env bash
IMAGE_NAME=franka_docker
# 与 Dockerfile 为同一文件；仅打开国内镜像（清华 apt / ROS2 / pip）。
docker build --build-arg USE_CN_MIRROR=1 . -t "${IMAGE_NAME}"