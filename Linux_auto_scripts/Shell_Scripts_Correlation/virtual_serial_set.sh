#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-12-06 18:50:00
# @version     : bash
# @Update time :
# @Description : Linux 配置虚拟串口


if [ "$(id -u)" -eq 0 ]; then
    echo "错误：该脚本禁止使用 sudo/root 权限运行！" >&2
    exit 1
fi

echo "=== 创建虚拟串口(使用 /dev/ttyCOM0 - /dev/ttyCOM1) ==="

if ! command -v socat &> /dev/null; then
    echo "socat 未安装，尝试安装..."
    
    # 检测包管理器并安装
    if command -v apt &> /dev/null; then
        echo "检测到 apt 包管理器"
        sudo apt update
        if sudo apt install -y socat; then
            echo "✓ socat 安装成功"
        else
            echo "✗ socat 安装失败"
            exit 1
        fi
    elif command -v yum &> /dev/null; then
        echo "检测到 yum 包管理器"
        if sudo yum install -y socat; then
            echo "✓ socat 安装成功"
        else
            echo "✗ socat 安装失败"
            exit 1
        fi
    elif command -v dnf &> /dev/null; then
        echo "检测到 dnf 包管理器"
        if sudo dnf install -y socat; then
            echo "✓ socat 安装成功"
        else
            echo "✗ socat 安装失败"
            exit 1
        fi
    elif command -v pacman &> /dev/null; then
        echo "检测到 pacman 包管理器"
        if sudo pacman -Sy --noconfirm socat; then
            echo "✓ socat 安装成功"
        else
            echo "✗ socat 安装失败"
            exit 1
        fi
    elif command -v zypper &> /dev/null; then
        echo "检测到 zypper 包管理器"
        if sudo zypper install -y socat; then
            echo "✓ socat 安装成功"
        else
            echo "✗ socat 安装失败"
            exit 1
        fi
    else
        echo "无法识别的包管理器，请手动安装 socat："
        echo "Ubuntu/Debian: sudo apt install socat"
        echo "RHEL/CentOS/Fedora: sudo yum install socat 或 sudo dnf install socat"
        echo "Arch Linux: sudo pacman -S socat"
        echo "openSUSE: sudo zypper install socat"
        exit 1
    fi
fi

# 1. 检查用户是否在dialout组
if ! groups "$USER" | grep -q dialout; then
    echo "将用户添加到dialout组..."
    sudo usermod -a -G dialout "$USER"
    echo "请重新登录使更改生效，或使用以下命令："
    echo "  newgrp dialout"
    read -p "是否继续？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 2. 清理旧的虚拟串口（覆盖 /dev/ttyCOM0 到 /dev/ttyCOM100）
echo "清理旧的虚拟串口（/dev/ttyCOM*）..."
sudo pkill -f "socat.*ttyCOM"
for i in {0..100}; do
    sudo rm -f "/dev/ttyCOM$i"
done

# 3. 创建虚拟串口对：COM0 ↔ COM1
echo "创建虚拟串口 /dev/ttyCOM0 和 /dev/ttyCOM1 ..."
sudo socat -d -d pty,raw,echo=0,link=/dev/ttyCOM0,perm=666 pty,raw,echo=0,link=/dev/ttyCOM1,perm=666 > /tmp/socat.log 2>&1 &
SOCAT_PID=$!

sleep 2

# 5. 设置正确权限（即使link已设perm=666，仍显式设置更可靠）
echo "设置设备权限..."
sudo chmod 666 /dev/ttyCOM0 /dev/ttyCOM1
sudo chown root:dialout /dev/ttyCOM0 /dev/ttyCOM1

# 4. 验证设备创建
echo "验证设备创建..."
if [ -e /dev/ttyCOM0 ] && [ -e /dev/ttyCOM1 ]; then
    echo "✓ 虚拟串口创建成功："
    echo "  /dev/ttyCOM0 -> $(readlink -f /dev/ttyCOM0)"
    echo "  /dev/ttyCOM1 -> $(readlink -f /dev/ttyCOM1)"
else
    echo "✗ 设备创建失败，检查日志："
    cat /tmp/socat.log
    exit 1
fi

# 6. 测试通信
echo -e "\n=== 测试虚拟串口通信 ==="
echo "在另一个终端执行以下命令进行测试："
echo "1. 监听端口： cat /dev/ttyCOM1"
echo "2. 发送数据： echo 'Hello World' > /dev/ttyCOM0"
echo "3. 查看监听终端响应"

# 7. 保持后台运行
echo -e "\n虚拟串口正在后台运行, PID: $SOCAT_PID"
echo "要停止虚拟串口，执行： sudo kill $SOCAT_PID"
echo "日志文件： /tmp/socat.log"

# 8. 创建停止脚本
sudo rm -f /tmp/stop_virtual_serial.sh
cat > /tmp/stop_virtual_serial.sh << 'EOF'
#!/bin/bash
echo "停止虚拟串口（/dev/ttyCOM*）..."

# 终止当前用户的 socat 进程（匹配 ttyCOM）
sudo pkill -f "socat.*link=/dev/ttyCOM"

# 清理设备节点（普通用户可删自己创建的符号链接）
for i in {0..100}; do
    if [ -L "/dev/ttyCOM$i" ] || [ -e "/dev/ttyCOM$i" ]; then
        sudo rm -f "/dev/ttyCOM$i"
    fi
done

echo "已停止虚拟串口。"
EOF

chmod +x /tmp/stop_virtual_serial.sh
echo "停止脚本： /tmp/stop_virtual_serial.sh"
