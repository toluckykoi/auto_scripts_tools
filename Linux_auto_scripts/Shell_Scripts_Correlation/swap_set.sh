#!/bin/bash
# @Author: 幸运的锦鲤
# @Date:   2025-02-23 20:31:06
# @Last Modified time:
# linux 虚拟内存设置脚本


# 函数：检查当前虚拟内存状态
check_virtual_memory() {
    local swap_info=$(free -m | egrep "Swap:|交换：")
    local total_swap=$(echo "$swap_info" | awk '{print $2}')
    if [ "$total_swap" -gt 0 ]; then
        echo "当前虚拟内存 (swap) 已启用，总大小: $total_swap MB"
        swapon -s
        return 0
    else
        echo "当前虚拟内存 (swap) 未启用。"
        return 1
    fi
}

# 函数：从 /etc/fstab 中移除所有 swap 条目
# 按第 3 列（文件系统类型）是否为 swap 判断，兼容以下两种挂载点列写法：
#   /swapfile      swap  swap  defaults 0 0
#   /swapfile16G   none  swap  sw       0 0
# 注释行（首列以 # 开头）保持不变。
remove_swap_from_fstab() {
    local fstab="${1:-/etc/fstab}"
    local tmp

    [ -f "$fstab" ] || { echo "警告：$fstab 不存在，跳过。"; return 0; }

    # 先判断是否真的有 swap 条目，避免无谓改写
    if ! awk '$1 !~ /^#/ && $3 == "swap" { found = 1 } END { exit !found }' "$fstab"; then
        return 0
    fi

    tmp=$(mktemp) || { echo "错误：创建临时文件失败。"; return 1; }

    # 保留原有权限与属主，避免 mv 后 fstab 属性被改掉
    chmod --reference="$fstab" "$tmp" 2>/dev/null
    if [ "$(id -u)" -eq 0 ]; then
        chown --reference="$fstab" "$tmp" 2>/dev/null
    fi

    if awk '$1 !~ /^#/ && $3 == "swap" { next } { print }' "$fstab" > "$tmp"; then
        mv -f "$tmp" "$fstab" || { rm -f "$tmp"; echo "错误：写入 $fstab 失败。"; return 1; }
        echo "已从 $fstab 移除 swap 条目。"
    else
        rm -f "$tmp"
        echo "错误：生成新的 $fstab 内容失败。"
        return 1
    fi
}

# 函数：完全清理所有虚拟内存（活跃的 + 残留文件）
cleanup_all_swap() {
    echo "正在清理所有虚拟内存..."

    # 关闭所有活动的 swap
    swapoff -a 2>/dev/null

    # 从 fstab 中移除所有 swap 挂载行（按文件系统类型列判断）
    remove_swap_from_fstab || return 1

    # 删除所有残留的 swap 文件（/swapfile、/swapfile16G、/swapfile32G 等）
    rm -f /swapfile /swapfile* 2>/dev/null

    sleep 1

    # 验证清理结果
    if [ -n "$(swapon --show=NAME --noheadings 2>/dev/null)" ]; then
        echo "警告：仍有活跃的 swap，请手动检查。"
        swapon -s
        return 1
    fi

    echo "虚拟内存清理完成。"
    free -h
    return 0
}

# 函数：创建虚拟内存
create_virtual_memory() {
    local size=$1
    local swapfile="/swapfile"

    # 验证输入
    if ! [[ "$size" =~ ^[0-9]+$ ]] || [ "$size" -le 0 ]; then
        echo "错误：大小必须是正整数（GB）。"
        return 1
    fi

    echo "正在创建 $size GB（十进制，$((size * 1000)) MB）的虚拟内存..."
    # 注意：bs=10MB 是十进制 10,000,000 字节，保证文件大小严格等于 size×10^9 字节
    dd if=/dev/zero of="$swapfile" bs=10MB count=$((size * 100)) status=progress
    chmod 0600 "$swapfile"
    mkswap "$swapfile"
    swapon "$swapfile"
    echo "$swapfile swap swap defaults 0 0" >> /etc/fstab
    echo "虚拟内存创建成功。"
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
    remove_swap_from_fstab || return 1
    rm -f /swapfile /swapfile* 2>/dev/null
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
                cleanup_all_swap || { echo "清理失败，中止。"; exit 1; }
                create_virtual_memory "$size"
            else
                echo "操作取消。"
            fi
        else
            create_virtual_memory "$size"
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
