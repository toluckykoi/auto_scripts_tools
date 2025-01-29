#!/bin/bash
# @Author: 幸运锦鲤
# @Date:   2024-11-12 22:32:35
# @Last Modified time:
# Debian 系安装EMQX


sudo apt update
sudo apt install -y curl
curl -s https://assets.emqx.com/scripts/install-emqx-deb.sh | sudo bash
sudo apt-get install emqx
sudo systemctl start emqx
