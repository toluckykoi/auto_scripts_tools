#!/bin/bash
# @Author: 蓝陌
# @Date:   2024-07-10 15:47:06
# @Last Modified time:
# 针对于 ros1 docker 的初始化脚本


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PARENT_DIR=$(dirname "$SCRIPT_DIR")

rm -rf /etc/apt/sources.list.d/ros-fish.list
gpg --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
gpg --export C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 | sudo tee /usr/share/keyrings/ros.gpg > /dev/null
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/ros.gpg] https://mirrors.ustc.edu.cn/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# root 用户运行：
apt update
apt -y upgrade
apt -y install ros-melodic-desktop-full
apt -y install lsb-release net-tools curl wget vim htop git unzip expect acct gedit
apt -y install gstreamer1.0-tools libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev
apt -y install bash-completion alsa-utils usbutils sox libsox-fmt-all pulseaudio python-sklear*
apt -y install libgl1-mesa-glx libgl1-mesa-dri libglu1-mesa mesa-utils openbox v4l-utils

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

# ros 依赖
source $PARENT_DIR/Envs_install/ros_env_install/ros1_melodic_env.sh

# 特殊依赖
sudo apt -y install libeigen3-dev
sudo cp -r /usr/include/eigen3/Eigen /usr/local/include

bash ./rosdistro_init.sh

# 替换文件
cp ./docker_ros_config/docker_ros_melodic/docker_root.bashrc /root/.bashrc
cp ./docker_ros_config/docker_ros_melodic/docker_user.bashrc /home/ros/.bashrc
cp ./docker_ros_config/docker_ros_melodic/docker_sudo.sudoers /etc/sudoers
cp ./docker_ros_config/docker_ros_melodic/docker_sshd_config /etc/ssh/sshd_config

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
