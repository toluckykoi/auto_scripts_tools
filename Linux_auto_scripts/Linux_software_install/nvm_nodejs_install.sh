#!/bin/bash
# @Author: 蓝陌
# @Date:   2024-07-20 16:30:35
# @Last Modified time: 2024-11-10 17:30:35
# nvm 安装脚本，同时安装 nodejs v16.20.2 和 pm2 管理


[ $(id -u) -eq 0 ] && echo "请不要使用 sudo 或 root 来执行此脚本！" && exit 1

function init_nodejs(){
    nvm alias default $node_version
    echo "nodejs v16.20.2 安装成功，版本信息：$(node -v)"
    echo "npm 版本信息：$(npm -v)"
    read -ep  "是否安装 pm2 管理(yes/no): " letter
    if [ "$letter" == "yes" ]; then
        install_pm2
    else
        echo "完成."
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
    fi
}

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
if [ $? -eq 0 ]; then
    sleep 3
    echo '' >> ~/.bashrc
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    source ~/.bashrc
    echo "source ~/.bashrc"
    echo "nvm 安装成功，版本信息：$(nvm -v)"
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
