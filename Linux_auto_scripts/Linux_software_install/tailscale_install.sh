#!/bin/bash


curl -fsSL https://tailscale.com/install.sh | sh

#用于启用和启动服务：systemctl
#
# sudo systemctl enable --now tailscaled
#将机器连接到尾鳞网络并在浏览器中进行身份验证：
#
# sudo tailscale up
#您已连接！您可以通过运行以下命令找到您的尾鳞 IPv4 地址：
#
# tailscale ip -4
