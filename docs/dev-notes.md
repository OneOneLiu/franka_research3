# 开发调试记录

## Docker 里用 git

- `run_container.bash`：宿主机仓库挂到 `/ros2_ws/src/<目录名>`，并设 `DEV_GIT_SAFE_DIR` 指向该路径。
- `entrypoint.sh`：`git config --system --add safe.directory "<挂载绝对路径>"`（用 `--system` 写 `/etc/gitconfig`，避免把 `/root/.gitconfig` 绑成单文件时 `git config --global` 报 *Device or resource busy*）。
- 业务仓库仍可在宿主机 `git`；容器内需 SSH 时依赖 `~/.ssh_docker` → `/root/.ssh`。

## 编译 `ur5_robot_gripper`

- **镜像构建阶段**（Dockerfile，与 gtest 同条 `apt`）：`nlohmann-json3-dev`、`ros-jazzy-moveit-visual-tools`。
- **容器启动**：`entrypoint.sh` 一行 `git clone` 到 `/ros2_ws/src/ur5_robot_gripper`（目录已存在则跳过）；需 SSH 密钥在容器内可用。

## MoveIt 调试结论

- 调试入口：`/ros2_ws/src/franka_fr3_moveit_config/launch/move_group.launch.py`。
- 现象：MoveIt 能规划但不能执行（mock component 问题）。
- 修复：将 `/ros2_ws/src/franka_fr3_moveit_config/config/fr3_ros_controllers.yaml` 中 `arm_controller.command_interfaces` 改为 `position`。
- `move_group.launch.py` 会 include `gripper.launch.py`。
- `gripper.launch.py` 在 `use_fake_hardware:=true` 时启动 `fake_gripper_state_publisher.py`，该节点不提供 action server。
- 因此 fake 模式会出现“有 client 没 server”，夹爪不执行动作。
