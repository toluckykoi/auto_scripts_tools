#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-01-08 23:30:20
# @version     : bash
# @Update time :
# @Description : 自动挂载磁盘


set -euo pipefail

# 必须用 sudo 运行，但记录原始用户
if [[ $EUID -ne 0 ]]; then
    echo "请使用 sudo 运行此脚本（用于 mount 操作）."
    exit 1
fi

# 获取调用 sudo 的原始用户
if [[ -z "${SUDO_USER:-}" ]]; then
    echo "无法确定原始用户，请使用 'sudo -u yourname ...' 或直接 sudo 运行."
    exit 1
fi

ORIGINAL_USER="$SUDO_USER"
ORIGINAL_UID=$(id -u "$ORIGINAL_USER")
ORIGINAL_GID=$(id -g "$ORIGINAL_USER")

echo "操作将为用户 '$ORIGINAL_USER' (UID=$ORIGINAL_UID, GID=$ORIGINAL_GID) 配置读写权限."

DEFAULT_MOUNT="/mnt/disk1"

# === 第一步：收集候选设备 ===
echo "正在扫描磁盘..."
mapfile -t disks < <(lsblk -rno NAME,TYPE | awk '$2=="disk" {print "/dev/"$1}')

candidates=()
candidate_types=()

for disk in "${disks[@]}"; do
    if lsblk -rno MOUNTPOINT "$disk" | grep -q -v '^$'; then
        continue
    fi
    mapfile -t parts < <(lsblk -rno NAME,TYPE "$disk" 2>/dev/null | awk '$2=="part" {print "/dev/"$1}')
    if [ ${#parts[@]} -eq 0 ]; then
        candidates+=("$disk")
        candidate_types+=("unpartitioned")
    else
        for part in "${parts[@]}"; do
            if lsblk -rno MOUNTPOINT "$part" | grep -q -v '^$'; then
                continue
            fi
            if blkid -o value -s TYPE "$part" >/dev/null 2>&1; then
                candidates+=("$part")
                candidate_types+=("unmounted")
            else
                candidates+=("$part")
                candidate_types+=("unformatted")
            fi
        done
    fi
done

if [ ${#candidates[@]} -eq 0 ]; then
    echo "没有需要挂载的磁盘."
    exit 0
fi

# === 第二步：显示选择 ===
echo "可处理的设备："
for i in "${!candidates[@]}"; do
    dev="${candidates[$i]}"
    type="${candidate_types[$i]}"
    size=$(lsblk -b -no SIZE "$dev" 2>/dev/null | head -n1)
    human_size=$(numfmt --to=iec --format="%.1f" "$size" 2>/dev/null || echo "未知")
    case "$type" in
        unpartitioned)   label="【未分区磁盘】" ;;
        unformatted)     label="【未格式化分区】" ;;
        unmounted)       label="【未挂载分区】" ;;
    esac
    echo "  [$i] $dev $label ($human_size)"
done

# === 第三步：选择 ===
while true; do
    read -rp "选择设备编号（q 退出）: " choice
    [[ "$choice" == "q" ]] && { echo "退出."; exit 0; }
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt "${#candidates[@]}" ]; then
        selected_dev="${candidates[$choice]}"
        selected_type="${candidate_types[$choice]}"
        break
    else
        echo "无效编号."
    fi
done

# === 第四步：处理未分区磁盘 ===
target_partition=""

if [[ "$selected_type" == "unpartitioned" ]]; then
    echo -e "\n为 $selected_dev 创建单一分区..."
    read -rp "确认？(y/N): " c; [[ ! "$c" =~ ^[Yy]$ ]] && exit 1
    echo -e "n\np\n1\n\n\nw" | fdisk "$selected_dev" >/dev/null 2>&1
    sleep 2
    partprobe "$selected_dev" 2>/dev/null || true
    sleep 1

    for try in "${selected_dev}1" "${selected_dev}p1"; do
        if [[ -e "$try" ]]; then
            target_partition="$try"
            break
        fi
    done

    if [[ -z "$target_partition" ]]; then
        for f in "${selected_dev}"*; do
            [[ -e "$f" && "$f" != "$selected_dev" ]] && { target_partition="$f"; break; }
        done
    fi

    [[ -z "$target_partition" ]] && { echo "未找到新分区."; exit 1; }
    echo "分区：$target_partition"
    selected_dev="$target_partition"
    selected_type="unformatted"
fi

target_partition="$selected_dev"

# === 第五步：格式化（如需要）===
if [[ "$selected_type" == "unformatted" ]]; then
    echo -e "\nFormatting $target_partition"
    read -rp "文件系统（回车=ext4）[ext4|xfs|btrfs|vfat|ntfs]: " fs_type
    fs_type="${fs_type:-ext4}"
    case "$fs_type" in
        ext4|ext3) mkfs_cmd="mkfs.$fs_type" ;;
        xfs)       mkfs_cmd="mkfs.xfs -f" ;;
        btrfs)     mkfs_cmd="mkfs.btrfs -f" ;;
        vfat|fat32) mkfs_cmd="mkfs.vfat"; fs_type="vfat" ;;
        ntfs)      mkfs_cmd="mkfs.ntfs -f" ;;
        *) echo "不支持"; exit 1 ;;
    esac
    command -v "${mkfs_cmd%% *}" >/dev/null || { echo "请安装对应工具"; exit 1; }
    read -rp "格式化会清空数据！继续？(y/N): " c; [[ ! "$c" =~ ^[Yy]$ ]] && exit 1
    $mkfs_cmd "$target_partition"
    echo "格式化完成."
fi

# === 第六步：挂载（关键：设置 UID/GID）===
read -rp "配置挂载点（默认：$DEFAULT_MOUNT）: " mount_point
mount_point="${mount_point:-$DEFAULT_MOUNT}"

[[ -e "$mount_point" ]] || mkdir -p "$mount_point"
[[ -d "$mount_point" ]] || { echo "非目录"; exit 1; }
mountpoint -q "$mount_point" && { echo "已挂载"; exit 1; }

# 检测文件系统类型
fstype=$(blkid -o value -s TYPE "$target_partition" 2>/dev/null || echo "auto")

# 构建挂载选项
if [[ "$fstype" == "vfat" ]] || [[ "$fstype" == "ntfs" ]] || [[ "$fstype" == "" ]]; then
    # FAT/NTFS 不支持 UID/GID，用 uid,gid,umask
    mount_opts="uid=$ORIGINAL_UID,gid=$ORIGINAL_GID,umask=022,dmask=022,fmask=133"
else
    # ext4/xfs/btrfs 等原生文件系统
    echo "ext4/xfs/btrfs"
    mount_opts="uid=$ORIGINAL_UID,gid=$ORIGINAL_GID"
fi

echo $fstype
echo "以 $ORIGINAL_USER 权限挂载 $target_partition 到 $mount_point..."
mount -t "$fstype" -o "$mount_opts" "$target_partition" "$mount_point"

echo "挂载成功！普通用户 $ORIGINAL_USER 可读写."

# === 第七步：fstab（谨慎）===
echo -e "\n是否加入 /etc/fstab（开机自动挂载）？(y/N)"
read -rp "注意：错误配置可能导致系统无法启动！(y/N): " add_fstab
if [[ "$add_fstab" =~ ^[Yy]$ ]]; then
    if [[ "$fstype" == "vfat" ]] || [[ "$fstype" == "ntfs" ]]; then
        opts="uid=$ORIGINAL_UID,gid=$ORIGINAL_GID,umask=022"
    else
        # ext4 等通常不建议在 fstab 中用 uid/gid（因为权限由文件系统 inode 决定）
        # 更推荐：挂载后 chown，或格式化时指定（但 mkfs 不支持）
        # 所以这里写入不带 uid/gid 的条目，依赖挂载后权限（或用户手动 chown）
        opts="defaults"
    fi

    uuid=$(blkid -o value -s UUID "$target_partition" 2>/dev/null)
    if [[ -n "$uuid" ]]; then
        entry="UUID=$uuid"
    else
        entry="$target_partition"
        echo "无 UUID，使用设备路径."
    fi
    fstab_line="$entry $mount_point $fstype $opts 0 2"

    if ! grep -qF "$fstab_line" /etc/fstab; then
        echo "$fstab_line" >> /etc/fstab
        echo "已写入 /etc/fstab（注意：ext4 类文件系统在 fstab 中无法通过 uid 设置权限，建议挂载后手动 chown）."
    else
        echo "条目已存在."
    fi
fi

echo -e "\n完成！验证权限："
echo "挂载点: $mount_point"
df -h "$mount_point" | head -n2
echo "权限测试（切换到普通用户）:"
sudo -u "$ORIGINAL_USER" touch "$mount_point/test_write" && echo "可写." && rm -f "$mount_point/test_write"
