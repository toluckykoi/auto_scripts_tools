#!/bin/bash


curl -s https://install.zerotier.com | sudo bash

# 在基于 UNIX 的操作系统上，这需要 .在 Windows 上，这需要管理员命令提示符。sudo
# 加入、离开和列出网络。请记住，ZeroTier 网络是 16 位 ID，如下所示8056c1221c000001
# zerotier-cli join 8056c1221c000001
# 200 人加入 OK

# zerotier-cli leave ################
# 200 离开 OK

# zerotier-cli listnetworks
# 200 listnetworks 8056c1221c000001 earth.zerotier.net 02：99：35：84：f9：dc OK PUBLIC 29.152.27.109/7

# debian 需要安装：apt install fonts-liberation libu2f-udev

