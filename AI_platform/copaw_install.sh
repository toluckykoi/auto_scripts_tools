#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-08-01 15:38:28
# @version     : bash
# @Update time :
# @Description : copaw 安装脚本

set -euo pipefail

# -------------------- 颜色输出 --------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# -------------------- 端口配置 --------------------
DEFAULT_PORT=8088
COPWA_PORT="$DEFAULT_PORT"
DEFAULT_DATA_PATH="copaw-data"
COPWA_DATA_PATH="$DEFAULT_DATA_PATH"

# -------------------- 前置检查 --------------------
fail_count=0

check_docker_installed() {
    if command -v docker &>/dev/null; then
        info "docker 已安装: $(docker --version)"
    else
        error "docker 未安装，请先安装 Docker"
        fail_count=$((fail_count + 1))
    fi
}

check_docker_running() {
    if docker info &>/dev/null; then
        info "Docker 服务运行中"
    else
        error "Docker 服务未运行，请先启动 Docker 服务"
        fail_count=$((fail_count + 1))
    fi
}

check_port_available() {
    local port="${1:-8088}"
    if ss -tuln | grep -q ":${port}\b"; then
        error "端口 ${port} 已被占用，请释放端口或修改脚本使用其他端口"
        fail_count=$((fail_count + 1))
    else
        info "端口 ${port} 可用"
    fi
}

# -------------------- 执行检查 --------------------
echo "============================================"
echo "  copaw 安装前环境检查"
echo "============================================"
echo ""

check_docker_installed
check_docker_running

echo ""
if [[ "$fail_count" -gt 0 ]]; then
    error "共发现 ${fail_count} 项前置条件不满足，请修复后重新运行"
    exit 1
fi

info "所有前置检查通过，开始安装 copaw..."

read -r -p "是否修改默认端口？当前默认端口为 ${DEFAULT_PORT} [y/N]: " change_port
if [[ "$change_port" =~ ^[Yy]$ ]]; then
    while true; do
        read -r -p "请输入新端口号 (1-65535): " new_port
        if [[ "$new_port" =~ ^[0-9]+$ ]] && [[ "$new_port" -ge 1 ]] && [[ "$new_port" -le 65535 ]]; then
            COPWA_PORT="$new_port"
            info "已设置端口为: ${COPWA_PORT}"
            break
        else
            error "无效端口号，请输入 1-65535 之间的数字"
        fi
    done
else
    info "使用默认端口: ${COPWA_PORT}"
fi

echo ""
read -r -p "是否指定数据存放路径？（默认使用 Docker 卷: ${DEFAULT_DATA_PATH}）[y/N]: " change_path
if [[ "$change_path" =~ ^[Yy]$ ]]; then
    while true; do
        read -r -p "请输入数据存放路径 (例: /data/copaw): " new_path
        if [[ -n "$new_path" ]]; then
            COPWA_DATA_PATH="$new_path"
            info "已设置数据路径为: ${COPWA_DATA_PATH}"
            break
        else
            error "路径不能为空"
        fi
    done
else
    info "使用默认 Docker 卷: ${COPWA_DATA_PATH}"
fi

check_port_available "$COPWA_PORT"

# -------------------- 安装 copaw --------------------
docker pull agentscope/copaw:latest \
    && docker run -d \
        --name copaw \
        --restart unless-stopped \
        -p "${COPWA_PORT}":8088 \
        -v "${COPWA_DATA_PATH}":/app/working \
        agentscope/copaw:latest

if [[ $? -eq 0 ]]; then
    echo ""
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -z "$LOCAL_IP" ]]; then
        LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
    fi
    [[ -z "$LOCAL_IP" ]] && LOCAL_IP="localhost"
    info "copaw 安装完成！访问地址: http://${LOCAL_IP}:${COPWA_PORT}"
else
    error "copaw 安装失败，请检查上方输出信息"
    exit 1
fi
