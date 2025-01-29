#!/bin/bash

sudo apt install unzip wget

wget -c http://web.808066.xyz:200/d/%E5%AD%97%E4%BD%93/windows_fonts.zip

unzip windows_fonts.zip

sudo mkdir /usr/share/fonts/windows_fonts

ls -la /usr/share/fonts/

sudo cp ./windows_fonts/*.ttf ./windows_fonts/*.TTF /usr/share/fonts/windows_fonts
ls -la /usr/share/fonts/windows_fonts/

sudo fc-cache -fv

sudo rm -rf windows_fonts.zip

echo "安装字体完成！"