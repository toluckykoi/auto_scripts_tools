#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-02 00:53:20
# @version     : bash
# @Update time :
# @Description : 安装 openclaw 环境


# 检查 node 是否存在
if ! command -v node &> /dev/null; then
    echo "Error: node 未安装，请先安装 Node.js（建议版本 >= 22）"
    echo "可以使用以下命令安装 Node.js："
    echo "1、cd auto_scripts_tools/Linux_auto_scripts/Linux_software_install"
    echo "2、./nvm_nodejs_install.sh"
    exit 1
fi

# 获取 node 版本
node_version=$(node -v | sed 's/^v//')
# 使用 sort -V 进行版本比较
if [ "$(printf '%s\n' "22" "$node_version" | sort -V | head -n1)" != "22" ]; then
    echo "Error: 当前 node 版本为 $node_version，但 openclaw 要求版本 >= 22"
    exit 1
fi

if command -v node &> /dev/null; then
    echo "npm源加速..."
    npm config set registry https://registry.npmmirror.com
fi

echo "正在安装 openclaw..."
curl -sSL https://openclaw.ai/install.sh | bash
