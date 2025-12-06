#!/bin/bash
# @Author: 幸运锦鲤
# @Date:   2024-11-12 22:32:35
# @Last Modified time:
# Debian 系安装EMQX


sudo apt update
sudo apt install -y curl
curl -s https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
sudo apt-get install emqx
sudo systemctl start emqx

echo ""
echo "emqx 安装完成，请在防火墙中放开以下端口："
echo "
    EMQX后台管理端口: 18083
    TCP端口：1883
    SSL端口：8883
    WebSocket端口：8083
    安全 WebSocket（WSS）端口：8084
"
