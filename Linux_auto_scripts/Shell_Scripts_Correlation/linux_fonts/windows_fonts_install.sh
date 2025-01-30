#!/bin/bash

sudo apt install unzip wget

wget -c http://web.808066.xyz:200/d/%E5%AD%97%E4%BD%93/windows_fonts.zip

unzip windows_fonts.zip

sudo mkdir /usr/share/fonts/windows_fonts

ls -la /usr/share/fonts/

sudo cp ./windows_fonts/*.ttf ./windows_fonts/*.TTF /usr/share/fonts/windows_fonts
ls -la /usr/share/fonts/windows_fonts/

sudo rm -rf windows_fonts.zip
sudo rm -rf windows_fonts

sudo fc-cache -fv
if [ $? -eq 0 ]; then echo "安装字体完成！"; else echo "安装失败，系统缺少 fc-cache 命令，执行：sudo apt install fontconfig 或 sudo dnf install fontconfig"; exit 1; fi
