#!/usr/bin/env bash
IMAGE_NAME=franka_docker
docker build -f Dockerfile.tsinghua . -t "${IMAGE_NAME}"