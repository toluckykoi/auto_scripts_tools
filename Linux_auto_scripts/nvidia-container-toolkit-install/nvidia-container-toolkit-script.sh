#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-03-23 16:20:42
# @version     : bash
# @Update time : 
# @Description : nvidia-container-toolkit 国内镜像源安装


if command -v apt >/dev/null 2>&1; then
    software_manager=apt
elif command -v yum >/dev/null 2>&1; then
    software_manager=redhat
elif command -v dnf >/dev/null 2>&1; then
    software_manager=redhat
else
    echo "未检测到apt、yum或dnf，请手动安装依赖"
    exit 1
fi

if [ "$software_manager" == "apt" ]; then
    curl -fsSL https://mirrors.ustc.edu.cn/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    if [ $? -eq 0 ]; then
        echo "配置 GPG 密钥文件成功."
    else
        echo "配置 GPG 密钥文件失败，请手动解决 GPG 密钥."
        exit
    fi

    curl -s -L https://mirrors.ustc.edu.cn/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://nvidia.github.io#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://mirrors.ustc.edu.cn#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    nvidia-container-cli --version
    if [ $? -eq 0 ]; then
        echo ''
        echo "nvidia-container-toolkit 安装成功."
    else
        echo ''
        echo "nvidia-container-toolkit 安装失败."
        exit
    fi

elif [ "$software_manager" == "redhat" ]; then
    curl -s -L https://mirrors.ustc.edu.cn/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
    sed 's#nvidia.github.io/libnvidia-container/stable/#mirrors.ustc.edu.cn/libnvidia-container/stable/#g' |
    sed 's#nvidia.github.io/libnvidia-container/experimental/#mirrors.ustc.edu.cn/libnvidia-container/experimental/#g' |
    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
    if [ $? -eq 0 ]; then
        echo "导入nvidia-container-toolkit 源成功."
        sudo yum install nvidia-container-toolkit
        nvidia-container-cli --version
    else
        echo "导入nvidia-container-toolkit 源失败."
        exit 1
    fi

else
    echo '未知包管理器.'

fi
