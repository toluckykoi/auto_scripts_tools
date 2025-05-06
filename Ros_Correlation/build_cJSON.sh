#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-22 11:21:36
# @version     : bash
# @Update time :
# @Description : cJSON 编译安装


REPO_URL="https://git.toluckykoi.com/library/cJSON.git"
PROJECT_NAME="cJSON"
CLEAN_BUILD=false
RECLONE=false
JOBS=$(nproc)  # 默认使用所有 CPU 核心

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j*)
            JOBS="${1#-j}"
            ;;
        --clean)
            CLEAN_BUILD=true
            ;;
        --reclone)
            RECLONE=true
            ;;
        -h|--help)
            echo "用法: $0 [-j<线程数>] [--clean] [--reclone]"
            echo "示例: $0 -j1 --clean"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
    shift
done

cd $HOME || { echo "无法进入 \$HOME"; exit 1; }

if [ "$RECLONE" = true ]; then
    echo "正在强制重新克隆 $PROJECT_NAME..."
    rm -rf "$PROJECT_NAME"
fi

if [ ! -d "$PROJECT_NAME" ]; then
    echo "正在克隆仓库..."
    git clone "$REPO_URL" "$PROJECT_NAME" || { echo "克隆失败"; exit 1; }
else
    echo "项目已存在: $PROJECT_NAME"
fi

cd "$PROJECT_NAME" || { echo "无法进入 $PROJECT_NAME"; exit 1; }

if [ "$CLEAN_BUILD" = true ]; then
    echo "正在清理 build 目录..."
    sudo rm -rf build
    exit 1
fi

mkdir -p build && cd build || { echo "无法创建 build 目录"; exit 1; }

echo "运行 CMake 配置..."
cmake .. || { echo "CMake 配置失败"; exit 1; }

echo "使用 $JOBS 个线程进行编译..."
make -j$JOBS || { echo "编译失败"; exit 1; }

echo "正在安装 cJSON..."
sudo make install || { echo "安装失败"; exit 1; }

echo "查找 cJSON.h 的安装位置..."
sudo find /usr -name "cJSON.h"

echo "✅ cJSON 编译完成..."
