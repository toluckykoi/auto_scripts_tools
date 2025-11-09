#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-05-06 11:14:32
# @version     : bash
# @Update time : 2025-08-09 11:14:32
# @Description : 编译安装 opencv 默认安装版本为 4.1.1


read -ep "请输入需要编译安装 OpenCV 版本 (默认 4.1.1): " input_version

if [ -z "$input_version" ]; then
    OPENCV_VERSION="4.1.1"
else
    OPENCV_VERSION="$input_version"
fi

echo "使用的 OpenCV 版本: $OPENCV_VERSION"
sleep 2
REPO_ZIP_URL="http://github.808066.xyz:38000/https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.zip"
PROJECT_NAME="opencv-${OPENCV_VERSION}"
ZIP_NAME="${PROJECT_NAME}.zip"
CLEAN_BUILD=false
REDOWNLOAD=false
JOBS=$(nproc)

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -j*)
            JOBS="${1#-j}"
            ;;
        --clean)
            CLEAN_BUILD=true
            ;;
        --redownload)
            REDOWNLOAD=true
            ;;
        -h|--help)
            echo "Usage: $0 [-j<jobs>] [--clean] [--redownload]"
            echo "Example: $0 -j8 --clean"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            exit 1
            ;;
    esac
    shift
done

echo "更新 apt 包..."
sudo apt update -y || { echo "apt update 失败"; exit 1; }

echo "安装 OpenCV 编译依赖..."
sudo apt-get -y install \
    build-essential libgtk2.0-dev libjpeg-dev libtiff5-dev libopenexr-dev libtbb-dev \
    libavcodec-dev libavformat-dev libswscale-dev libgtk-3-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev pkg-config \
    || { echo "依赖安装失败"; exit 1; }
sudo cp -r /usr/local/include/eigen3/* /usr/include/

cd $HOME || { echo "无法进入 \$HOME"; exit 1; }

if [ "$REDOWNLOAD" = true ]; then
    echo "正在清理已有源码和压缩包..."
    rm -rf "$PROJECT_NAME"
    rm -f "$ZIP_NAME"
    exit 1
fi

if [ ! -f "$ZIP_NAME" ]; then
    echo "正在下载 OpenCV $OPENCV_VERSION 源码..."
    wget -O "$ZIP_NAME" "$REPO_ZIP_URL" || { echo "下载失败"; exit 1; }
else
    echo "OpenCV 压缩包已存在：$ZIP_NAME"
fi

if [ -d "$PROJECT_NAME" ]; then
    echo "OpenCV 源码目录已存在：$PROJECT_NAME"
else
    echo "正在解压 OpenCV 源码..."
    unzip "$ZIP_NAME" || { echo "解压失败"; exit 1; }
fi

cd "$PROJECT_NAME" || { echo "无法进入 $PROJECT_NAME"; exit 1; }

cd build || mkdir build && cd build || { echo "无法创建 build 目录"; exit 1; }

if [ "$CLEAN_BUILD" = true ]; then
    echo "清理 build 目录..."
    rm -rf *
    exit 1
fi

echo "运行 CMake 配置..."
cmake .. || { echo "CMake 配置失败"; exit 1; }

echo "使用 $JOBS 个线程进行编译..."
make -j${JOBS} || { echo "编译失败"; exit 1; }

echo "正在安装 OpenCV 到系统目录..."
sudo make install || { echo "安装失败"; exit 1; }

echo "验证 OpenCV 版本..."
pkg-config opencv --modversion || echo "pkg-config 未找到 opencv，请检查环境变量或安装路径"

echo "✅ OpenCV $OPENCV_VERSION 安装完成！"
