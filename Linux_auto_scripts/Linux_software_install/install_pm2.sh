#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-08 18:52:27
# @version     : bash
# @Update time :
# @Description : 安装 pm2 管理工具


# 检查是否已安装 node
if ! command -v node &> /dev/null; then
    echo "错误：未检测到 Node.js，请先安装 Node.js 再运行此脚本。"
    exit 1
fi

echo "检测到 Node.js，版本：$(node -v)"
echo "正在配置 npm 镜像并安装 pm2..."

# 设置 npm 镜像（使用 npmmirror + taobao）
npm config set registry https://registry.npmmirror.com
npm install -g nrm
nrm use taobao

# 安装 pm2
npm install -g pm2

if [ $? -eq 0 ]; then
    echo "✅ pm2 安装成功，版本：$(pm2 -v)"
else
    echo "❌ pm2 安装失败，请检查网络或权限。"
    exit 1
fi
