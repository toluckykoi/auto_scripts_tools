#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-01-04 18:02:52
# @version     : bash
# @Update time :
# @Description : boot-repair 引导修复软件安装脚本（建议使用ubuntu18.04的镜像）


cd /tmp
wget -c http://web.808066.xyz:200/d/Linux_software/system_dependency/boot-repair.zip
unzip boot-repair.zip

sudo apt install -y mokutil
sudo apt install -y ./glade2script_3.2.4~ppa27_all.deb
sudo apt install -y ./glade2script-python2_3.2.4~ppa27_all.deb
sudo apt install -y ./glade2script-python3_3.2.4~ppa27_all.deb
sudo apt install -y ./boot-sav_4ppa2081_all.deb
sudo apt install -y ./boot-repair_4ppa2081_all.deb
