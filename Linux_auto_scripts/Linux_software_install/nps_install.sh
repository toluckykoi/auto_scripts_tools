#!/bin/bash
# nps 服务器端安装

clear

[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！！！" && exit 1

echo "请使用 source 命令运行本脚本！！！"

sleep 8

mkdir -p /root/Documents/nps && cd /root/Documents/nps

# Linux 服务端软件：
wget -c https://github.com/ehang-io/nps/releases/download/v0.26.9/linux_amd64_server.tar.gz

tar -zxvf linux_amd64_server.tar.gz

./nps install

# Linux 客户端软件：
# wget -c https://github.com/ehang-io/nps/releases/download/v0.26.9/linux_amd64_client.tar.gz
