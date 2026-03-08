#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-01 16:57:14
# @version     : bash
# @Update time :
# @Description : 安装 Google Chrome


echo "开始安装 Google Chrome..."

detect_pkg_manager() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    else
        echo "unsupported"
    fi
}

PKG_MANAGER=$(detect_pkg_manager)
TEMP_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

if [ "$PKG_MANAGER" = "apt" ]; then
    cd "$TEMP_DIR"
    echo "正在下载 Google Chrome..."
    wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O chrome.deb
    sudo dpkg -i chrome.deb
    sudo apt-get install -f -y

elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
    cd "$TEMP_DIR"
    echo "正在下载 Google Chrome..."
    wget -c https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O chrome.rpm
    echo "正在安装依赖..."
    sudo $PKG_MANAGER install -y liberation-fonts
    sudo rpm -ivh chrome.rpm
    if [ $? -ne 0 ]; then
        sudo $PKG_MANAGER install -y --allmatches chrome.rpm
    fi

else
    echo "不支持的包管理器，请使用 apt、yum 或 dnf"
    exit 1
fi

if command -v google-chrome &> /dev/null; then
    echo "========================================"
    echo "Google Chrome 安装成功！"
    google-chrome --version
    echo "========================================"
else
    echo "安装失败"
    exit 1
fi
