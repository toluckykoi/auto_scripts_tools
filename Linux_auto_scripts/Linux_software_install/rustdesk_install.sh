#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-12-21 15:08:25
# @version     : bash
# @Update time :
# @Description : RustDesk 安装脚本


set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}RustDesk 自动安装脚本.${NC}"
echo "----------------------------------------"

# 架构检测
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    DEB_URL1="http://web.808066.xyz:200/d/Linux_software/%E8%BF%9C%E7%A8%8B%E8%BD%AF%E4%BB%B6/rustdesk-1.2.7-x86_64.deb"
    DEB_URL2="https://pan.toluckykoi.com/f/3ysE/rustdesk-1.2.7-x86_64.deb"
    PKG_FILE="rustdesk-1.2.7-x86_64.deb"
elif [[ "$ARCH" == "aarch64" ]]; then
    DEB_URL1="http://web.808066.xyz:200/d/Linux_software/%E8%BF%9C%E7%A8%8B%E8%BD%AF%E4%BB%B6/rustdesk-1.2.6-aarch64.deb"
    DEB_URL2="https://pan.toluckykoi.com/f/7at3/rustdesk-1.2.6-aarch64.deb"
    PKG_FILE="rustdesk-1.2.6-aarch64.deb"
else
    echo -e "${RED}不支持的架构: $ARCH${NC}"
    exit 1
fi

# 发行版检测
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION_ID=${VERSION_ID:-""}
else
    echo -e "${RED}无法识别发行版${NC}"
    exit 1
fi

echo "系统: $DISTRO, 版本: ${VERSION_ID:-未知}, 架构: $ARCH"

# 下载函数（带进度）
download_with_progress() {
    local url1="$1"
    local url2="$2"
    local outfile="$3"

    try_download() {
        local url="$1"
        local of="$2"
        if command -v curl >/dev/null 2>&1; then
            echo -e "${GREEN}使用 curl 下载...${NC}"
            if curl -f -L --progress-bar -o "$of" "$url"; then
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            echo -e "${GREEN}使用 wget 下载...${NC}"
            if wget -q --show-progress --progress=bar:force:noscroll -O "$of" "$url"; then
                return 0
            fi
        else
            echo -e "${RED}错误：缺少 curl 或 wget${NC}"
            exit 1
        fi
        return 1
    }

    # 尝试主链接
    if try_download "$url1" "$outfile"; then
        :
    else
        echo -e "${YELLOW}主链接失败，尝试备用链接...${NC}"
        if ! try_download "$url2" "$outfile"; then
            echo -e "${RED}备用链接也失败${NC}"
            exit 1
        fi
    fi

    # 验证文件是否有效
    local size
    size=$(stat -c%s "$outfile" 2>/dev/null || stat -f%z "$outfile" 2>/dev/null || echo 0)

    # 如果文件小于 100KB，极可能是错误页面（JSON/HTML）
    if [[ $size -lt 102400 ]]; then  # 100KB
        echo -e "${RED}警告：下载的文件过小（仅 ${size} 字节），疑似错误响应！${NC}"
        echo -e "${RED}内容预览：${NC}"
        head -n 5 "$outfile"
        echo ""
        rm -f "$outfile"
        exit 1
    fi

    echo -e "${GREEN}✓ 下载完成且文件有效${NC}"
}

# Ubuntu 18.04 pipewire 处理
handle_ubuntu_pipewire() {
    if [[ "$DISTRO" == "ubuntu" ]] && [[ "$VERSION_ID" == "18.04" ]]; then
        echo -e "${YELLOW}检测到 Ubuntu 18.04，正在配置 PipeWire...${NC}"
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:pipewire-debian/pipewire-upstream
        sudo apt update
    fi
}

# 用户确认函数
confirm_install() {
    while true; do
        read -rp "$(echo -e ${YELLOW}"是否继续安装 RustDesk？[y/N]: "${NC})" yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]*|"") echo -e "${GREEN}安装已取消。${NC}"; exit 0;;
            * ) echo "请输入 y 或 n。";;
        esac
    done
}

# 根据发行版执行安装流程
install_by_distro() {
    case "$DISTRO" in
        ubuntu|debian|linuxmint|pop|kali)
            handle_ubuntu_pipewire
            download_with_progress "$DEB_URL1" "$DEB_URL2" "$PKG_FILE"
            confirm_install
            echo -e "${GREEN}正在安装 RustDesk...${NC}"
            sudo apt install -fy ./"$PKG_FILE"
            ;;
            
        centos|rhel|almalinux|rocky)
            if [[ $(echo "${VERSION_ID:-0} >= 7" | bc 2>/dev/null) -eq 1 ]]; then
                echo -e "${YELLOW}警告：仅提供 .deb 包。将尝试转换为 RPM（需 alien）...${NC}"
                if ! command -v alien >/dev/null; then
                    echo "安装 alien..."
                    sudo yum install -y alien
                fi
                download_with_progress "$DEB_URL1" "$DEB_URL2" "rustdesk.deb"
                echo "转换 .deb 为 .rpm..."
                sudo alien -r -c rustdesk.deb 2>/dev/null
                confirm_install
                sudo yum localinstall -y rustdesk-*.rpm
            else
                echo -e "${RED}系统版本过低，不支持安装${NC}"
                exit 1
            fi
            ;;
            
        fedora)
            echo -e "${YELLOW}警告：仅提供 .deb 包。将尝试转换为 RPM（需 alien）...${NC}"
            if ! command -v alien >/dev/null; then
                echo "安装 alien..."
                sudo dnf install -y alien
            fi
            download_with_progress "$DEB_URL1" "$DEB_URL2" "rustdesk.deb"
            echo "转换 .deb 为 .rpm..."
            sudo alien -r -c rustdesk.deb 2>/dev/null
            confirm_install
            sudo dnf install -y rustdesk-*.rpm
            ;;

        arch|manjaro)
            echo -e "${YELLOW}Arch 系使用官方 AppImage...${NC}"
            APPIMAGE="rustdesk.AppImage"
            URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-${ARCH}.AppImage"
            if command -v curl >/dev/null; then
                curl -L --progress-bar -o "$APPIMAGE" "$URL"
            else
                wget --show-progress --progress=bar:force:noscroll -O "$APPIMAGE" "$URL"
            fi
            chmod +x "$APPIMAGE"
            confirm_install
            echo -e "${GREEN}AppImage 已就绪，直接运行即可：./$APPIMAGE${NC}"
            ;;

        opensuse*)
            echo -e "${YELLOW}openSUSE 使用官方 AppImage...${NC}"
            APPIMAGE="rustdesk.AppImage"
            URL="https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk-${ARCH}.AppImage"
            if command -v curl >/dev/null; then
                curl -L --progress-bar -o "$APPIMAGE" "$URL"
            else
                wget --show-progress --progress=bar:force:noscroll -O "$APPIMAGE" "$URL"
            fi
            chmod +x "$APPIMAGE"
            confirm_install
            echo -e "${GREEN}AppImage 已就绪，直接运行即可：./$APPIMAGE${NC}"
            ;;

        *)
            echo -e "${RED}不支持的发行版: $DISTRO${NC}"
            exit 1
            ;;
    esac
}


# 执行安装流程
install_by_distro

# 安装后提示
echo
echo -e "${GREEN}✓ RustDesk 安装/配置完成！${NC}"

# Wayland 登录屏提示
if [[ -f /etc/gdm3/custom.conf ]] || [[ -f /etc/gdm/custom.conf ]]; then
    echo
    echo -e "${YELLOW}提示：如需远程访问登录界面，请禁用 Wayland：${NC}"
    echo "  编辑 /etc/gdm3/custom.conf（Ubuntu）或 /etc/gdm/custom.conf（Fedora）"
    echo "  取消注释并设置：WaylandEnable=false"
    echo "  然后重启系统。"
fi

# SELinux 检查
if command -v getenforce >/dev/null 2>&1 && [[ $(getenforce 2>/dev/null) == "Enforcing" ]]; then
    echo
    echo -e "${RED}⚠️  警告：SELinux 处于 Enforcing 模式，RustDesk 可能无法正常工作！${NC}"
    echo "  建议临时设为 permissive：sudo setenforce 0"
    echo "  或创建策略：sudo grep 'comm=\"rustdesk\"' /var/log/audit/audit.log | audit2allow -M rustdesk && sudo semodule -i rustdesk.pp"
fi

echo
echo -e "${GREEN}启动方式：${NC}"
if [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" || "$DISTRO" == "opensuse"* ]]; then
    echo "  运行：./rustdesk.AppImage"
else
    echo "  终端输入：rustdesk"
    echo "  或从应用程序菜单启动"
fi

