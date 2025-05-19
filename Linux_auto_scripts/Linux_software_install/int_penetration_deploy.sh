#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-05-19 10:45:06
# @version     : bash
# @Update time : 
# @Description : 内网穿透程序部署


ARCH=$(uname -m)
case "$ARCH" in
    "x86_64")
        TARGET_ARCH="amd64"
        ;;
    "aarch64" | "arm64")
        TARGET_ARCH="arm64"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac

# ZeroTier
#########################################################
# 加入、离开和列出网络。请记住，ZeroTier 网络是 16 位 ID，如下所示8056c1221c000001 (200 人加入 OK)
# zerotier-cli join 8056c1221c000001
# 200 离开 OK
# zerotier-cli leave 8056c1221c000001
# 查询
# zerotier-cli listnetworks
#########################################################
function ZeroTier_Install(){
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y fonts-liberation libu2f-udev

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y fonts-liberation libu2f-udev
    else
        echo "未检测到apt、yum或dnf, 请手动安装依赖"
        exit 1
    fi

    curl -s https://install.zerotier.com | sudo bash

    sleep 3
    read -ep "请输入ZeroTier网络16位ID: " idid
    sudo zerotier-cli join $idid
    sleep 2
    sudo zerotier-cli listnetworks
    echo "部署 ZeroTier 完成."
}

# Tailscale
#########################################################
# 将您的计算机连接到 Tailscale 网络并在浏览器中进行身份验证：
# sudo tailscale up
# 您已连接！您可以通过运行以下命令找到您的尾鳞 IPv4 地址：
# tailscale ip -4
#########################################################
function Tailscale_Install(){
    curl -fsSL https://tailscale.com/install.sh | sh
    
    sleep 3
    sudo tailscale up
    sleep 2
    echo -n "Tailscale IP地址为: " && tailscale ip -4
    echo "部署 Tailscale 完成."
}

# Frp
#########################################################
# https://github.com/fatedier/frp
# https://gofrp.org/zh-cn/docs/setup/
#########################################################
function Frp_Install(){
    FRP_VERSION=0.62.1
    sudo mkdir -p /opt/frp
    cd /opt/frp/
    FRP_URL="http://github.808066.xyz:38000/https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz"
    sudo wget -c "$FRP_URL" -O "frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz"
    
    if [ $? -eq 0 ]; then echo "下载完成."; else echo "下载失败，请重新执行脚本！"; exit 1; fi
    
    sudo tar -zxvf "frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz"
    cd "frp_${FRP_VERSION}_linux_${TARGET_ARCH}"
    
    sudo touch /etc/systemd/system/frps.service
    sudo tee /etc/systemd/system/frps.service > /dev/null <<EOF
[Unit]
# 服务名称，可自定义
Description=frp server
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
# 启动frps的命令, 需修改为您的frps的安装路径
ExecStart=/path/to/frps -c /path/to/frps.toml

[Install]
WantedBy=multi-user.target
EOF

    sleep 2
    echo ""
    echo "Frp 下载完成, 已简单配置, 具体需要手动配置."
    echo "Frp 安装路径: /opt/frp/frp_${FRP_VERSION}_linux_${TARGET_ARCH}"
    echo "systemd 配置文件路径: /etc/systemd/system/frps.service"
}


echo "内网穿透程序部署，请选择操作："
echo "1. 部署 ZeroTier"
echo "2. 部署 Tailscale"
echo "3. 下载安装 Frp"
read -ep "请输入选项: " option

case $option in
    1)
        echo "正在安装部署 ZeroTier..."
        ZeroTier_Install
        ;;
    2)
        echo "正在安装部署 Tailscale..."
        Tailscale_Install
        ;;
    3)
        echo "正在下载安装 Frp..."
        Frp_Install
        ;;
    *)
        echo "无效选项。"
        ;;
esac
