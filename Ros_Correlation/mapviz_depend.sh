#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-08-09 15:18:17
# @version     : bash
# @Update time :
# @Description : 源码安装 mapviz 所需要的依赖环境安装脚本


sudo apt update
sudo apt-get install -y libglew-dev

sudo apt-get install -y ros-$ROS_DISTRO-marti-common-msgs
sudo apt-get install -y ros-$ROS_DISTRO-rosbridge-suite
sudo apt-get install -y ros-$ROS_DISTRO-swri-transform-util
sudo apt-get install -y ros-$ROS_DISTRO-marti-sensor-msgs
sudo apt-get install -y ros-$ROS_DISTRO-marti-visualization-msgs
sudo apt-get install -y ros-$ROS_DISTRO-swri-image-util
sudo apt-get install -y ros-$ROS_DISTRO-swri-route-util

