#!/bin/bash
# @Author: 幸运的锦鲤
# @Date:   2025-02-23 20:31:06
# @Last Modified time: 
# linux 虚拟内存设置脚本


# 函数：检查当前虚拟内存状态
check_virtual_memory() {
    swap_info=$(free -m | egrep "Swap:|交换：")
    total_swap=$(echo "$swap_info" | awk '{print $2}')
    if [ "$total_swap" -gt 0 ]; then
        echo "当前虚拟内存 (swap) 已启用，总大小: $total_swap MB"
        swapon -s
        return 0
    else
        echo "当前虚拟内存 (swap) 未启用。"
        return 1
    fi
}

# 函数：获取当前虚拟内存路径
get_swap_paths() {
    swapon --show=NAME --noheadings
}

# 函数：创建虚拟内存
create_virtual_memory() {
    local size=$1
    local swapfile="/swapfile$size"G

    echo "正在创建 $size GB 的虚拟内存..."
    dd if=/dev/zero of=$swapfile bs=256M count=$((size * 4))
    mkswap $swapfile
    chmod 0600 $swapfile
    swapon $swapfile
    echo "$swapfile swap swap defaults 0 0" >> /etc/fstab
    echo "虚拟内存创建成功。"
    free -h
}

# 函数：删除虚拟内存
delete_virtual_memory() {
    local swap_paths=$(get_swap_paths)

    if [ -z "$swap_paths" ]; then
        echo "未找到虚拟内存路径，无需删除。"
        return
    fi

    for path in $swap_paths; do
        if [[ $path == /dev/* ]]; then
            echo "检测到交换分区: $path"
            echo "正在从 /etc/fstab 中移除交换分区配置..."
            sed -i '/\/swapfile/d' /etc/fstab
            swapoff $path
            echo "交换分区配置已移除。"
        else
            echo "检测到交换文件: $path"
            echo "正在删除交换文件: $path"
            swapoff $path
            rm -f $path
            sed -i "\|^$path |d" /etc/fstab
            sed -i '/swap/d' /etc/fstab
            echo "交换文件已删除。"
        fi
    done
    echo "虚拟内存删除成功。"
    free -h
}

# 函数：临时关闭虚拟内存
disable_virtual_memory_temporarily() {
    echo "正在临时关闭虚拟内存..."
    swapoff -a
    echo "虚拟内存已临时关闭。"
    free -h
}

# 函数：永久关闭虚拟内存
disable_virtual_memory_permanently() {
    echo "正在永久关闭虚拟内存..."
    swapoff -a
    sed -i '/swap/d' /etc/fstab
    echo "虚拟内存已永久关闭。"
    free -h
}

# 主程序
echo "请选择操作："
echo "1. 设置虚拟内存"
echo "2. 管理虚拟内存"
read -ep "请输入选项 (1 或 2): " option

case $option in
    1)
        read -ep "请输入所需的虚拟内存大小（单位：GB）：" size
        if check_virtual_memory; then
            read -ep "当前已启用虚拟内存，是否删除并重新创建？(y/n): " answer
            if [ "$answer" = "y" ]; then
                delete_virtual_memory
                create_virtual_memory $size
            else
                echo "操作取消。"
            fi
        else
            create_virtual_memory $size
        fi
        ;;
    2)
        echo "请选择管理操作："
        echo "1. 临时关闭虚拟内存"
        echo "2. 永久关闭虚拟内存"
        read -ep "请输入选项 (1 或 2): " manage_option
        case $manage_option in
            1) disable_virtual_memory_temporarily ;;
            2) disable_virtual_memory_permanently ;;
            *) echo "无效选项。" ;;
        esac
        ;;
    *)
        echo "无效选项。"
        ;;
esac
