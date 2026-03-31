ARG DEBIAN_FRONTEND=noninteractive
ARG ISAACSIM_VERSION=5.1.0

# https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim
FROM nvcr.io/nvidia/isaac-sim:${ISAACSIM_VERSION}

ENV MIN_DRIVER_VERSION=525.60.11
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /isaac-sim

# 基础镜像常为普通用户；apt 与系统安装需 root。
USER root

# =============================================================================
# 1 — Isaac Sim 示例路径 + 通用编译 / 网络 / 图形调试工具
# =============================================================================
RUN ln -s exts/omni.isaac.examples/omni/isaac/examples extension_examples && \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        wget \
        iputils-ping \
        build-essential \
        cmake \
        tree \
        gdb \
        git \
        python3-pip \
        xauth \
        x11-apps && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# 2 — ROS 2 Jazzy：locale、ROS apt 源、桌面版与开发工具
# 参考：https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html
# =============================================================================
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV ROS_DISTRO=jazzy

RUN apt-get update && \
    apt-get install -y locales software-properties-common curl && \
    locale-gen en_US en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    add-apt-repository universe -y && \
    apt-get update && \
    ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F'"' '{print $4}') && \
    curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo ${UBUNTU_CODENAME:-${VERSION_CODENAME}})_all.deb" && \
    apt-get install -y /tmp/ros2-apt-source.deb && \
    rm -f /tmp/ros2-apt-source.deb && \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y ros-dev-tools ros-jazzy-desktop && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# 3 — Franka ROS 2 源码：jazzy 主仓库 + dependency.repos（libfranka 等）
# 参考：https://github.com/frankarobotics/franka_ros2/tree/jazzy
# =============================================================================
ENV FRANKA_ROS2_WS=/franka_ros2_ws

RUN mkdir -p ${FRANKA_ROS2_WS} && cd ${FRANKA_ROS2_WS} && \
    git clone -b jazzy --depth 1 https://github.com/frankarobotics/franka_ros2.git src && \
    vcs import src < src/dependency.repos --recursive --skip-existing

# =============================================================================
# 4 — 工作空间：rosdep、libfranka 单测所需 gtest/gmock、colcon 全量编译
# （上一阶段 apt 曾清理 lists；rosdep install 前须先 apt-get update，否则无法解析 ros-jazzy-*）
# =============================================================================
RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    bash -c 'set -e; source /opt/ros/jazzy/setup.bash; cd /franka_ros2_ws; \
        rosdep install --from-paths src --ignore-src --rosdistro jazzy -y' && \
    apt-get update && \
    apt-get install -y libgtest-dev libgmock-dev && \
    rm -rf /var/lib/apt/lists/* && \
    bash -c 'set -e; source /opt/ros/jazzy/setup.bash; cd /franka_ros2_ws; \
        colcon build --symlink-install \
            --allow-overriding controller_manager hardware_interface realtime_tools \
            --cmake-args -DCMAKE_BUILD_TYPE=Release'

# =============================================================================
# 5 — 交互式 shell 默认 source；容器入口
# =============================================================================
RUN printf '%s\n' \
    'source /opt/ros/jazzy/setup.bash' \
    '[ -f /franka_ros2_ws/install/setup.bash ] && source /franka_ros2_ws/install/setup.bash' \
    >> /root/.bashrc

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
