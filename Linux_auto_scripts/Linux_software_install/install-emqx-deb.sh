#!/bin/bash
# @Author: 幸运锦鲤
# @Date:   2024-11-12 22:32:35
# @Last Modified time:
# Debian 系安装EMQX


echo "开始安装 EMQX..."

sudo apt update
sudo apt install -y curl

if command -v emqx &> /dev/null; then
    echo "EMQX 已安装，跳过安装步骤"
else
    echo "安装 EMQX 中..."
    curl -s https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
    sudo apt-get install -y emqx
fi

sudo systemctl enable emqx
sudo systemctl restart emqx

echo ""
echo "========================================"
echo "emqx 安装完成！"
echo "========================================"
echo "后台管理端口: 18083"
echo "TCP端口: 1883"
echo "SSL端口: 8883"
echo "WebSocket端口: 8083"
echo "安全 WebSocket（WSS）端口: 8084"
echo "========================================"
