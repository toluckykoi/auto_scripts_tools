#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-02-15 22:42:19
# @version     : bash
# @Update time :
# @Description : Python pip 初始化脚本


need_sudo() {
    if [ "$EUID" -eq 0 ]; then
        echo ""
    elif command -v sudo >/dev/null 2>&1; then
        echo "sudo"
    else
        echo ""
    fi
}

# 镜像源列表（统一格式：URL|名称）
MIRRORS=(
    "https://pypi.tuna.tsinghua.edu.cn/simple|清华源"
    "https://mirrors.aliyun.com/pypi/simple/|阿里云"
    "https://pypi.douban.com/simple/|豆瓣"
    "https://pypi.mirrors.ustc.edu.cn/simple/|中科大"
    "https://mirrors.cloud.tencent.com/pypi/simple/|腾讯云"
    "https://mirrors.huaweicloud.com/repository/pypi/simple|华为云"
    "https://pypi.org/simple|官方源"
)

# 检测包管理器
detect_pkg_mgr() {
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MGR="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MGR="yum"
    else
        echo "错误: 未检测到支持的包管理器 (apt/yum/dnf)"
        exit 1
    fi
}

# 选择镜像源（默认华为源）
select_mirror() {
    echo ""
    echo "可用镜像源:"
    for i in "${!MIRRORS[@]}"; do
        name="${MIRRORS[$i]##*|}"
        echo "  $((i+1)). $name"
    done
    echo ""

    read -p "请选择镜像源编号 [默认: 6 华为云]: " choice
    choice=${choice:-6}

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#MIRRORS[@]}" ]; then
        echo "警告: 无效选择，使用默认源（华为云）"
        choice=6
    fi

    SELECTED="${MIRRORS[$((choice-1))]}"
    MIRROR_URL="${SELECTED%%|*}"
    MIRROR_NAME="${SELECTED##*|}"
    echo "已选择: $MIRROR_NAME"
}

# 安装 Python/pip
install_pip() {
    echo "安装 Python 3 和 pip..."
    SUDO_CMD=$(need_sudo)

    # CentOS 7 特殊处理: 安装 EPEL
    if [ "$PKG_MGR" = "yum" ] && [ -f /etc/redhat-release ] && grep -q "release 7" /etc/redhat-release; then
        if ! rpm -q epel-release >/dev/null 2>&1; then
            echo "安装 EPEL 仓库 (CentOS 7)..."
            ${SUDO_CMD} yum install -y epel-release
        fi
    fi

    # 安装基础包
    if [ "$PKG_MGR" = "apt" ]; then
        ${SUDO_CMD} apt-get update
        ${SUDO_CMD} apt-get install -y python3-pip python3-venv
    elif [ "$PKG_MGR" = "dnf" ]; then
        ${SUDO_CMD} dnf install -y python3-pip
    elif [ "$PKG_MGR" = "yum" ]; then
        ${SUDO_CMD} yum install -y python3-pip
    fi

    # 升级 pip（用户级，无需 sudo）
    if ! command -v pip3 >/dev/null 2>&1; then
        python3 -m ensurepip --upgrade --user >/dev/null 2>&1 || {
            echo "错误: pip 安装失败"
            exit 1
        }
        export PATH="$HOME/.local/bin:$PATH"
    fi

    pip3 install --upgrade pip 
    PIP_VERSION=$(pip3 --version | awk '{print $2}')
    echo "pip $PIP_VERSION 已就绪"
}

# 配置镜像源
configure_pip() {
    echo "配置 pip 镜像源..."

    # 确定配置路径
    if [ "$(uname)" = "Linux" ]; then
        CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pip"
        CONFIG_FILE="$CONFIG_DIR/pip.conf"
        [ -f "$HOME/.pip/pip.conf" ] && CONFIG_FILE="$HOME/.pip/pip.conf"
    elif [ "$(uname)" = "Darwin" ]; then
        CONFIG_DIR="$HOME/Library/Application Support/pip"
        CONFIG_FILE="$CONFIG_DIR/pip.conf"
    else
        echo "错误: 不支持的操作系统"
        exit 1
    fi

    # 备份
    [ -f "$CONFIG_FILE" ] && cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" && echo "已备份原有配置"

    # 创建目录
    mkdir -p "$(dirname "$CONFIG_FILE")"

    # 提取 trusted-host
    TRUSTED_HOST=$(echo "$MIRROR_URL" | sed -E 's|https?://([^/]+).*|\1|')

    # 写入配置
    cat > "$CONFIG_FILE" <<EOF
[global]
index-url = $MIRROR_URL
trusted-host = $TRUSTED_HOST
timeout = 120
retries = 5

[install]
trusted-host = $TRUSTED_HOST
EOF

    chmod 600 "$CONFIG_FILE" 2>/dev/null || true
    echo "镜像源配置完成: $MIRROR_NAME"
}

# 验证配置
verify() {
    echo "验证配置..."
    if timeout 10 pip3 install six --dry-run >/dev/null 2>&1; then
        echo "镜像源连接正常"
    else
        echo "镜像源连接较慢（可正常使用）"
    fi
}

# 主流程
main() {
    echo ""
    echo "=========================================="
    echo "pip 初始化配置工具（默认华为源）"
    echo "=========================================="

    detect_pkg_mgr
    select_mirror
    install_pip
    configure_pip
    verify

    echo ""
    echo "使用技巧:"
    echo "  • 临时换源: pip3 install 包名 -i 源地址"
    echo "  • 查看配置: pip3 config list"
    echo "  • 恢复官方源: rm -f ~/.config/pip/pip.conf ~/.pip/pip.conf"
    echo ""
    echo "=========================================="
    echo "配置完成"
    echo "=========================================="
}

main

