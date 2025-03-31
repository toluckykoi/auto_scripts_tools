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

wget -c http://web.808066.xyz:200/d/Fonts/windows_fonts.zip

unzip windows_fonts.zip

sudo mkdir /usr/share/fonts/windows_fonts

ls -la /usr/share/fonts/

sudo cp ./windows_fonts/*.ttf ./windows_fonts/*.TTF /usr/share/fonts/windows_fonts
ls -la /usr/share/fonts/windows_fonts/

sudo rm -rf windows_fonts.zip
sudo rm -rf windows_fonts

sudo fc-cache -fv
if [ $? -eq 0 ]; then echo "安装字体完成！"; else echo "安装失败，系统缺少 fc-cache 命令，执行：sudo apt install fontconfig 或 sudo dnf install fontconfig"; exit 1; fi
