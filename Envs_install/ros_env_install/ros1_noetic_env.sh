#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-30 10:53:32
# @version     : bash
# @Update time :
# @Description : ros1 noetic 相关的环境依赖安装脚本

# noetic 上失去维护
# ros-$ROS_DISTRO-libuvc
# ros-$ROS_DISTRO-ar-track-alvar

echo "Ros 相关依赖安装..."

# ROS
sudo apt install -y ros-$ROS_DISTRO-cv-bridge
sudo apt install -y ros-$ROS_DISTRO-usb-cam
sudo apt install -y ros-$ROS_DISTRO-can-msgs
sudo apt install -y ros-$ROS_DISTRO-tf2-geometry-msgs
sudo apt install -y ros-$ROS_DISTRO-realsense2-camera
sudo apt install -y ros-$ROS_DISTRO-mbf-costmap-core
sudo apt install -y ros-$ROS_DISTRO-mbf-msgs
sudo apt install -y ros-$ROS_DISTRO-costmap-converter
sudo apt install -y ros-$ROS_DISTRO-rtabmap-ros
sudo apt install -y ros-$ROS_DISTRO-async-web-server-cpp
sudo apt install -y ros-$ROS_DISTRO-joy
sudo apt install -y ros-$ROS_DISTRO-ackermann-msgs
sudo apt install -y ros-$ROS_DISTRO-velocity-controllers
sudo apt install -y ros-$ROS_DISTRO-libg2o
sudo apt install -y ros-$ROS_DISTRO-move-base-msgs
sudo apt install -y ros-$ROS_DISTRO-tf2-sensor-msgs
sudo apt install -y ros-$ROS_DISTRO-realsense2-description
sudo apt install -y ros-$ROS_DISTRO-camera-info-manager
sudo apt install -y ros-$ROS_DISTRO-realsense2-camera
sudo apt install -y ros-$ROS_DISTRO-serial
sudo apt install -y ros-$ROS_DISTRO-uuid-msgs
sudo apt install -y ros-$ROS_DISTRO-libuvc-camera ros-$ROS_DISTRO-libuvc-ros
sudo apt install -y ros-$ROS_DISTRO-rgbd-launch
sudo apt install -y ros-$ROS_DISTRO-mavros
sudo apt install -y ros-$ROS_DISTRO-costmap*
sudo apt install -y ros-$ROS_DISTRO-gmapping*
sudo apt install -y ros-$ROS_DISTRO-hector*
sudo apt install -y ros-$ROS_DISTRO-slam-karto*
sudo apt install -y ros-$ROS_DISTRO-octomap*
sudo apt install -y ros-$ROS_DISTRO-cob-map-accessibility-analysis
sudo apt install -y ros-$ROS_DISTRO-rtcm-msgs
sudo apt install -y ros-$ROS_DISTRO-nmea-navsat-driver ros-noetic-geographic-info ros-noetic-gps-common
sudo apt install -y ros-$ROS_DISTRO-catkin-virtualenv ros-noetic-imu-tools
sudo apt install -y ros-$ROS_DISTRO-robot-pose-ekf
sudo apt install -y ros-${ROS_DISTRO}-rviz-visual-tools
sudo apt install -y ros-${ROS_DISTRO}-jsk-rviz-plugins

# systeam
sudo apt-get install -y portaudio19-dev
sudo apt-get install -y libcrypto++-dev
sudo apt-get install -y libpcap-dev
sudo apt-get install -y libuvc-dev
sudo apt-get install -y libudev-dev
sudo apt-get install -y jstest-gtk
sudo apt-get install -y libsdl1.2-dev libsdl-image1.2-dev
sudo apt-get install -y v4l-utils
sudo apt-get install -y liborocos-bfl-dev libnetpbm10-dev 
sudo apt-get install -y libcoinutils-dev coinor-libclp-dev coinor-libosi-dev coinor-libcbc-dev
