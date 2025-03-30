#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-03-30 15:45:10
# @version     : bash
# @Update time : 
# @Description : 简化版Linux主机名修改脚本


if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要root权限执行，请使用sudo运行。"
    exit 1
fi

generate_hostname() {
    DISTRO=$(grep '^NAME=' /etc/os-release | cut -d'"' -f2 | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -cd '[:alnum:]-')
    
    RAND_CHARS=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
    
    echo "${DISTRO}-${RAND_CHARS}" | cut -c 1-63
}

validate_hostname() {
    local hostname=$1
    
    if [ -z "$hostname" ]; then
        echo "错误：主机名不能为空！"
        return 1
    fi
    
    if [ "${#hostname}" -gt 63 ]; then
        echo "错误：主机名长度不能超过63个字符！"
        return 1
    fi
    
    if ! echo "$hostname" | grep -qE '^[a-zA-Z0-9-]+$'; then
        echo "错误：主机名只能包含字母、数字和连字符(-)！"
        return 1
    fi
    
    if [[ "$hostname" == -* || "$hostname" == *- ]]; then
        echo "错误：主机名不能以连字符开头或结尾！"
        return 1
    fi
    
    return 0
}

change_hostname() {
    local old_hostname new_hostname
    
    old_hostname=$(hostname)
    new_hostname=$1
    
    echo "当前主机名: $old_hostname"
    echo "新主机名: $new_hostname"
    
    echo "正在修改主机名..."
    
    if ! hostnamectl set-hostname "$new_hostname"; then
        echo "错误：hostnamectl设置失败！"
        exit 1
    fi
    
    echo "$new_hostname" > /etc/hostname || {
        echo "错误：无法写入/etc/hostname文件！"
        exit 1
    }
    
    if grep -q "127.0.1.1" /etc/hosts; then
        sed -i "s/127.0.1.1\s.*$/127.0.1.1 $new_hostname/g" /etc/hosts || {
            echo "错误：无法更新/etc/hosts文件！"
            exit 1
        }
    else
        echo "127.0.1.1 $new_hostname" >> /etc/hosts || {
            echo "错误：无法追加到/etc/hosts文件！"
            exit 1
        }
    fi
    
    echo "主机名已成功修改为: $(hostname)"
    exit 0
}

# 主界面
clear
echo "Linux主机名修改工具"
echo "===================="
echo "1. 手动输入新主机名"
echo "2. 自动生成主机名"
echo "===================="

read -ep "请选择操作[1-2]: " choice

case $choice in
    1)
        read -ep "请输入新的主机名: " new_hostname
        if validate_hostname "$new_hostname"; then
            change_hostname "$new_hostname"
        else
            exit 1
        fi
        ;;
    2)
        new_hostname=$(generate_hostname)
        echo "自动生成的主机名: ${new_hostname}"
        change_hostname "$new_hostname"
        ;;
    *)
        echo "无效的选择！"
        exit 1
        ;;
esac
