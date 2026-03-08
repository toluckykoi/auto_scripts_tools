#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-01 16:56:47
# @version     : bash
# @Update time :
# @Description : 安装 Microsoft Edge


echo "开始安装 Microsoft Edge..."

if ! command -v apt-get &> /dev/null; then
    echo "此脚本仅支持 Debian/Ubuntu 系统"
    exit 1
fi

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /tmp/packages.microsoft.gpg
sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list
sudo apt-get update
sudo apt-get install -y microsoft-edge-stable

if command -v microsoft-edge &> /dev/null; then
    echo "========================================"
    echo "Microsoft Edge 安装成功！"
    microsoft-edge --version
    echo "========================================"
else
    echo "安装失败"
    exit 1
fi
