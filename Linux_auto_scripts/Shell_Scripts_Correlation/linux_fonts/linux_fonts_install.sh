#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-01 00:49:00
# @version     : bash
# @Update time : 
# @Description : 安装字体


# 检测包管理器并安装 unzip 和 wget
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y unzip wget
elif command -v yum &> /dev/null; then
    sudo yum install -y unzip wget
elif command -v dnf &> /dev/null; then
    sudo dnf install -y unzip wget
else
    echo "无法找到支持的包管理器 (apt, yum 或 dnf)"
    exit 1
fi

mkdir ./my_Fonts
cd ./my_Fonts

wget -c http://web.808066.xyz:200/d/Fonts/CascadiaCode-2111.01.zip
wget -c http://web.808066.xyz:200/d/Fonts/JetBrainsMono-2.304.zip

mkdir ./fonts_CascadiaCode
mkdir ./fonts_JetBrainsMono

unzip CascadiaCode-2111.01.zip -d ./fonts_CascadiaCode/
unzip JetBrainsMono-2.304.zip -d ./fonts_JetBrainsMono/

sudo mkdir /usr/share/fonts/CascadiaCode
sudo mkdir /usr/share/fonts/JetBrainsMono

ls -la /usr/share/fonts/

sudo cp ./fonts_CascadiaCode/ttf/*.ttf /usr/share/fonts/CascadiaCode
ls -la /usr/share/fonts/CascadiaCode/
sudo cp ./fonts_JetBrainsMono/fonts/ttf/*.ttf /usr/share/fonts/JetBrainsMono
ls -la /usr/share/fonts/JetBrainsMono

sudo rm -rf ../my_Fonts

sudo fc-cache -fv
if [ $? -eq 0 ]; then echo "安装字体完成！"; else echo "安装失败，系统缺少 fc-cache 命令，执行：sudo apt install fontconfig 或 sudo dnf install fontconfig"; exit 1; fi

# fc-list | grep CascadiaCode

# 字体设置：
# 'Cascadia Code'
# 'JetBrains Mono'
