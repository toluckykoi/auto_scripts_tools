#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-05-28 23:37:08
# @version     : bash
# @Update time :
# @Description : python 虚拟环境部署脚本


PYENVS=~/.pyenvs
DIR_PATH=$( cd "$( dirname "$(dirname "$(pwd)")" )" >/dev/null 2>&1 && pwd )
ARCH=$(uname -m)
case "$ARCH" in
    "x86_64")
        TARGET_ARCH="x86_64"
        ;;
    "aarch64" | "arm64")
        TARGET_ARCH="aarch64"
        ;;
    *)
        echo "不支持的架构: $ARCH"
        exit 1
        ;;
esac


function python_venv_deploy() {
    if [ ! -d "$PYENVS" ]; then
        echo "虚拟环境目录 $PYENVS 不存在，正在创建..."
        mkdir -p "$PYENVS"
    else
        echo "虚拟环境目录 $PYENVS 已存在。"
    fi

    read -ep "请输入需要创建Python的虚拟环境名: " env_name
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y python3-venv python3-pip

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3-venv python3-pip
    
    else
        echo "未检测到apt、yum或dnf, 请手动安装依赖(venv,pip)"
        exit 1
    fi

    python3 -m venv $PYENVS/$env_name
    echo "Python venv $env_name 环境创建成功"
    echo "虚拟环境路径为：$PYENVS/$env_name"
    echo "请使用$PYENVS/$env_name/bin/activate进行激活虚拟环境"
}


function python_uv_deploy() {
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y curl wget

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y curl wget
    
    else
        echo "未检测到apt、yum或dnf, 请手动安装依赖"
        exit 1
    fi

    wget -qO- https://astral.sh/uv/install.sh | sh
    echo "Python uv 安装完成."
}


function miniconda3_deploy() {
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y curl wget

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y curl wget
    
    else
        echo "未检测到apt、yum或dnf, 请手动安装依赖"
        exit 1
    fi

    wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$ARCH.sh
    chmod +x Miniconda3-latest-Linux-$ARCH.sh
    ./Miniconda3-latest-Linux-$ARCH.sh

    rm -rf ./Miniconda3-latest-Linux-$ARCH.sh
}


function virtualenv_deploy() {
    cd $DIR_PATH/Linux_auto_scripts/Linux_software_install/
    ./py_virtualenv_install.sh
}


echo "Python 虚拟环境创建，请选择操作："
echo "1. Python venv"
echo "2. Python uv"
echo "3. Miniconda3"
echo "4. Virtualenv"
read -ep "请输入选项: " option


case $option in
    1)
        echo "Python venv 正在部署中..."
        python_venv_deploy
        ;;
    2)
        echo "Python uv 正在部署中..."
        python_uv_deploy
        ;;
    3)
        echo "Miniconda3 正在部署中..."
        miniconda3_deploy
        ;;
    4)
        echo "Virtualenv 正在部署中..."
        virtualenv_deploy
        ;;
    *)
        echo "无效选项。"
        ;;
esac

