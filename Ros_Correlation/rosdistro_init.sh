#!/bin/bash
# @Author: 蓝陌
# @Date:   2024-07-10 15:47:06
# @Last Modified time: 2024-10-08 22:58:06
# ROS rosdep 换源（不要使用sudo或者root运行）

# 原：
# sudo rosdep init
# rosdep update

# 更换：
# 手动模拟 rosdep init
sudo mkdir -p /etc/ros/rosdep/sources.list.d/
sudo cp ./Ros_Distro/20-default.list /etc/ros/rosdep/sources.list.d/

# 为 rosdep update 换源
export ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml
rosdep update

# 每次 rosdep update 之前，均需要增加该环境变量
# 为了持久化该设定，可以将其写入 .bashrc 中，例如
echo '' >> ~/.bashrc
echo '' >> ~/.bashrc
echo "# ROS Distro" >> ~/.bashrc
echo 'export ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml' >> ~/.bashrc
echo '' >> ~/.bashrc

echo "rosdep init done!"

