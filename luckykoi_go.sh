#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-09-20 23:25:25
# @version     : bash
# @Update time :
# @Description : 快捷一键安装和配置脚本,只需一条命令即可完成!


set -euo pipefail 
WORKSPACE_DIR="/tmp/auto_scripts_tools/"
REPO_URL="https://gitee.com/toluckykoi/auto_scripts_tools.git"
MAX_RETRIES=3
RETRY_DELAY=5

if [ -d "$WORKSPACE_DIR" ]; then
    sudo rm -rf "$WORKSPACE_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to del directory $WALLPAPER_DIR" >&2
        exit 1
    fi
fi

cd /tmp
attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    if git clone "$REPO_URL" ; then
        chmod +x -R auto_scripts_tools
        echo "仓库拉取完成."
        break
    else
        echo "仓库拉取失败!"

        if [ $attempt -eq $MAX_RETRIES ]; then
            echo "已达到最大重试次数 ($MAX_RETRIES), 仓库拉取失败!"
            exit 1
        fi

        echo "等待 $RETRY_DELAY 秒后重试..."
        sleep $RETRY_DELAY
        attempt=$((attempt + 1))
    fi
done

# 1.快速更换系统镜像源:
function change_system_source(){
    cd /tmp/auto_scripts_tools/
    ./Linux_auto_scripts/Shell_Scripts_Correlation/change_source_mirror.sh
}

# 2.快速设置pip加速源:
function change_pip_source(){
    cd /tmp/auto_scripts_tools/
    pip config set global.index-url https://mirrors.huaweicloud.com/repository/pypi/simple
}

function check_sys_info(){
    cd /tmp/auto_scripts_tools/
    ./Linux_auto_scripts/Shell_Scripts_Correlation/system_info.sh
}


case "${1:-}" in
    source)
        echo "快速更换系统镜像源..."
        change_system_source
        ;;
    pip)
        echo "快速设置pip加速源..."
        change_pip_source
        ;;
    sysinfo)
        echo "快速查看系统信息..."
        check_sys_info
        ;;
    "" | -h | --help)
        echo "Usage: $0 {source|pip|sysinfo}"
        exit 0
        ;;
    *)
        echo "Invalid option: $1"
        exit 1
        ;;
esac
