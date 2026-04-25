#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-04-06 17:46:55
# @version     : bash
# @Update time :
# @Description : 优化nginx_ui的安装


[ $(id -u) -gt 0 ] && echo "权限不足,请用root用户执行此脚本,不是root用户请使用 sudo xxx.sh 执行" && exit 1


function env_check() {
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y nginx
    elif command -v dnf &> /dev/null; then
        # Fedora/CentOS 8+
        sudo dnf install -y nginx
    elif command -v yum &> /dev/null; then
        # CentOS 7
        sudo yum install -y nginx
    else
        echo "Unsupported package manager"
        exit 1
    fi
}

env_check

# 安装最新稳定版本
sudo bash -c "$(curl -L https://cloud.nginxui.com/install.sh)" @ install -r https://cloud.nginxui.com/
