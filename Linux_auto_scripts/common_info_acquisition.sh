#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-28 22:30:57
# @version     : bash
# @Update time :
# @Description : 记录Linux中常用获取信息条件(统一标准)


# 获取当前系统登录用户名
CURRENT_USER=${SUDO_USER:-$(whoami)}
echo "当前用户：${CURRENT_USER}"

# 获取当前系统登录的主目录
USER_HOME_DIR=$(eval echo "~$CURRENT_USER")
echo "当前用户家目录：${USER_HOME_DIR}"

# 获取当前脚本运行的目录
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo "当前脚本运行目录：${SCRIPT_DIR}"

# 提取并输出当前 Linux 操作系统的发行版 ID（名称）
DISTRO_ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')

# 提取并输出当前 Linux 操作系统的具体版本号
VERSION_ID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F '=' '{print $2}' | sed 's/"//g')

# 显示当前计算机的硬件架构（机器类型）
ARCH_TYPE=$(
    m=$(uname -m)
    if [ "$m" = "x86_64" ]; then
        echo "amd64"
    elif [ "$m" = "aarch64" ] || [ "$m" = "arm64" ]; then
        echo "arm64"
    else
        echo "unknown"
    fi
)

# 获取当前系统的包管理工具
PKG_MANAGER=$(
    if command -v apt > /dev/null 2>&1; then
        echo "apt"
    elif command -v apt-get > /dev/null 2>&1; then
        echo "apt-get"
    elif command -v dnf > /dev/null 2>&1; then
        echo "dnf"
    elif command -v yum > /dev/null 2>&1; then
        echo "yum"
    elif command -v pacman > /dev/null 2>&1; then
        echo "pacman"
    elif command -v brew > /dev/null 2>&1; then
        echo "brew"
    elif command -v apk > /dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
)

