#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-10-24 21:19:11
# @version     : bash
# @Update time : 2026-10-24
# @Description : GO 程序安装脚本 - 使用官方二进制包安装

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_GO_VERSION="1.23.0"
GO_VERSION="${GO_VERSION:-$DEFAULT_GO_VERSION}"
ARCH="$(uname -m)"
INSTALL_DIR="/usr/local"
DOWNLOAD_DIR="/tmp/go_install_$$"

# 架构映射
case "$ARCH" in
    x86_64)   GO_ARCH="amd64" ;;
    aarch64)  GO_ARCH="arm64" ;;
    armv7l)   GO_ARCH="armv6l" ;;
    *)        echo -e "${RED}不支持的架构: $ARCH${NC}"; exit 1 ;;
esac

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
    -v, --version VERSION    指定 Go 版本 (默认: $DEFAULT_GO_VERSION)
    -h, --help              显示此帮助信息
    --no-proxy              不配置 GOPROXY (默认配置为中国大陆代理)
    --workspace             创建 Go 工作空间目录 ~/go/bin (默认不创建)
    --no-workspace          显式禁用工作空间创建
    --dry-run               仅显示将要执行的操作，不实际执行

示例:
    $0                      # 安装默认版本 (不创建工作空间)
    $0 -v 1.22.5            # 安装指定版本
    $0 --workspace          # 安装并创建工作空间
    $0 --no-proxy           # 不配置代理
    $0 --dry-run            # 预览安装步骤

环境变量:
    GO_VERSION              覆盖默认版本

说明:
    - 仅添加 /usr/local/go/bin 和 ~/go/bin 到 PATH
    - 不设置 GOPATH (Go 1.11+ 使用模块模式，无需 GOPATH)
    - 工作空间仅创建 ~/go/bin 目录用于存放编译产物
EOF
}

# 解析命令行参数
CONFIGURE_PROXY=true
CREATE_WORKSPACE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            GO_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --no-proxy)
            CONFIGURE_PROXY=false
            shift
            ;;
        --workspace)
            CREATE_WORKSPACE=true
            shift
            ;;
        --no-workspace)
            CREATE_WORKSPACE=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 构建下载 URL
GO_TARBALL="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
DOWNLOAD_URL="https://go.dev/dl/${GO_TARBALL}"

# 预检查
preflight_check() {
    log_info "开始预检查..."

    # 检查是否为 root 或有 sudo 权限 (dry-run 模式跳过)
    if [[ "$DRY_RUN" != "true" ]] && [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        log_error "需要 sudo 权限来安装到 $INSTALL_DIR"
        exit 1
    fi

    # 检查必要工具
    for cmd in wget tar; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "缺少必要工具: $cmd"
            exit 1
        fi
    done

    # 检查是否已安装
    if [[ -d "$INSTALL_DIR/go" ]] && command -v go &>/dev/null; then
        local current_version
        current_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        log_warn "检测到已安装的 Go: $current_version"
        if [[ "$current_version" == "go${GO_VERSION}" ]]; then
            log_info "版本相同，无需重复安装"
            exit 0
        fi
        read -rp "是否覆盖安装? [y/N] " -n 1
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "取消安装"
            exit 0
        fi
    fi

    log_success "预检查通过"
}

# 显示安装计划
show_plan() {
    cat << EOF
========================================
Go 安装计划
========================================
版本:          go${GO_VERSION}
架构:          ${GO_ARCH}
安装目录:      ${INSTALL_DIR}/go
下载地址:      ${DOWNLOAD_URL}
配置代理:      ${CONFIGURE_PROXY}
创建工作空间:  ${CREATE_WORKSPACE}
模拟运行:      ${DRY_RUN}
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

# 下载 Go 安装包
download_go() {
    log_info "下载 Go ${GO_VERSION} (${GO_ARCH})..."

    run_cmd "mkdir -p \"$DOWNLOAD_DIR\""
    run_cmd "cd \"$DOWNLOAD_DIR\""

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] wget -q --show-progress \"$DOWNLOAD_URL\""
        return
    fi

    if ! wget -q --show-progress "$DOWNLOAD_URL" -O "$GO_TARBALL"; then
        log_error "下载失败，请检查版本号和网络连接"
        log_info "可用版本请访问: https://go.dev/dl/"
        exit 1
    fi

    # 验证文件完整性
    if [[ ! -s "$GO_TARBALL" ]]; then
        log_error "下载的文件为空"
        exit 1
    fi

    log_success "下载完成: $GO_TARBALL"
}

# 安装 Go
install_go() {
    log_info "安装 Go 到 $INSTALL_DIR/go ..."

    # 删除旧版本
    run_cmd "sudo rm -rf \"$INSTALL_DIR/go\""

    # 解压新版本
    run_cmd "sudo tar -C \"$INSTALL_DIR\" -xzf \"$DOWNLOAD_DIR/$GO_TARBALL\""

    # 验证安装
    if [[ "$DRY_RUN" != "true" ]]; then
        if [[ ! -f "$INSTALL_DIR/go/bin/go" ]]; then
            log_error "安装失败: 未找到 $INSTALL_DIR/go/bin/go"
            exit 1
        fi
    fi

    log_success "Go 安装完成"
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
    if grep -q '/usr/local/go/bin' "$shell_rc" 2>/dev/null; then
        log_warn "检测到旧的 Go 环境变量配置，将替换为新格式"
        # 删除旧的 Go 环境变量配置块
        sed -i '/# Go 环境变量/,/^export PATH.*go\/bin/d' "$shell_rc"
    fi

    local env_config='
# Go 环境变量
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin

'

    # 使用 heredoc 避免变量展开
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} cat >> \"$shell_rc\" << 'EOF'"
        echo "$env_config" | sed 's/^/  /'
        echo -e "  ${YELLOW}EOF${NC}"
    else
        cat >> "$shell_rc" << 'EOF'
# Go 环境变量
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin

EOF
    fi
    log_success "环境变量已添加到 $shell_rc (用户: $real_user)"

    # 当前会话生效（仅对当前 shell 有效）
    if [[ "$DRY_RUN" != "true" ]]; then
        export PATH=$PATH:/usr/local/go/bin
        export PATH=$PATH:$HOME/go/bin
    fi
}

# 配置 GOPROXY
configure_proxy() {
    if [[ "$CONFIGURE_PROXY" != "true" ]]; then
        log_info "跳过 GOPROXY 配置"
        return
    fi

    log_info "配置 GOPROXY (中国大陆加速)..."

    run_cmd "go env -w GO111MODULE=on"
    run_cmd "go env -w GOPROXY=https://goproxy.cn,direct"

    log_success "GOPROXY 配置完成: $(go env GOPROXY 2>/dev/null || echo '待生效')"
}

# 创建工作空间
create_workspace() {
    if [[ "$CREATE_WORKSPACE" != "true" ]]; then
        log_info "跳过工作空间创建"
        return
    fi

    # 获取真实用户的 home 目录
    local real_user="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
    local real_home
    real_home=$(getent passwd "$real_user" | cut -d: -f6)

    log_info "创建 Go 工作空间目录 (用户: $real_user)..."

    run_cmd "mkdir -p \"$real_home/go/bin\""

    log_success "工作空间创建完成: $real_home/go/bin"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] go version"
        log_info "[DRY-RUN] go env GOPROXY"
        return
    fi

    local version_output
    version_output=$(go version)
    log_success "Go 版本: $version_output"

    log_info "GOPROXY: $(go env GOPROXY)"
    log_info "GOROOT: $(go env GOROOT)"
}

# 清理临时文件
cleanup() {
    if [[ -d "$DOWNLOAD_DIR" ]]; then
        run_cmd "rm -rf \"$DOWNLOAD_DIR\""
        log_info "临时文件已清理"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     Go 语言安装脚本 (官方二进制包)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo

    preflight_check
    show_plan

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "模拟运行模式，不执行实际操作"
        echo
    fi

    download_go
    install_go
    configure_env
    configure_proxy
    create_workspace
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
    echo -e "  ${YELLOW}go version${NC}"
    echo
    echo -e "开始编程:"
    echo -e "  ${YELLOW}mkdir -p ~/go/src/hello && cd ~/go/src/hello${NC}"
    echo -e "  ${YELLOW}echo 'package main\nimport \"fmt\"\nfunc main() { fmt.Println(\"Hello, Go!\") }' > main.go${NC}"
    echo -e "  ${YELLOW}go run main.go${NC}"
}

# 捕获中断信号
trap cleanup EXIT INT TERM

# 运行主函数
main "$@"
