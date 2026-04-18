# Docker（Isaac Sim + 后续 ROS 2）

本目录用于构建与运行 **Franka Research 3** 相关开发环境。镜像基于 NVIDIA **Isaac Sim 5.1.0**（见 [NGC：isaac-sim](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim)；Dockerfile 中 `ARG ISAACSIM_VERSION` 默认与此一致，可自行改为其他标签）。

## 前置条件

- 已安装 **NVIDIA 驱动**（Isaac Sim 要求不低于 Dockerfile 中的 `MIN_DRIVER_VERSION`，当前为 525.60.11 量级，以官方文档为准）。
- 已安装 **Docker**，并配置 **NVIDIA Container Toolkit**（`--gpus all`、`--runtime=nvidia`）。
- 若需图形界面（Isaac Sim / RViz 等）：本机 **X11**，宿主机可执行 `xhost +`（`run_container.bash` 已包含；生产环境建议收紧访问策略）。

## 镜像与命名

| 项目 | 默认值 |
|------|--------|
| 镜像标签 | `franka_docker` |
| 容器名 | `franka_docker` |

修改标签时，请同步修改 `build.bash`、`build_tshinghua.sh` 与 `run_container.bash` 中的名称。

## 构建镜像

### 默认（官方 Ubuntu / packages.ros.org 源）

在 **`docker/` 目录下**执行：

```bash
bash build.bash
```

等价于：`docker build . -t franka_docker`（可通过 `Dockerfile` 顶部 `ARG ISAACSIM_VERSION` 调整 Isaac Sim 版本，默认 `5.1.0`）。

### 中国大陆网络（清华大学镜像源）

与默认构建共用 **`Dockerfile`**，通过 **`USE_CN_MIRROR=1`** 在构建前将 **Ubuntu apt**、**ROS 2 apt**（`packages.ros.org` → 清华）以及 **pip**（PyPI，写入 `/etc/pip.conf`）指向 [清华大学开源软件镜像站](https://mirrors.tuna.tsinghua.edu.cn/)，以加速 `apt` / `rosdep` 中涉及的 pip 等步骤。

在 **`docker/` 目录下**执行：

```bash
bash build_tshinghua.sh
```

等价于：`docker build --build-arg USE_CN_MIRROR=1 . -t franka_docker`。

**说明：** `rosdep update`、`git clone`、`curl`（如从 GitHub 获取 `ros-apt-source` 版本信息）仍依赖外网；若仅 apt/ros2 慢，用本脚本通常有明显改善。镜像名仍为 **`franka_docker`**，与 `run_container.bash` 一致。

## 启动容器

在 **`docker/` 目录下**执行：

```bash
bash run_container.bash
```

脚本会挂载 Isaac Sim 常用缓存与数据目录到 **`~/docker/isaac-sim/`** 下（`kit`、`ov`、`pip`、`GLCache`、`ComputeCache`、`logs`、`data`、`documents` 等）。首次运行前若目录不存在，Docker 会按需创建；也可提前手动创建以便权限清晰。

其他说明：

- 需同意 Omniverse 相关条款：脚本中已设置 `ACCEPT_EULA=Y`、`PRIVACY_CONSENT=Y`、`OMNI_ENV_PRIVACY_CONSENT=1`。
- Dockerfile 使用 **`USER root`** 以便 `apt` 安装依赖；Omniverse Kit 默认禁止 root 启动，故脚本中设置 **`OMNI_KIT_ALLOW_ROOT=1`**（见容器内提示）。若改为镜像默认非 root 用户运行，可去掉此项并调整挂载路径（勿再挂到 `/root/...`）。
- 可选挂载：`~/.ssh_docker` → 容器内 `/root/.ssh`，`~/.gitconfig` → 容器内 git 配置；若本机无对应路径，请先创建或从脚本中删去对应 `-v` 行。
- `--device=/dev/ttyUSB0` 等与串口/硬件相关；无硬件时可按需注释。

## ROS 2 Jazzy 与 Franka ROS 2

- 镜像内已安装 **ROS 2 Jazzy**（`ros-jazzy-desktop`、`ros-dev-tools`），并在 **`/franka_ros2_ws`** 按 [franka_ros2 `jazzy` 分支](https://github.com/frankarobotics/franka_ros2/tree/jazzy) 完成 `vcs import`、`rosdep install`、`colcon build`（构建时间较长，且会拉取 `libfranka`、`gz_ros2_control` 等依赖）。
- **`entrypoint.sh`** 会在执行容器命令前 `source` `/opt/ros/jazzy/setup.bash` 与 **`/franka_ros2_ws/install/setup.bash`**；交互式 shell 也会在 **`~/.bashrc`** 中自动 source。

**无真机自检 MoveIt（假硬件）：**

```bash
ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=dont-care use_fake_hardware:=true
```

真机与 FCI 注意点见 Franka 官方文档（网络、实时内核、避免 Docker Desktop 等）。

更完整的仓库目标说明见根目录 [`README.md`](../README.md)。

## 注意事项

- **拉取 Isaac Sim 基础镜像（`nvcr.io/nvidia/isaac-sim`）**：须先登录 NVIDIA NGC 容器仓库，否则构建时拉取该层常见 **HTTP 403**。在终端执行：

  ```bash
  docker login nvcr.io
  ```

  - **用户名**：按 [NVIDIA NGC 说明](https://org.ngc.nvidia.com/setup/api-keys)，填写固定字面量 **`$oauthtoken`**（不是你的邮箱；若你使用的客户端允许省略用户名，以提示为准）。
  - **密码**：在 [NGC — API Keys](https://org.ngc.nvidia.com/setup/api-keys) 生成 **Personal API Key** 并粘贴。

  登录成功后再执行 `bash build.bash` 或 `bash build_tshinghua.sh`。
