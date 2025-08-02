#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-30 11:14:32
# @version     : bash
# @Update time :
# @Description : 针对于 ros1 noetic docker 的初始化脚本


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PARENT_DIR=$(dirname "$SCRIPT_DIR")

# root 用户运行：
export DEBIAN_FRONTEND=noninteractive
apt update
apt -y upgrade
apt -y install ros-noetic-desktop-full
apt -y install lsb-release net-tools curl wget vim htop git unzip expect acct gedit
apt -y install gstreamer1.0-tools libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
apt -y install bash-completion alsa-utils usbutils sox libsox-fmt-all pulseaudio python-sklear*
apt -y install libgl1-mesa-glx libgl1-mesa-dri libglu1-mesa mesa-utils openbox v4l-utils libgoogle-glog-dev
apt -y install python3-venv python3-pip

pip3 config set global.index-url https://mirrors.huaweicloud.com/repository/pypi/simple
pip3 install testresources

apt update && apt -y install openssh-server
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
passwd root <<EOF
root
root
EOF

useradd -d /home/ros -m -s /bin/bash ros
passwd ros <<EOF
ros
ros
EOF

usermod -aG ubuntu ros

# ros 依赖安装
source $PARENT_DIR/Envs_install/ros_env_install/ros1_noetic_env.sh


# 特殊依赖
sudo apt -y install libeigen3-dev
sudo cp -r /usr/include/eigen3/Eigen /usr/local/include

bash ./rosdistro_init.sh

# 替换文件
cp ./docker_ros_config/docker_ros_noetic/docker_root.bashrc /root/.bashrc
cp ./docker_ros_config/docker_ros_noetic/docker_user.bashrc /home/ros/.bashrc
cp ./docker_ros_config/docker_ros_noetic/docker_sudo.sudoers /etc/sudoers
cp ./docker_ros_config/docker_ros_noetic/docker_sshd_config /etc/ssh/sshd_config

su ros -c "pip3 config set global.index-url https://mirrors.huaweicloud.com/repository/pypi/simple"

echo "Initialization successful."
su ros

# 关于与宿主机的文件权限问题：
# 因为容器与宿主机是隔离的，用户也是，如果想要权限统一，需要将宿主机创建多一个 ros 用户，并将宿主机用户都加入 ros 组中
# ros:x:1001:ros,ubuntu
# sudo useradd ros
# sudo usermod -aG ros ros
# sudo usermod -aG ros ubuntu
# sudo usermod -aG ubuntu ros
# sudo usermod -aG ubuntu ubuntu
# usermod -aG ubuntu ros `ubuntu`是目标组名，`ros`是要添加的用户名
