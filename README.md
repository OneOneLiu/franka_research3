# Franka Research 3 + ROS 2（Docker）

## 这是什么

本仓库提供 **Docker 镜像**，在容器里装好 **ROS 2 Jazzy**、**Franka ROS 2（FR3）**，用于在 **无真机** 时用假硬件跑 MoveIt，或在 **有真机** 时连接 Franka 做规划与控制。镜像基于 **NVIDIA Isaac Sim 5.1.0** 层，便于与 Isaac 生态对齐；日常 Franka 开发主要用容器内的 ROS 2 工作空间 **`/franka_ros2_ws`**。

---

## 安装（构建镜像）

1. 安装 **Docker**、**NVIDIA 驱动**，并配置 **NVIDIA Container Toolkit**（需 GPU 时见 [`docker/README.md`](docker/README.md) 前置条件）。
2. 在仓库里进入 **`docker/`** 目录，执行其一：
   - **常规构建**：`bash build.bash`
   - **中国大陆网络（清华镜像等）**：`bash build_tshinghua.sh`（与 `Dockerfile` 相同，传入 `USE_CN_MIRROR=1`）

构建时间较长；拉取 Isaac 基础镜像需 **NVIDIA NGC 登录**，否则常见 **403**，见下文「注意事项」。

更细的参数、环境变量与故障说明见 **[`docker/README.md`](docker/README.md)**。

---

## 使用

### 启动并进入容器

在 **`docker/`** 下执行：

```bash
bash run_container.bash
```

需要 **RViz / 图形界面**时，请按 [`docker/README.md`](docker/README.md) 配置 **X11 / `DISPLAY`**（脚本里可能已含 `xhost` 等辅助）。

容器启动后会通过 [`docker/entrypoint.sh`](docker/entrypoint.sh) 自动 `source` **`/opt/ros/jazzy`** 与 **`/franka_ros2_ws/install`**。

### 无真机：假硬件跑 MoveIt

在 **容器内**执行：

```bash
ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=dont-care use_fake_hardware:=true
```

### 真机：连机器人

把 **`192.168.1.10`** 换成机器人 / Desk 在局域网中的 **真实 IP**，并关闭假硬件：

```bash
ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=192.168.1.10 use_fake_hardware:=false
```

真机前必须在 **机器人侧**（Desk / FCI 等）完成解锁与允许外部控制；版本需与 **libfranka** 兼容。详见下方「注意事项」。

---

## 注意事项与补充

### 镜像里大致有什么

| 内容 | 说明 |
|------|------|
| ROS 2 | **Jazzy**（`ros-jazzy-desktop` 等） |
| Franka | 构建时克隆 [franka_ros2 `jazzy` 分支](https://github.com/frankarobotics/franka_ros2/tree/jazzy)，在 **`/franka_ros2_ws`** 内 **`colcon build`** 完成 |
| MoveIt 2 | 未在 Dockerfile 里单独写死包名；**`rosdep install --from-paths src`** 解析 `franka_ros2` 时会自动装上所需 **`ros-jazzy-moveit-*`**，一般无需再手动装 MoveIt |
| Isaac Sim | 作为 **Docker 基镜像版本**（默认 **5.1.0**），与 Isaac 工作流对接时使用 |

### Docker：构建、运行、403、国内镜像

- 镜像名默认 **`franka_docker`**；构建、运行脚本与 **NGC 登录、403**、挂载目录等见 **[`docker/README.md`](docker/README.md)**（含 **注意事项** 一节）。

### 真机前建议核对

| 项目 | 说明 |
|------|------|
| 网络 | 本机/容器能访问机器人 **IP**；`run_container.bash` 使用 **`--net=host`** 时与宿主机同网 |
| Launch | **`robot_ip`** 为真实地址，**`use_fake_hardware:=false`** |
| Desk / FCI | **Desk** 指机器人侧控制与管理界面（常通过浏览器访问机器人 **IP**）。需在机器人上启用 **FCI**、解锁、允许外部控制等，**不是**只改电脑上的 launch 即可 |
| 版本 | 机器人 **系统软件 / 固件** 与电脑侧 **`libfranka`**（本仓库由 `dependency.repos` 固定）须在官方 **兼容范围** 内；升级机器人软件后常需对照说明调整并重编 |

对 **UDP 超时、实时性** 更敏感时：**Linux + Docker Engine** 通常优于 Docker Desktop；宿主机使用 **PREEMPT_RT** 等更稳妥（非绝对前提）。

### 规划与仿真方向

- **运动规划与控制**：ROS 2 下的规划、控制接口与节点。  
- **仿真**：可与 **Isaac Sim** 对接做仿真验证（具体对接方式以你使用的 Isaac / 桥接方案为准）。

### 更多文档

- 多机、夹爪、`franka_bringup`、`franka.config.yaml` 等见 [franka_ros2 文档（jazzy）](https://github.com/frankarobotics/franka_ros2/tree/jazzy)。
