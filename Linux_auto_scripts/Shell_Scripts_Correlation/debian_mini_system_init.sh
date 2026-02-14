#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-02-14 17:09:11
# @version     : bash
# @Update time :
# @Description : debian 最小化系统初始脚本（只对sudo进行初始化）


ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')

function debian_sudo(){
    echo ""; echo ""
    if [ "$ID" == "debian" ]; then
        echo "####################sudo 相关配置####################"
        if command -v sudo >/dev/null 2>&1; then
            debian_sudo=sudo
            echo "sudo 已安装."
        else
            echo "未检测到sudo，正在安装....."
            apt install -y sudo
            echo "sudo 安装完成."
        fi

        NORMAL_USER=$(awk -F: '$3 >= 1000 && $1 != "nobody" && $3 < 65534 {print $1; exit}' /etc/passwd)
        if [ -z "$NORMAL_USER" ]; then
            echo "未找到普通用户, 无需配置 sudo."
            exit 1
        fi
        
        su - $NORMAL_USER -c 'sudo -v'
        if [ $? -eq 0 ]; then
            echo "普通用户已有sudo 权限, 无需配置 sudo."
        else
            echo "正在配置普通用户 sudo 权限..."
            # 创建 sudoers 规则文件（Debian/Ubuntu 使用 'sudo' 组，RHEL/CentOS 用 'wheel'）
            # 这里以 Debian/Ubuntu 为例：允许用户执行所有命令，需输密码
            RULE_FILE="/etc/sudoers.d/$NORMAL_USER"

            # 写入规则（使用 here-document + chmod 保证安全）
            cat > "$RULE_FILE" <<EOF
# Grant sudo access to user $NORMAL_USER
$NORMAL_USER ALL=(ALL:ALL) ALL
EOF
            # 必须设置权限为 0440（sudo 要求）
            chmod 440 "$RULE_FILE"

            echo "已授予用户 '$NORMAL_USER' sudo 权限（需输入密码）"
            echo "规则文件: $RULE_FILE"
        fi
        
    else
        echo "不是 Debian 系统，不需要配置！"
    fi
}


debian_sudo
