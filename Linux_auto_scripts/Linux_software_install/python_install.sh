#!/bin/bash
# Author: 蓝陌
# VERSION="2022-04-19"
# Date:   2022-04-9 14:59:26
# Modify: 2022-4-21 01:02:50
# 以编译的方式安装 Python
# centos_7 是自带Python 2.7.5
# ubuntu_18 是自带Python 2.7.5
# ubuntu_20 是自带Python 3.8
# 以上都没有安装 pip
# 需要提前安装好 make gcc ！！！
# 需要使用 source 运行此脚本

# 安装前需要检查的是否安装有 wget make gcc !!!!

echo " "
echo "注意：请使用soure命令执行此脚本"
echo " "
echo "1：安装Python2.7.15"
echo "2：安装Python3.8.8"
echo "3：取消"
echo " "
read -p "请选择需要安装的 python 程序：" pythonx

# Python 2.x (2.7.)安装脚本：
if ((pythonx==1)); then
    echo "----------Python 2.7.5 开始安装----------"
    sleep 3
    wget https://www.python.org/ftp/python/2.7.15/Python-2.7.15.tgz
    tar zxvf Python-2.7.15.tgz
    cd Python-2.7.15
    ./configure --prefix=/usr/local/python2
    make && make install
    ln -s /usr/local/python2/bin/python2.7 /usr/bin/python2


# Python 3.x (3.8.8)安装脚本：
elif ((pythonx==2)); then
    echo "----------Python 3.8.8 开始安装----------"
    sleep 3
    wget https://www.python.org/ftp/python/3.8.8/Python-3.8.8.tgz
    tar zxvf Python-3.8.8.tgz
    cd Python-3.8.8
    ./configure --prefix=/usr/local/python3
    make && make install
    ln -s /usr/local/python3/bin/python3.8 /usr/bin/python3
fi


# python pip 安装脚本
# 1 是 Ubuntu 系统
# 2 是 centos 系统
echo "##########-pip开始安装-##########"
echo " "
echo "1：Ubuntu_20"
echo "2：Centos_7"
echo "3：取消"
echo "4：本脚本不适应于ubuntu_18"
echo " "
read -p "请选择本机系统：" system

if ((system==1)); then
    echo "----------Python pip 开始安装----------"
    sleep 3
    apt-get update
    apt-get -y install python3-pip --fix-missing
    rm /usr/bin/pip

# Ubuntu 20 弃用 pip
# Ubuntu 20已经无法通过apt来安装python2的pip2了，只能安装python3的pip
# 同时使用 get-pip.py 也无法安装，暂时无法解决

elif ((system==2)); then
  yum -y install epel-release

  ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
  pip3 install --upgrade pip


fi

