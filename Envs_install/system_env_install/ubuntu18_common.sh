#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-08-17 16:55:13
# @version     : bash
# @Update time :
# @Description : 存储ubuntu18系统中常用的一些依赖，使用时一键安装即可


sudo apt update

# Dependency
sudo apt install -y curl wget vim htop git unzip expect acct tar cmake gdb dos2unix tmux openssh-server gnupg2 net-tools iputils-ping lsb-release
sudo apt install -y ffmpeg libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-tools
sudo apt install -y libssl-dev libxcb-xinerama0 libglew-dev libxcb-cursor0 libxcb-cursor-dev ninja-build
sudo apt install -y build-essential bash-completion x11-xserver-utils
sudo apt install -y libqtermwidget5-0 portaudio19-dev python3-pyaudio

