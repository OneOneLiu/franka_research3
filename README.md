# 1. Franka Research 3（ROS 2 + Isaac Sim）

本仓库用于在 **ROS 2** 环境下搭建 **Franka Research 3** 相关能力，并通过 **Docker** 统一开发与运行环境。

## 1.1 环境与基镜像

- **容器基镜像**：NVIDIA Isaac Sim **6.0.0-dev2**
- **ROS 2**：**Jazzy**（`ros-jazzy-desktop`、`ros-dev-tools`）
- **Franka ROS 2**：在镜像构建阶段已克隆 [franka_ros2 `jazzy` 分支](https://github.com/frankarobotics/franka_ros2/tree/jazzy)、拉取 `dependency.repos`、执行 `rosdep` 与 **`colcon build`**，工作空间位于容器内 **`/franka_ros2_ws`**
- **MoveIt 2**：**未在 Dockerfile 里单独写 apt 安装**；在 **`rosdep install --from-paths src`** 解析 `franka_ros2`（含 **`franka_fr3_moveit_config`** 等）依赖时，会 **自动装上** 一组 **`ros-jazzy-moveit-*` 软件包**（如 `moveit-core`、`moveit-ros-move-group`、`moveit-ros-planning-interface` 等）。因此构建完成后 **已具备 MoveIt**，可直接使用文档中的 **`moveit.launch.py`**，无需再单独安装 MoveIt。

构建与运行方式见 [`docker/`](docker/)（`build.bash`、`run_container.bash`）。

## 1.2 使用本 Dockerfile 构建后能得到什么

按 [`docker/Dockerfile`](docker/Dockerfile) **完整构建成功**并进入容器后，环境已包含 **ROS 2 Jazzy** 与 **编译好的 franka_ros2**，可直接做 **无真机（假硬件 / dummy hardware）** 下的 MoveIt 等验证，**无需再手动 clone 与 colcon**（除非你要改源码重编）。

容器启动时会通过 [`docker/entrypoint.sh`](docker/entrypoint.sh) 自动 `source` `/opt/ros/jazzy` 与 `/franka_ros2_ws/install`。

### 1.2.1 无真机测试命令

在容器内执行（需要 **图形界面** 时请用 `docker/run_container.bash` 等方式把 **X11 / `DISPLAY`** 配好，以便打开 RViz）：

```bash
ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=dont-care use_fake_hardware:=true
```

### 1.2.2 真机测试前须完成的工作

以下不满足时，通常 **无法控制真机**：

| 类别 | 说明 |
|------|------|
| 网络 | 宿主机/容器能访问 **Franka Desk** 所在网络的 **机器人 IP**（launch 里的 `robot_ip` 即连这一地址）；使用 `run_container.bash` 的 **`--net=host`** 时与宿主机共用网络栈。 |
| 参数 | Launch 中使用 **真实 `robot_ip`**，并 **关闭假硬件**（`use_fake_hardware:=false`）。 |
| Desk / FCI（机器人侧，非只在电脑上改） | **是**：Franka 文档里的 **Desk** 指 **机器人自带的控制系统与管理界面**（含网页等），**不是** 只在你的 PC 里改 launch 就能替代。Franka 机型一般 **没有** 传统工业机器人那种 **独立大型控制柜**，多为 **随臂配套的小型控制器/电控单元**（具体形态以官方说明与实物为准）。在这些界面（通常用浏览器访问 **机器人 IP** 打开 **Desk 网页**，或 **机载屏幕**）上完成：启用 **FCI**、**解锁**、**允许外部控制** 等。菜单名称与流程以 Franka 官方 **装机 / FCI** 文档为准。 |
| 版本（机器人侧软件 ↔ 电脑端 libfranka） | **不只是在机器人上点一项开关**：**机器人侧**运行 Franka **系统软件 / 固件**（由官方升级与维护）；**电脑 / Docker 侧**编译 **`libfranka`**（本镜像由 `dependency.repos` 固定版本）。两者须在官方 **兼容范围** 内，否则易 **连不上或报版本错误**。升级机器人侧软件后，常需 **对照官方说明** 调整 `libfranka` 并重编工作空间。 |

以下主要影响 **通信稳定性、是否易出现 UDP 超时**，属于 **强烈建议**，但不是「绝对连一次都连不上」的唯一条件：

- 宿主机使用 **PREEMPT_RT** 等实时内核并按要求配置  
- **避免使用 Docker Desktop** 跑对实时敏感的控制；**Linux + Docker Engine** 更合适  

### 1.2.3 真机测试示例 Launch

将 **`192.168.1.10`** 换成你的 **机器人 / Desk 在局域网中的 IP**（与浏览器访问 Desk 网页时用的地址一致）：

```bash
ros2 launch franka_fr3_moveit_config moveit.launch.py robot_ip:=192.168.1.10 use_fake_hardware:=false
```

更复杂的 bringup、多机、夹爪参数等见 [franka_ros2 文档](https://github.com/frankarobotics/franka_ros2/tree/jazzy)（如 `franka_bringup`、`franka.config.yaml`）。

## 1.3 规划能力

| 方向 | 说明 |
|------|------|
| **运动规划与控制** | 基于 ROS 2 的机器人运动规划、控制接口与节点 |
| **仿真** | 与 **Isaac Sim** 对接，支持在仿真中验证规划与控制 |

## 1.4 Docker

镜像构建、启动、环境变量与 Franka 说明见 [`docker/README.md`](docker/README.md)。
