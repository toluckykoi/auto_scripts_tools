#!/bin/bash
# @Author: 幸运锦鲤
# @Date:   2024-11-23 15:40:35
# @Last Modified time: 
# python virtualenv 虚拟环境管理安装脚本


[ $(id -u) -eq 0 ] && echo "请不要使用 sudo 或 root 来执行此脚本！" && exit 1

ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')
VERSION_ID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F '=' '{print $2}' | awk -F '"' '{print $2}')

if command -v apt >/dev/null 2>&1; then
    software_manager=apt
elif command -v yum >/dev/null 2>&1; then
    software_manager=yum
else
    echo "未检测到apt、yum或dnf，请手动安装依赖"
    exit 1
fi


function install_virtualenv() {
    pip3 install virtualenvwrapper 
    mkdir -p $HOME/.virtualenvs
    echo "" >> ~/.bashrc
    echo "# virtualenv" >> ~/.bashrc
    echo "VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
    echo "WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
    
    if [ -f "/usr/local/bin/virtualenvwrapper.sh" ] && [ -z "$(grep 'source /usr/local/bin/virtualenvwrapper.sh' ~/.bashrc)" ]; then
        echo -e "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
        echo "" >> ~/.bashrc 
    fi
    if [ -f "${HOME}/.local/bin/virtualenvwrapper.sh" ] && [ -z "$(grep "source ${HOME}/.local/bin/virtualenvwrapper.sh" ~/.bashrc)" ]; then 
        echo -e "source ${HOME}/.local/bin/virtualenvwrapper.sh" >> ~/.bashrc
        echo "" >> ~/.bashrc 
    fi
}


if [ "$software_manager" == "apt" ]; then
    sudo apt update
    sudo apt install -y bc

    if [ "$VERSION_ID" == "18.04" ]; then
        sudo apt update
        echo "Python3.8 初始化中..."
        sudo add-apt-repository ppa:deadsnakes/ppa <<EOF

EOF
        sudo apt update
        sudo apt install -y python3.8 python3.8-dev
        echo "Python3.8 安装完成"

        echo "virtualenv 环境初始化中..."
        sudo apt install -y virtualenv python3-virtualenv python3-pip
        python3 -m pip install -i https://mirrors.ustc.edu.cn/pypi/simple --upgrade pip
        pip3 config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple

        install_virtualenv

        if [ $? -eq 0 ]; then echo "virtualenv 环境安装完成"; else echo "virtualenv 环境安装安装失败,请手动检查！"; exit 1; fi

    elif (( $(echo "$VERSION_ID >= 20.04" | bc -l) )) && [ "$ID" == "ubuntu" ]; then
        sudo apt update
        sudo apt install -y virtualenv python3-virtualenv python3-pip
        python3 -m pip install -i https://mirrors.ustc.edu.cn/pypi/simple --upgrade pip
        pip3 config set global.index-url https://mirrors.ustc.edu.cn/pypi/simple

        install_virtualenv

        if [ $? -eq 0 ]; then echo "virtualenv 环境安装完成"; else echo "virtualenv 环境安装安装失败,请手动检查！"; exit 1; fi

    fi

elif [ "$software_manager" == "yum" ]; then
    if [ "$software_manager" == "yum" ] && [ "$ID" == "centos" ]; then
        echo "CentOS 7.x 官方已停止更新..."
    else
        echo "适配中..."
    fi

fi

