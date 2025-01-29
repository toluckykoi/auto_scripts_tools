#!/bin/bash


sudo apt install unzip wget

mkdir ./my_Fonts
cd ./my_Fonts

wget -c http://web.808066.xyz:200/d/%E5%AD%97%E4%BD%93/CascadiaCode-2111.01.zip
wget -c http://web.808066.xyz:200/d/%E5%AD%97%E4%BD%93/JetBrainsMono-2.304.zip

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

sudo fc-cache -fv

# fc-list | grep CascadiaCode

echo "安装字体完成！"


# 字体设置：
# 'Cascadia Code'
# 'JetBrains Mono'