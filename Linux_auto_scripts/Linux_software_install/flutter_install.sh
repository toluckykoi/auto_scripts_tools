#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-11-08
# @version     : bash
# @Update time : 2026-11-08
# @Description : Flutter SDK 安装脚本 - 使用官方二进制包安装

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_FLUTTER_VERSION="3.47.9"          # 稳定版
FLUTTER_VERSION="${FLUTTER_VERSION:-$DEFAULT_FLUTTER_VERSION}"
CHANNEL="${FLUTTER_CHANNEL:-stable}"       # stable / beta / dev
ARCH="$(uname -m)"
INSTALL_DIR="/opt/flutter"
DOWNLOAD_DIR="/tmp/flutter_install_$$"

# 下载源配置（默认官方源，可切换镜像源）
FLUTTER_MIRROR="${FLUTTER_MIRROR:-official}"     # official / mirror_cn
OFFICIAL_BASE_URL="https://storage.googleapis.com/flutter_infra_release/releases"
MIRROR_BASE_URL="https://storage.flutter-io.cn/releases"

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 [选项]

选项:
    -v, --version VERSION    指定 Flutter 版本 (默认: $DEFAULT_FLUTTER_VERSION)
    -c, --channel CHANNEL    指定发布渠道 stable/beta/dev (默认: stable)
    -d, --dir DIR            指定安装目录 (默认: $INSTALL_DIR)
    -m, --mirror MIRROR      下载源 official/mirror_cn (默认: $FLUTTER_MIRROR)
    --no-mirror             不使用镜像源（等价于 -m official）
    -y, --yes                跳过版本确认提示
    --dry-run               仅显示将要执行的操作，不实际执行
    -h, --help              显示此帮助信息

示例:
    $0                          # 安装最新稳定版到 /opt/flutter
    $0 -v 3.32.0                # 安装指定版本
    $0 -c beta                  # 安装最新 beta 版
    $0 -d ~/flutter             # 安装到指定目录
    $0 -m mirror_cn             # 使用国内镜像源 (storage.flutter-io.cn)
    $0 --dry-run                # 预览安装步骤

环境变量:
    FLUTTER_VERSION      覆盖默认版本号
    FLUTTER_CHANNEL      覆盖默认渠道
    FLUTTER_MIRROR       覆盖默认下载源

说明:
    - 仅支持 x86_64 架构 (官方 Linux 发布包仅提供 x64)
    - 安装后自动配置 PUB_HOSTED_URL 与 FLUTTER_STORAGE_BASE_URL (国内镜像)
    - 依赖的 Linux 构建工具（如 clang、cmake 等）需通过 flutter doctor 检测后安装
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            FLUTTER_VERSION="$2"
            shift 2
            ;;
        -c|--channel)
            CHANNEL="$2"
            shift 2
            ;;
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -m|--mirror)
            FLUTTER_MIRROR="$2"
            shift 2
            ;;
        --no-mirror)
            FLUTTER_MIRROR="official"
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

SKIP_CONFIRM="${SKIP_CONFIRM:-false}"
DRY_RUN="${DRY_RUN:-false}"

# 架构检查（官方 Linux 发布包仅支持 x86_64）
check_arch() {
    case "$ARCH" in
        x86_64)
            log_success "架构支持: x86_64"
            ;;
        *)
            log_error "不支持的架构: $ARCH"
            log_error "Flutter 官方 Linux 发布包仅提供 x86_64 架构"
            log_info "如为 ARM64 设备，请参考官方文档从源码构建: https://github.com/flutter/flutter"
            exit 1
            ;;
    esac
}

# 检查版本号格式（防止命令注入）
validate_version() {
    if [[ ! "$FLUTTER_VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9a-zA-Z.]+)*$ ]]; then
        log_error "无效的版本号格式: $FLUTTER_VERSION"
        exit 1
    fi
    if [[ ! "$CHANNEL" =~ ^(stable|beta|dev)$ ]]; then
        log_error "无效的渠道: $CHANNEL (可选: stable/beta/dev)"
        exit 1
    fi
}

# 构建下载 URL
BUILD_TARBALL="flutter_linux_${FLUTTER_VERSION}-${CHANNEL}.tar.xz"
BUILD_URL=""
if [[ "$FLUTTER_MIRROR" == "mirror_cn" ]]; then
    BUILD_URL="${MIRROR_BASE_URL}/${CHANNEL}/linux/${BUILD_TARBALL}"
else
    BUILD_URL="${OFFICIAL_BASE_URL}/${CHANNEL}/linux/${BUILD_TARBALL}"
fi

# 预检查
preflight_check() {
    log_info "开始预检查..."

    # 检查是否为 root 或有 sudo 权限 (dry-run 模式跳过)
    if [[ "$DRY_RUN" != "true" ]] && [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_error "需要 sudo 权限来安装到 $INSTALL_DIR"
        exit 1
    fi

    # 检查必要工具
    for cmd in wget tar xz; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "缺少必要工具: $cmd"
            exit 1
        fi
    done

    # 检查是否已安装
    if [[ -x "$INSTALL_DIR/flutter/bin/flutter" ]] && command -v flutter &>/dev/null; then
        local current_version
        current_version=$(flutter --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_warn "检测到已安装的 Flutter: $current_version"
        if [[ "$current_version" == "$FLUTTER_VERSION" ]]; then
            log_info "版本相同，无需重复安装"
            exit 0
        fi
        if [[ "$SKIP_CONFIRM" == "true" ]]; then
            log_info "检测到 --yes 参数，自动覆盖安装"
        else
            read -rp "是否覆盖安装? [y/N] " -n 1
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "取消安装"
                exit 0
            fi
        fi
    fi

    log_success "预检查通过"
}

# 显示安装计划
show_plan() {
    cat << EOF
========================================
Flutter 安装计划
========================================
版本:         ${FLUTTER_VERSION} (${CHANNEL})
架构:         ${ARCH}
安装目录:     ${INSTALL_DIR}
下载地址:     ${BUILD_URL}
下载源:       ${FLUTTER_MIRROR} (官方源/国内镜像)
模拟运行:     ${DRY_RUN}
========================================
EOF
}

# 执行命令（支持 dry-run）
run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        eval "$@"
    fi
}

# 下载 Flutter SDK
download_flutter() {
    log_info "下载 Flutter ${FLUTTER_VERSION} (${CHANNEL})..."

    run_cmd "mkdir -p \"$DOWNLOAD_DIR\""
    run_cmd "cd \"$DOWNLOAD_DIR\""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] wget -q --show-progress \"$BUILD_URL\""
        return
    fi

    if ! wget -q --show-progress "$BUILD_URL" -O "$BUILD_TARBALL"; then
        log_error "下载失败，请检查版本号和网络连接"
        log_error "可尝试使用 --no-mirror 参数切换下载源"
        exit 1
    fi

    # 验证文件完整性
    if [[ ! -s "$BUILD_TARBALL" ]]; then
        log_error "下载的文件为空"
        exit 1
    fi

    log_success "下载完成: $BUILD_TARBALL"
}

# 安装 Flutter SDK
install_flutter() {
    log_info "安装 Flutter 到 ${INSTALL_DIR} ..."

    # 创建安装目录
    run_cmd "sudo mkdir -p \"$INSTALL_DIR\""

    # 删除旧版本
    if [[ -d "$INSTALL_DIR/flutter" ]]; then
        log_warn "删除旧版本: $INSTALL_DIR/flutter"
        run_cmd "sudo rm -rf \"$INSTALL_DIR/flutter\""
    fi

    # 解压新版本
    run_cmd "sudo tar -C \"$INSTALL_DIR\" -xf \"$DOWNLOAD_DIR/$BUILD_TARBALL\""

    # 验证安装
    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ ! -x "$INSTALL_DIR/flutter/bin/flutter" ]]; then
            log_error "安装失败: 未找到 $INSTALL_DIR/flutter/bin/flutter"
            exit 1
        fi
    fi

    log_success "Flutter 安装完成"
}

# 配置环境变量
configure_env() {
    log_info "配置环境变量..."

    # 获取真实用户（sudo 时为调用用户，非 sudo 为当前用户）
    local real_user="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
    local real_home
    real_home=$(getent passwd "$real_user" | cut -d: -f6)

    local shell_rc=""
    # 检测用户的默认 shell
    local user_shell
    user_shell=$(getent passwd "$real_user" | cut -d: -f7 | xargs basename)
    case "$user_shell" in
        bash)   shell_rc="$real_home/.bashrc" ;;
        zsh)    shell_rc="$real_home/.zshrc" ;;
        *)      shell_rc="$real_home/.profile" ;;
    esac

    # 检查是否已配置 - 先清理旧配置
    if grep -q '^# Flutter 环境变量$' "$shell_rc" 2>/dev/null; then
        log_warn "检测到旧的 Flutter 环境变量配置，将替换为新配置"
        # 删除旧的 Flutter 环境变量配置块（从注释标记到 FLUTTER_STORAGE_BASE_URL 行）
        sed -i '/^# Flutter 环境变量$/,/^export FLUTTER_STORAGE_BASE_URL=[^ ]*$/d' "$shell_rc"
    fi

    # 使用 heredoc 避免变量展开
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} cat >> \"$shell_rc\" << 'EOF'"
        echo "# Flutter 环境变量"
        echo "export PATH=\$PATH:${INSTALL_DIR}/flutter/bin"
        echo
        echo "# Flutter 国内镜像加速 (如需可注释)"
        echo "export PUB_HOSTED_URL=${FLUTTER_MIRROR_PUB_URL}"
        echo "export FLUTTER_STORAGE_BASE_URL=${FLUTTER_MIRROR_STORAGE_URL}"
        echo -e "  ${YELLOW}EOF${NC}"
    else
        {
            echo "# Flutter 环境变量"
            echo "export PATH=\$PATH:${INSTALL_DIR}/flutter/bin"
            echo
            echo "# Flutter 国内镜像加速 (如需可注释)"
            echo "export PUB_HOSTED_URL=${FLUTTER_MIRROR_PUB_URL}"
            echo "export FLUTTER_STORAGE_BASE_URL=${FLUTTER_MIRROR_STORAGE_URL}"
        } >> "$shell_rc"
    fi

    log_success "环境变量已添加到 $shell_rc (用户: $real_user)"
}

# 配置国内镜像加速
configure_proxy() {
    if [[ "$FLUTTER_MIRROR" == "mirror_cn" ]]; then
        log_info "配置国内镜像加速 (storage.flutter-io.cn)..."
        FLUTTER_MIRROR_PUB_URL="https://pub.flutter-io.cn"
        FLUTTER_MIRROR_STORAGE_URL="https://storage.flutter-io.cn"
    else
        log_info "使用官方源，不配置镜像加速"
        FLUTTER_MIRROR_PUB_URL="https://pub.dev"
        FLUTTER_MIRROR_STORAGE_URL="https://storage.googleapis.com"
    fi

    # 验证
    if [[ "$DRY_RUN" != "true" ]]; then
        run_cmd "export PUB_HOSTED_URL=\"$FLUTTER_MIRROR_PUB_URL\""
        run_cmd "export FLUTTER_STORAGE_BASE_URL=\"$FLUTTER_MIRROR_STORAGE_URL\""
    fi
    log_success "镜像配置完成: PUB_HOSTED_URL=$FLUTTER_MIRROR_PUB_URL"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] flutter --version"
        log_info "[DRY-RUN] flutter doctor"
        return
    fi

    # 设置环境变量以便当前会话验证
    export PATH="$PATH:${INSTALL_DIR}/flutter/bin"
    export PUB_HOSTED_URL="$FLUTTER_MIRROR_PUB_URL"
    export FLUTTER_STORAGE_BASE_URL="$FLUTTER_MIRROR_STORAGE_URL"

    local version_output
    version_output=$("${INSTALL_DIR}/flutter/bin/flutter" --version 2>&1 || true)
    if [[ -z "$version_output" ]]; then
        log_error "Flutter 验证失败，请检查安装"
        exit 1
    fi
    log_success "Flutter 版本: $version_output"

    log_info "运行 flutter doctor 检查依赖环境 (可能需要数分钟)..."
    "${INSTALL_DIR}/flutter/bin/flutter" doctor 2>&1 | head -30 || true
}

# 清理函数
cleanup() {
    if [[ -d "$DOWNLOAD_DIR" ]]; then
        run_cmd "rm -rf \"$DOWNLOAD_DIR\""
        log_info "临时文件已清理"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Flutter SDK 安装脚本 (官方二进制包)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo

    check_arch
    validate_version
    preflight_check
    configure_proxy
    show_plan

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "模拟运行模式，不执行实际操作"
        echo
    fi

    download_flutter
    install_flutter
    configure_env
    verify_installation
    cleanup

    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "请运行以下命令使环境变量立即生效:"
    echo -e "  ${YELLOW}source ~/.bashrc${NC}  (或对应的 shell 配置文件)"
    echo
    echo -e "验证安装:"
    echo -e "  ${YELLOW}flutter --version${NC}"
    echo
    echo -e "创建新项目:"
    echo -e "  ${YELLOW}flutter create my_app${NC}"
    echo -e "  ${YELLOW}cd my_app && flutter run${NC}"
    echo
    echo -e "检查开发环境依赖:"
    echo -e "  ${YELLOW}flutter doctor${NC}"
}

# 捕获中断信号
trap cleanup EXIT INT TERM

# 运行主函数
main "$@"