#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-08 17:18:10
# @version     : bash
# @Update time :
# @Description : nodejs 一键安装脚本


if [ $(id -u) -eq 0 ]; then
    read -p "警告：检测到您正在使用 root 或 sudo 运行此脚本。是否仍要继续？(yes/no): " confirm
    if [[ "$confirm" != "yes" && "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "已取消安装。"
        exit 1
    else
        echo "警告：您已选择以 root 身份继续安装，可能存在风险。"
        sleep 3
    fi
fi

function init_nodejs(){
    cat << 'EOF' >> ~/.bashrc

# Configure the domestic mirror source (npmmirror) for Node.js and npm
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
export NVM_NPM_MIRROR=https://npmmirror.com/mirrors/npm

EOF

    nvm alias default $node_version
    npm config set registry https://registry.npmmirror.com
    npm install -g pnpm

    echo ""
    echo "nodejs 安装成功，版本信息：$(node -v)"
    echo "npm 版本信息：$(npm -v)"
    echo "pnpm 版本信息：$(pnpm -v)"
    read -ep  "是否安装 pm2 管理工具(yes/no): " letter
    if [[ "$letter" == "y" || "$letter" == "yes" ]]; then
        install_pm2
    else
        echo "处理完成."
    fi
}

function install_pm2(){
    # 安装 pm2 管理工具
    echo "安装 pm2 管理工具"
    # 原始源
    # npm config set registry https://registry.npmjs.org
    npm config set registry https://registry.npmmirror.com
    npm install -g nrm
    nrm ls
    nrm test
    nrm use taobao

    npm install pm2 -g
    if [ $? -eq 0 ]; then
        source ~/.bashrc
        echo "pm2 安装成功，版本信息：$(pm2 -v)"
    else
        echo "pm2 安装失败......"
        exit 1
    fi
}

# 检查是否已安装 nvm
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "检测到已安装的 nvm，正在加载..."
    \. "$NVM_DIR/nvm.sh"                # 加载 nvm 函数
    echo "nvm 已加载，版本：$(nvm -v)"
    exit 0
else
    echo "nvm 未安装，开始安装..."
fi

# 安装 nvm
curl -o- http://github.808066.xyz:38000/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
if [ $? -eq 0 ]; then
    sleep 3
    echo '' >> ~/.bashrc
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    source ~/.bashrc
    echo "source ~/.bashrc"
    echo "nvm 安装成功，版本信息：$(nvm -v)"

    export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
    export NVM_NPM_MIRROR=https://npmmirror.com/mirrors/npm

    nvm cache clear

    read -ep "请输入需要安装的 nodejs 版本(留空默认安装并设置默认版本为nodejs 16)：" node_version
    if [ -z "$node_version" ]; then
        echo "未输入任何内容，默认安装 Node.js 16 版本。"
        node_version="16"
    elif ! [[ "$node_version" =~ ^[0-9]+$ ]]; then
        echo "错误: 输入的内容不是有效的数字。请重新运行脚本并输入一个有效的 Node.js 版本。"
        read -ep "请输入需要安装的 nodejs 版本(留空默认安装并设置默认版本为nodejs 16)：" node_version
        if [ -z "$node_version" ]; then
            echo "未输入任何内容，默认安装 Node.js 16 版本。"
            node_version="16"
        fi
    fi
    nvm install $node_version
    
    if [ $? -eq 0 ]; then
        init_nodejs
    else
        echo "nodejs $node_version 安装失败，第一次重试..."
        nvm install $node_version
        init_nodejs
    fi

else
    echo "nvm 安装失败，可能网络原因，请重新运行脚本或者手动检查问题！"
    exit 1
fi
