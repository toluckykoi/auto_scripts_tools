#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-25 15:18:17
# @version     : bash
# @Update time :
# @Description : 修复 ROS apt 更新源


GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ============================================================
#  可配置变量（如需更换镜像站，只需修改此处）
# ============================================================
ROS_MIRROR="https://mirror.nju.edu.cn/ros/ubuntu"
# 其他可选镜像：
#   https://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu   # 清华
#   https://mirrors.ustc.edu.cn/ros/ubuntu            # 中科大
#   http://packages.ros.org/ros/ubuntu                # 官方源

# ── 权限检查 ────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "请使用 sudo 或以 root 身份运行此脚本：sudo bash $0"
fi

# ── 1. 删除旧的 ROS sources.list 文件 ───────────────────────
info "检查 /etc/apt/sources.list.d/ 下的 ROS 源文件..."

shopt -s nullglob
ros_files=(/etc/apt/sources.list.d/ros*.list)
shopt -u nullglob

if [[ ${#ros_files[@]} -eq 0 ]]; then
    info "未发现旧的 ROS 源文件，跳过删除步骤。"
else
    for f in "${ros_files[@]}"; do
        warn "删除旧源文件：$f"
        rm -f "$f"
    done
    info "旧源文件已全部删除。"
fi

# ── 2. 导入 GPG 密钥 ─────────────────────────────────────────
KEY_ID="C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654"
KEYRING="/usr/share/keyrings/ros.gpg"

info "正在从 keyserver.ubuntu.com 获取 GPG 密钥（$KEY_ID）..."
gpg --keyserver 'hkp://keyserver.ubuntu.com:80' \
    --recv-key "$KEY_ID" \
    || error "GPG 密钥获取失败，请检查网络连接后重试。"

info "导出密钥到 $KEYRING ..."
gpg --export "$KEY_ID" | tee "$KEYRING" > /dev/null
info "GPG 密钥已保存至 $KEYRING"

# ── 3. 写入新的 ROS 镜像源（南京大学镜像站）────────────────
CODENAME=$(lsb_release -sc)
SOURCE_FILE="/etc/apt/sources.list.d/ros-latest.list"
SOURCE_LINE="deb [signed-by=${KEYRING}] ${ROS_MIRROR} ${CODENAME} main"

info "写入新源文件：$SOURCE_FILE"
info "源地址：$SOURCE_LINE"
echo "$SOURCE_LINE" > "$SOURCE_FILE"

# ── 4. 更新 apt 索引 ─────────────────────────────────────────
info "执行 apt-get update ..."
apt-get update

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  ROS1 更新源修复完成！Ubuntu 代号：${CODENAME}${NC}"
echo -e "${GREEN}  镜像站：${ROS_MIRROR}${NC}"
echo -e "${GREEN}============================================================${NC}"