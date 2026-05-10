#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-05-10 08:35:21
# @version     : bash
# @Update time :
# @Description : 安装 docker-compose


set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否为 root 用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[错误] 请使用 root 权限运行此脚本${NC}"
        exit 1
    fi
}

# 检查 Docker 是否安装
check_docker() {
    if command -v docker &> /dev/null; then
        local version=$(docker --version 2>/dev/null)
        echo -e "${GREEN}[检查] Docker 已安装: ${version}${NC}"
    else
        echo -e "${RED}[错误] Docker 未安装，请先安装 Docker${NC}"
        exit 1
    fi
}

# 检查 docker-compose 是否已安装
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        local version=$(docker-compose --version 2>/dev/null)
        echo -e "${GREEN}[检查] docker-compose 已安装: ${version}${NC}"
        read -p "是否重新安装？ [y/N]: " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "取消安装"
            exit 0
        fi
    fi
}

# 安装 docker-compose
install_docker_compose() {
    echo -e "${YELLOW}[安装] Docker-compose 开始安装...${NC}"

    local os=$(uname -s)
    local arch=$(uname -m)
    local url="http://github.808066.xyz:38000/https://github.com/docker/compose/releases/latest/download/docker-compose-${os}-${arch}"
    local dest="/usr/local/bin/docker-compose"

    echo "[下载] URL: $url"

    if curl -L --fail --progress-bar "$url" -o "$dest"; then
        chmod +x "$dest"
        ln -sf "$dest" /usr/bin/docker-compose
        echo -e "${GREEN}[成功] docker-compose 安装完成${NC}"
    else
        echo -e "${RED}[错误] 下载失败，请检查网络连接${NC}"
        exit 1
    fi
}

# 验证安装
verify_install() {
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}[验证] docker-compose 版本:${NC}"
        docker-compose --version
    else
        echo -e "${RED}[错误] 安装验证失败${NC}"
        exit 1
    fi
}

# 主流程
main() {
    echo "=========================================="
    echo "       Docker-Compose 安装脚本"
    echo "=========================================="
    echo ""

    check_root
    check_docker
    check_docker_compose
    install_docker_compose
    verify_install

    echo ""
    echo -e "${GREEN}=========================================="
    echo "       安装完成!"
    echo "==========================================${NC}"
}

main "$@"
