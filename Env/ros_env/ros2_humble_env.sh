#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-02-13 00:44:44
# @version     : bash
# @Update time :
# @Description : ros2 humble 相关的环境依赖安装脚本

# boost 版本需要：boost_1_75_0
# 先编译：colcon build --packages-select wheeltec_rrt_msg

# ROS
sudo apt install -y ros-humble-usb-cam
sudo apt install -y ros-humble-joint-state-publisher*
sudo apt install -y ros-humble-image-common
sudo apt install -y ros-humble-filters
sudo apt install -y ros-humble-nav2-mppi*
sudo apt install -y ros-humble-robot-localization
sudo apt install -y ros-humble-async-web-server-cpp*
sudo apt install -y ros-humble-rtab*
sudo apt install -y ros-humble-cartographer*
sudo apt install -y ros-humble-slam-toolbox*
sudo apt install -y ros-humble-test-msgs*
sudo apt install -y ros-humble-behaviortree-cpp-v3*
sudo apt install -y ros-humble-ompl
sudo apt install -y ros-humble-async-web-server-cpp*
sudo apt install -y ros-humble-filters
sudo apt install -y ros-humble-diagnostic-updater
sudo apt install -y ros-humble-rqt*
sudo apt install -y ros-humble-rqt-image-view ros-humble-image-transport
sudo apt install -y ros-humble-magic-enum
sudo apt install -y ros-humble-bondcpp
sudo apt install -y  ros-humble-nav2-*
#sudo apt install -y ros-humble-gazebo-ros-pkgs

# systeam
sudo apt install -y libuvc-dev
