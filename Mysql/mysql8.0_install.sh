#!/bin/bash
# @Author: 幸运锦鲤
# @Date:   2024-11-23 21:28:35
# @Last Modified time: 
# mysql8.0安装脚本


ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')

if command -v apt >/dev/null 2>&1; then
    software_manager=apt
elif command -v yum >/dev/null 2>&1; then
    software_manager=yum
else
    echo "未检测到apt、yum或dnf，请手动安装依赖"
    exit 1
fi

install_mysql() {
    if [ "$software_manager" == "apt" ] && [ "$ID" == "ubuntu" ]; then
        echo "####################mysql8.0安装####################"
        echo "暂无ubuntu支持"
        exit 1
    
    elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
        echo "####################mysql8.0安装####################"
        sudo apt -y install gnupg wget
        wget -c https://repo.mysql.com/apt/debian/pool/mysql-apt-config/m/mysql-apt-config/mysql-apt-config_0.8.29-1_all.deb
        if [ $? -eq 0 ]; then echo "mysql8.0.deb下载成功"; else echo "mysql8.0.deb下载失败"; exit 1; fi
        sudo dpkg -i mysql-apt-config_0.8.29-1_all.deb
        sudo apt update
        sudo apt -y install mysql-community-server mysql-server

        if [ $? -eq 0 ]; then echo "mysql8.0安装安装成功"; else echo "mysql8.0安装安装失败"; exit 1; fi

    elif [ "$software_manager" == "yum" ] && [ $ID == '"centos"' ]; then
        echo "####################mysql8.0安装####################"
        echo "暂无centos支持"
        exit 1
    fi
}

install_mysql
