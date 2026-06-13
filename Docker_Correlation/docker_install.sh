#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-06-13 23:48:10
# @version     : bash
# @Update time :
# @Description : 一键安装docker脚本

ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')
VERSION_ID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F '=' '{print $2}' | awk -F '"' '{print $2}')
DIR_PATH=$(dirname "$(cd "$(dirname "$0")" && pwd)")

case "$ID" in
    ubuntu|debian|fedora|centos)
        echo "当前系统 ($ID) 受支持。"
        ;;
    *)
        echo "错误：暂不支持的系统类型 '$ID'。仅支持 Ubuntu、Debian、Fedora 或 CentOS。"
        exit 1
        ;;
esac

ARCH=$(uname -m)
if [[ $ARCH == "x86_64" ]] || [[ $ARCH == "i386" ]] || [[ $ARCH == "i686" ]]; then
    SYSTEM_ARCH="x86"
elif [[ $ARCH == "aarch64" ]] || [[ $ARCH == "arm"* ]]; then
    SYSTEM_ARCH="ARM"
else
    echo "未知架构: $ARCH"
    exit 1
fi

if command -v apt >/dev/null 2>&1; then
    software_manager=apt
elif command -v yum >/dev/null 2>&1; then
    software_manager=yum
else
    echo "未检测到apt, yum或dnf软件包安装工具"
    exit 1
fi

if [ $# == 0 ]; then
    server_region="china"
else
    server_region=$1
fi

function docker_speed(){
    echo ""; echo ""
    echo "####################docker pull加速设置####################"
    sudo mkdir -p /etc/docker
    sudo cp $DIR_PATH/ConfigFiles/docker/daemon.json /etc/docker/
    echo "加载加速配置文件成功."

    sudo systemctl daemon-reload
    sudo systemctl restart docker
    if [ $? -eq 0 ]; then
        echo "配置 docker 加速源成功."
    else
        echo "异常配置失败."
        exit
    fi
}

# 1.安装 docke 因国内限制了docker，国内安装docker的曲线救国方法，国外直接一键安装
echo "####################安装docker容器####################"    

if [ "$server_region" = "china" ]; then
    echo "国内安装docker容器"
    if [ "$software_manager" == "apt" ]; then
        echo "debian系docker容器安装"
        sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        if [ "$ID" == "ubuntu" ]; then
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        elif [ "$ID" == "debian" ]; then
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian \
            "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi
        sudo apt-get -y update
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo service docker start
        sudo systemctl enable docker.service
        
        groupadd docker
        if [[ "$2" == "1" ]]; then
            usermod -aG docker $3
        else
            echo "当前执行脚本的用户是：$USER"
            sleep 0.2
            read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
            sudo usermod -aG docker $docker_user
        fi
        
        # newgrp docker
        sudo apt install -y bash-completion

        docker_speed
        echo "docker 容器安装完成，请重启终端(桌面版系统需要重启系统才能普通用户使用docker命令!)"

    elif [ "$software_manager" == "yum" ]; then
        echo "centos系docker容器安装"
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
        sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
        sudo yum makecache --timer
        sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo service docker start
        sudo systemctl enable docker.service
        
        groupadd docker
        if [[ "$2" == "1" ]]; then
            sudo usermod -aG docker $3
        else
            echo "当前执行脚本的用户是：$USER"
            sleep 0.2
            read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
            sudo usermod -aG docker $docker_user
        fi

        # newgrp docker
        sudo yum install -y bash-completion

        docker_speed
        echo "docker 容器安装完成，请重启终端(桌面版系统需要重启系统才能普通用户使用docker命令!)"

    else
        echo "版本不支持"
        exit 1
    fi

elif [ "$server_region" = "foreign" ]; then
    echo "一键安装docker容器"
    curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh
    sudo service docker start
    sudo systemctl enable docker.service

    groupadd docker
    if [[ "$2" == "1" ]]; then
        usermod -aG docker $3
    else
        echo "当前执行脚本的用户是：$USER"
        sleep 0.2
        read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
        usermod -aG docker $docker_user
    fi
    # sudo newgrp docker
    echo "docker容器安装完成"
fi

# 2.安装 docker-compose:
echo ""; echo ""
echo "####################docker-compose安装####################"
sudo $DIR_PATH/Docker_Correlation/docker_compose_install.sh
