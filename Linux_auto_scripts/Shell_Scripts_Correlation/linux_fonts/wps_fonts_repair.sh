#!/bin/bash

sudo apt install unzip wget

wget -c http://web.808066.xyz:200/d/%E5%AD%97%E4%BD%93/wps_symbol_fonts.zip

unzip wps_symbol_fonts.zip

sudo mkdir /usr/share/fonts/wps_symbol_fonts

ls -la /usr/share/fonts/

sudo cp ./wps_symbol_fonts/*.ttf ./wps_symbol_fonts/*.TTF /usr/share/fonts/wps_symbol_fonts
ls -la /usr/share/fonts/wps_symbol_fonts/

sudo fc-cache -fv

sudo rm -rf wps_symbol_fonts.zip

echo "安装字体完成！"