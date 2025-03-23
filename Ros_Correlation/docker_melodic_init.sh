#!/bin/bash
# @Author: 蓝陌
# @Date:   2024-07-10 15:47:06
# @Last Modified time:
# 针对于 ros1 docker 的初始化脚本


# root 用户运行：
apt update
apt -y upgrade
apt -y install ros-melodic-desktop-full
apt -y install lsb-release net-tools curl wget vim htop git unzip expect acct gedit
apt -y install gstreamer1.0-tools libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev
apt -y install bash-completion alsa-utils usbutils sox libsox-fmt-all pulseaudio python-sklear*
apt -y install libgl1-mesa-glx libgl1-mesa-dri libglu1-mesa mesa-utils openbox

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
sudo apt-get -y  install libsdl1.2-dev libsdl-image1.2-dev
sudo apt-get -y  install ros-melodic-uuid-msgs
sudo apt-get -y  install ros-melodic-serial
sudo apt-get -y  install ros-melodic-libg2o
sudo apt-get -y  install libpcap-dev
sudo apt-get -y  install libuvc-dev
sudo apt-get -y  install libudev-dev
sudo apt-get -y  install ros-melodic-camera-info-manager
sudo apt-get -y  install ros-melodic-tf2-geometry-msgs
sudo apt-get -y  install ros-melodic-realsense2-camera
sudo apt-get -y  install ros-melodic-mbf-costmap-core
sudo apt-get -y  install ros-melodic-mbf-msgs
sudo apt-get -y  install ros-melodic-bfl
sudo apt-get -y  install ros-melodic-tf2-sensor-msgs
sudo apt-get -y  install ros-melodic-move-base-msgs
sudo apt-get -y  install ros-melodic-costmap-converter
sudo apt-get -y  install ros-melodic-async-web-server-cpp
sudo apt-get -y  install ros-melodic-joy
sudo apt-get -y install ros-melodic-realsense2-description
sudo apt-get -y install ros-melodic-libuvc
sudo apt-get -y install ros-melodic-mavros
sudo apt-get -y install ros-melodic-ackermann-msgs
sudo apt-get -y install ros-melodic-velocity-controllers
sudo apt install -y ros-melodic-costmap*
sudo apt install -y ros-melodic-gmapping*
sudo apt install -y ros-melodic-hector*
sudo apt install -y ros-melodic-slam-karto*
sudo apt install -y ros-melodic-ar-track-alvar
sudo apt install -y ros-melodic-octomap*

# 特殊依赖
sudo apt -y install libeigen3-dev
sudo cp -r /usr/include/eigen3/Eigen /usr/local/include


bash ./rosdistro_init.sh


# 替换文件
cp ./docker_ros_config/docker_root.bashrc /root/.bashrc
cp ./docker_ros_config/docker_user.bashrc /home/ros/.bashrc
cp ./docker_ros_config/docker_sudo.sudoers /etc/sudoers
cp ./docker_ros_config/docker_sshd_config /etc/ssh/sshd_config


# 关于与宿主机的文件权限问题：
# 因为容器与宿主机是隔离的，用户也是，如果想要权限统一，需要将宿主机创建多一个 ros 用户，并将宿主机用户都加入 ros 组中
# ros:x:1001:ros,ubuntu
# sudo useradd ros
# sudo usermod -aG ros ros
# sudo usermod -aG ros ubuntu
# sudo usermod -aG ubuntu ros
# sudo usermod -aG ubuntu ubuntu
# usermod -aG ubuntu ros `ubuntu`是目标组名，`ros`是要添加的用户名
