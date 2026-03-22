#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-12-23 22:43:49
# @version     : bash
# @Update time :
# @Description : 修复 CH340/CH341 设备被 brltty 占用


set -e

echo "🔍 检查 brltty 是否正在干扰 CH340/CH341 设备..."

# 检查 brltty 服务状态
if systemctl is-active --quiet brltty; then
    echo "⚠️ brltty 服务正在运行，正在停止并禁用..."
else
    echo "✅ brltty 未在运行，但将继续确保其被屏蔽以防干扰。"
fi

# 停止并屏蔽 brltty
sudo systemctl stop brltty brltty-udev 2>/dev/null || true
sudo systemctl disable brltty brltty-udev 2>/dev/null || true
sudo systemctl mask brltty brltty-udev

echo "🛡️ brltty 已被屏蔽，不会再占用 USB 串口设备。"

# 可选：卸载 brltty（取消注释下一行即可启用）
# sudo apt remove --purge -y brltty brltty-udev

# 提示用户操作
echo ""
echo "🔌 请拔下你的 CH340/CH341 设备（如 Arduino、ESP、USB转串口模块），然后重新插入。"
echo "📌 之后可通过以下命令确认设备是否识别："
echo "   dmesg | tail"
echo "   ls /dev/ttyUSB*"
echo ""
echo "✅ 修复完成！"
