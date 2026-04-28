#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-04-28 22:24:46
# @version     : bash
# @Update time :
# @Description : VM虚拟机共享文件夹挂载（支持多共享文件夹）


set -e

# 检查是否以root运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "\033[31m错误: 此脚本需要root权限运行\033[0m"
        echo "请使用: sudo $0"
        exit 1
    fi
}

# 检查vmware-hgfsclient是否存在
check_hgfsclient() {
    if ! command -v vmware-hgfsclient &> /dev/null; then
        echo "错误: vmware-hgfsclient 未找到"
        echo "请确保已安装 VMware Tools"
        exit 1
    fi
}

# 获取共享文件夹列表
get_shared_folders() {
    mapfile -t SHARES < <(vmware-hgfsclient)
    if [[ ${#SHARES[@]} -eq 0 ]]; then
        echo "错误: 没有找到任何共享文件夹"
        echo "请先在 VMware 中配置共享文件夹"
        exit 1
    fi
}

# 显示菜单并让用户选择
select_share() {
    echo "========================================"
    echo "       可用的共享文件夹列表        "
    echo "========================================"
    for i in "${!SHARES[@]}"; do
        echo "  $((i+1)). ${SHARES[$i]}"
    done
    echo "========================================"
    echo ""

    while true; do
        read -ep "请输入要挂载的序号 [1-${#SHARES[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#SHARES[@]} ]]; then
            SELECTED_SHARE="${SHARES[$((choice-1))]}"
            break
        else
            echo "无效选择，请输入 1-${#SHARES[@]} 之间的数字"
        fi
    done
    echo "已选择: $SELECTED_SHARE"
}

# 创建挂载点
create_mount_point() {
    MOUNT_POINT="/mnt/hgfs/$SELECTED_SHARE"
    if [[ ! -d "$MOUNT_POINT" ]]; then
        echo "创建挂载点: $MOUNT_POINT"
        mkdir -p "$MOUNT_POINT"
        # 尝试设置普通用户权限 (uid=1000可根据实际调整)
        if [[ -n "$SUDO_USER" ]]; then
            chown -R "$SUDO_USER:$SUDO_USER" "$MOUNT_POINT"
        else
            chown -R 1000:1000 "$MOUNT_POINT"
        fi
    else
        echo "挂载点已存在: $MOUNT_POINT"
    fi
}

# 挂载共享文件夹
do_mount() {
    echo "正在挂载共享文件夹..."
    if mount | grep -q "$MOUNT_POINT"; then
        echo "警告: $MOUNT_POINT 已被挂载"
        return 0
    fi

    # 挂载命令
    mount -t fuse.vmhgfs-fuse .host:/"$SELECTED_SHARE" "$MOUNT_POINT" \
        -o allow_other,uid=1000,gid=1000,umask=022,entry_timeout=3,negative_timeout=3,attr_timeout=3,defaults

    if mount | grep -q "$MOUNT_POINT"; then
        echo "挂载成功!"
    else
        echo "错误: 挂载失败"
        exit 1
    fi
}

# 添加到fstab实现持久挂载
add_to_fstab() {
    FSTAB_LINE=".host:/$SELECTED_SHARE $MOUNT_POINT fuse.vmhgfs-fuse allow_other,uid=1000,gid=1000,umask=022,entry_timeout=3,negative_timeout=3,attr_timeout=3,defaults 0 0"

    if grep -v '^#' /etc/fstab | grep -q ".host:/$SELECTED_SHARE"; then
        echo "/etc/fstab 中已存在该挂载条目，跳过"
    else
        echo "" >> /etc/fstab
        echo "# VMware Shared Folder: $SELECTED_SHARE" >> /etc/fstab
        echo "$FSTAB_LINE" >> /etc/fstab
        echo "" >> /etc/fstab
        echo "已添加到 /etc/fstab"
    fi
}

# 主函数
main() {
    check_root
    check_hgfsclient
    get_shared_folders
    select_share
    create_mount_point
    do_mount
    add_to_fstab

    echo ""
    echo "========================================"
    echo "           挂载完成                  "
    echo "========================================"
    echo "挂载点: $MOUNT_POINT"
    echo "查看内容: ls $MOUNT_POINT"
}

main "$@"
