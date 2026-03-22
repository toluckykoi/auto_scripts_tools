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
function Frp_Install_Deploy(){
case "$1" in
    1)
        SERVICE_NAME="frps"
        UNIT_DESC="frp server"
        ;;
    2)
        SERVICE_NAME="frpc"
        UNIT_DESC="frp client"
        ;;
    *)
        echo "参数错误."
        exit 1
        ;;
esac

# 写入服务文件
sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" > /dev/null <<EOF
[Unit]
# 服务名称，可自定义
Description=$UNIT_DESC
After=network.target syslog.target
Wants=network.target

[Service]
Type=simple
# 启动frps的命令, 需修改为您的frps的安装路径
ExecStart=/opt/frp/$SERVICE_NAME -c /opt/frp/$SERVICE_NAME.toml

[Install]
WantedBy=multi-user.target
EOF

    sleep 2
    echo ""
    read -ep "是否设置Frp开机启动? (y/n): " answer
    answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
    if [[ $answer == "y" || $answer == "yes" ]]; then
        echo "Frp 添加开机启动."
        sudo systemctl enable $SERVICE_NAME.service
    fi

    echo -e "\n# 启动frp\nsudo systemctl start $SERVICE_NAME.service\n# 停止frp\nsudo systemctl stop $SERVICE_NAME.service\n# 重启frp\nsudo systemctl restart $SERVICE_NAME.service\n# 查看frp状态\nsudo systemctl status $SERVICE_NAME.service\n"
    echo "Frp 安装路径: /opt/frp/"
    echo "Frp 配置文件路径: /opt/frp/ "
    echo "systemd 配置文件路径: /etc/systemd/system/$SERVICE_NAME.service"
    echo "Frp 部署完成, 具体请手动配置.toml文件, 参考: https://gofrp.org/zh-cn/docs/examples/"
}

function Frp_Install(){
    FRP_VERSION=0.62.1
    sudo mkdir -p /opt/frp
    cd /opt/frp/
    FRP_URL="http://github.808066.xyz:38000/https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz"
    sudo wget -c "$FRP_URL" -O "frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz"
    
    if [ $? -eq 0 ]; then echo "下载完成."; else echo "下载失败，请重新执行脚本！"; exit 1; fi
    
    sudo tar -zxvf "frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz"
    cd "frp_${FRP_VERSION}_linux_${TARGET_ARCH}"
    sudo cp -r ./* /opt/frp/

    sudo rm -rf "/opt/frp/frp_${FRP_VERSION}_linux_${TARGET_ARCH}.tar.gz" "/opt/frp/frp_${FRP_VERSION}_linux_${TARGET_ARCH}"
    read -ep "请选项部署的方式 (1):服务端, (2):客户端: " frp_deploy
    case $frp_deploy in
        1)
            echo "正在安装部署 Frp 服务端..."
            sudo touch /etc/systemd/system/frps.service
            Frp_Install_Deploy 1
            ;;
        2)
            echo "正在安装部署 Frp 客户端..."
            sudo touch /etc/systemd/system/frpc.service
            Frp_Install_Deploy 2
            ;;
        *)
            echo "无效选项。"
            exit 1
            ;;
    esac
}


echo "内网穿透程序部署，请选择操作："
echo "1. 部署 ZeroTier"
echo "2. 部署 Tailscale"
echo "3. 部署 Frp 服务端/客户端"
echo "4. ZeroTier/Tailscale/Frp卸载操作"
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
    4)
        echo "请选择要卸载的服务："
        echo "1. ZeroTier"
        echo "2. Tailscale"
        echo "3. Frp"
        read -ep "请输入选项 (1/2/3): " uninstall_choice

        case $uninstall_choice in
            1)
                echo "正在卸载 ZeroTier..."
                if command -v zerotier-cli &>/dev/null; then
                    NETWORKS=$(sudo zerotier-cli listnetworks | awk '/^200 listnetworks [a-f0-9]+/ {print $3}')
                    sudo zerotier-cli leave $NETWORKS
                    sudo systemctl stop zerotier-one
                    sudo systemctl disable zerotier-one
                    if command -v apt &>/dev/null; then
                        sudo apt purge -y zerotier-one
                    elif command -v yum &>/dev/null; then
                        sudo yum remove -y zerotier-one
                    else
                        echo "未识别的包管理器，请手动卸载 ZeroTier。"
                        exit 1
                    fi
                    sudo rm -rf /var/lib/zerotier-one/
                    echo "ZeroTier 卸载完成。"
                else
                    echo "未检测到 ZeroTier, 跳过卸载。"
                fi
                ;;
            2)
                echo "正在卸载 Tailscale..."
                if command -v tailscale &>/dev/null; then
                    sudo tailscale down
                    if command -v apt &>/dev/null; then
                        sudo apt purge -y tailscale
                    elif command -v yum &>/dev/null; then
                        sudo yum remove -y tailscale
                    else
                        echo "未识别的包管理器，请手动卸载 Tailscale。"
                        exit 1
                    fi
                    sudo rm -rf /var/lib/tailscale/
                    echo "Tailscale 卸载完成。"
                else
                    echo "未检测到 Tailscale, 跳过卸载。"
                fi
                ;;
            3)
                echo "正在卸载 Frp..."
                if [ -d "/opt/frp" ]; then
                    sudo rm -rf /opt/frp/
                fi
                if [ -f "/etc/systemd/system/frps.service" ]; then
                    sudo systemctl stop frps
                    sudo systemctl disable frps
                    sudo rm -f /etc/systemd/system/frps.service
                fi
                if [ -f "/etc/systemd/system/frpc.service" ]; then
                    sudo systemctl stop frpc
                    sudo systemctl disable frpc
                    sudo rm -f /etc/systemd/system/frpc.service
                fi
                sudo systemctl daemon-reload
                echo "Frp 卸载完成。"
                ;;
            *)
                echo "无效选项。"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "无效选项。"
        ;;
esac
