#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-11-08
# @version     : bash
# @Update time : 2026-11-08
# @Description : Rust 安装脚本 - 使用 rustup 官方工具链安装

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_TOOLCHAIN="stable"          # 默认工具链
TOOLCHAIN="${TOOLCHAIN:-$DEFAULT_TOOLCHAIN}"
PROFILE="${RUSTUP_PROFILE:-default}" # minimal / default / complete
ARCH="$(uname -m)"
MIRROR="official"                   # official / ustc / tuna
CONFIGURE_CARGO_MIRROR=true         # 是否配置 cargo 国内镜像
DRY_RUN=false
SKIP_CONFIRM=false
DOWNLOAD_DIR="/tmp/rust_install_$$"

# 架构映射到 rustup 目标三元组
case "$ARCH" in
    x86_64)   RUST_TARGET="x86_64-unknown-linux-gnu" ;;
    aarch64)  RUST_TARGET="aarch64-unknown-linux-gnu" ;;
    armv7l)   RUST_TARGET="armv7-unknown-linux-gnueabihf" ;;
    armv6l)   RUST_TARGET="arm-unknown-linux-gnueabihf" ;;
    *)
        echo -e "${RED}[ERROR]${NC} 不支持的架构: $ARCH"
        exit 1
        ;;
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
    -v, --toolchain VERSION   指定 rustup 工具链 (默认: $DEFAULT_TOOLCHAIN)
                              如: stable / beta / nightly / 1.75.0
    -p, --profile PROFILE     指定安装配置 minimal/default/complete (默认: default)
    -m, --mirror MIRROR       rustup 下载源 official/rsproxy/ustc/tuna/auto (默认: official)
                              auto 自动探测可用镜像; 下载失败会自动回退 rsproxy -> 官方
    --no-proxy                不配置 cargo 国内镜像 (默认配置)
    -y, --yes                 跳过确认提示
    --dry-run                 仅显示将要执行的操作，不实际执行
    -h, --help                显示此帮助信息

示例:
    $0                          # 安装最新 stable 工具链
    $0 -v 1.75.0                # 安装指定版本工具链
    $0 -v nightly               # 安装 nightly 工具链
    $0 -p minimal               # 最小化安装 (仅 rustc/cargo/rustup)
    $0 -m ustc                  # 使用中科大镜像安装并配置 cargo 镜像
    $0 -m rsproxy               # 使用 rsproxy (字节) 镜像安装并配置 cargo 镜像
    $0 -m auto                  # 自动探测可用国内镜像
    $0 --no-proxy               # 安装但不在 ~/.cargo/config.toml 配置镜像
    $0 --dry-run                # 预览安装步骤

环境变量:
    TOOLCHAIN                  覆盖默认工具链
    RUSTUP_PROFILE             覆盖默认 profile
    RUSTUP_DIST_SERVER         覆盖 Rust 发行版下载地址 (含工具链发布)
    RUSTUP_UPDATE_ROOT         覆盖 rustup 自身更新地址

说明:
    - 使用官方 rustup-init 程序安装，rustup 管理工具链 (rustc/cargo/clippy 等)
    - 默认安装到 ~/.cargo 和 ~/.rustup，无需 root 权限
    - 检测到已安装 Rust 时会询问是否重新安装，-y/--yes 可跳过询问直接重装
    - 自动配置 shell 配置文件 (source ~/.cargo/env)，支持 bash/zsh
    - 国内镜像同时覆盖 rustup 下载与 crates.io 依赖源
    - 卸载: rustup self uninstall
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--toolchain)
            TOOLCHAIN="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -m|--mirror)
            MIRROR="$2"
            shift 2
            ;;
        --no-proxy)
            CONFIGURE_CARGO_MIRROR=false
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

# 根据镜像配置下载地址与 cargo 源
case "$MIRROR" in
    official)
        RUSTUP_INIT_URL="https://static.rust-lang.org/rustup"
        RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://static.rust-lang.org}"
        RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://static.rust-lang.org/rustup}"
        CARGO_MIRROR_URL=""
        ;;
    rsproxy)
        # rsproxy (字节跳动) 同时提供 rustup 分发与 crates.io 代理，国内最稳定之一
        RUSTUP_INIT_URL="https://rsproxy.cn/rustup"
        RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://rsproxy.cn/rustup}"
        RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://rsproxy.cn/rustup}"
        CARGO_MIRROR_URL="sparse+https://rsproxy.cn/index/"
        ;;
    ustc)
        RUSTUP_INIT_URL="https://mirrors.ustc.edu.cn/rust-static/rustup"
        RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://mirrors.ustc.edu.cn/rust-static}"
        RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://mirrors.ustc.edu.cn/rust-static/rustup}"
        # 注意: 中科大镜像站不提供 crates.io 镜像，这里用国内常用的 rsproxy 代理
        CARGO_MIRROR_URL="sparse+https://rsproxy.cn/index/"
        ;;
    tuna)
        RUSTUP_INIT_URL="https://mirrors.tuna.tsinghua.edu.cn/rustup"
        RUSTUP_DIST_SERVER="${RUSTUP_DIST_SERVER:-https://mirrors.tuna.tsinghua.edu.cn/rustup}"
        RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://mirrors.tuna.tsinghua.edu.cn/rustup}"
        CARGO_MIRROR_URL="sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
        ;;
    auto)
        # 自动探测可用镜像：依次尝试 ustc -> tuna -> rsproxy，取第一个可用；全部不可用则用官方
        RUSTUP_INIT_URL=""
        RUSTUP_DIST_SERVER=""
        RUSTUP_UPDATE_ROOT=""
        CARGO_MIRROR_URL=""
        log_info "自动探测可用国内镜像源..."
        # 探测函数：有 curl 用 curl，否则用 wget
        if command -v curl &>/dev/null; then
            probe_url() { curl -sfI --max-time 8 "$1" >/dev/null 2>&1; }
        else
            probe_url() { wget -q --spider --timeout=8 "$1" 2>/dev/null; }
        fi
        for candidate in "ustc" "tuna" "rsproxy"; do
            test_url=""
            c_init_url=""
            c_dist=""
            c_update=""
            c_cargo=""
            case "$candidate" in
                ustc)
                    c_init_url="https://mirrors.ustc.edu.cn/rust-static/rustup"
                    c_dist="https://mirrors.ustc.edu.cn/rust-static"
                    c_update="https://mirrors.ustc.edu.cn/rust-static/rustup"
                    c_cargo="sparse+https://rsproxy.cn/index/"
                    ;;
                tuna)
                    c_init_url="https://mirrors.tuna.tsinghua.edu.cn/rustup"
                    c_dist="https://mirrors.tuna.tsinghua.edu.cn/rustup"
                    c_update="https://mirrors.tuna.tsinghua.edu.cn/rustup"
                    c_cargo="sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
                    ;;
                rsproxy)
                    c_init_url="https://rsproxy.cn/rustup"
                    c_dist="https://rsproxy.cn/rustup"
                    c_update="https://rsproxy.cn/rustup"
                    c_cargo="sparse+https://rsproxy.cn/index/"
                    ;;
            esac
            test_url="${c_init_url}/dist/${RUST_TARGET}/rustup-init"
            if probe_url "$test_url"; then
                RUSTUP_INIT_URL="$c_init_url"
                RUSTUP_DIST_SERVER="$c_dist"
                RUSTUP_UPDATE_ROOT="$c_update"
                CARGO_MIRROR_URL="$c_cargo"
                MIRROR="$candidate"
                log_success "已选择可用镜像: $candidate ($RUSTUP_DIST_SERVER)"
                break
            fi
            log_warn "镜像 $candidate 不可用，尝试下一个..."
        done
        # 全部不可用则回退官方
        if [[ -z "$RUSTUP_INIT_URL" ]]; then
            log_warn "所有国内镜像均不可用，回退官方源"
            RUSTUP_INIT_URL="https://static.rust-lang.org/rustup"
            RUSTUP_DIST_SERVER="https://static.rust-lang.org"
            RUSTUP_UPDATE_ROOT="https://static.rust-lang.org/rustup"
            CARGO_MIRROR_URL=""
            MIRROR="official"
        fi
        ;;
    *)
        log_error "不支持的镜像源: $MIRROR (可选: official/rsproxy/ustc/tuna/auto)"
        exit 1
        ;;
esac

# 检测真实目标用户（以 sudo/root 运行时，安装给调用用户而非 root）
# 注意: rustup 官方不支持全局安装，rustup-init 必须按目标用户的 HOME 执行
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(logname 2>/dev/null || echo "$USER")"
fi
if command -v getent &>/dev/null; then
    REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
else
    REAL_HOME="${HOME}"
fi
RUSTUP_HOME="${REAL_HOME}/.rustup"
CARGO_HOME="${REAL_HOME}/.cargo"

# 校验工具链与 profile 格式
validate_options() {
    if [[ ! "$TOOLCHAIN" =~ ^(stable|beta|nightly|[0-9]+\.[0-9]+(\.[0-9]+)?)$ ]] && \
       [[ ! "$TOOLCHAIN" =~ ^(stable|beta|nightly)-[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_error "无效的工具链: $TOOLCHAIN (可选: stable/beta/nightly/版本号/日期版本)"
        exit 1
    fi
    if [[ ! "$PROFILE" =~ ^(minimal|default|complete)$ ]]; then
        log_error "无效的 profile: $PROFILE (可选: minimal/default/complete)"
        exit 1
    fi
}

# 预检查
preflight_check() {
    log_info "开始预检查..."

    # 检查必要工具 (wget 或 curl 至少一个)
    local has_wget=false has_curl=false
    command -v wget &>/dev/null && has_wget=true
    command -v curl &>/dev/null && has_curl=true
    if [[ "$has_wget" != "true" && "$has_curl" != "true" ]]; then
        log_error "缺少必要工具: wget 或 curl (请先安装其中之一)"
        exit 1
    fi

    # 检查是否已安装 rustup
    local rustup_bin="$CARGO_HOME/bin/rustup"
    if command -v rustup &>/dev/null || [[ -x "$rustup_bin" ]]; then
        local head_rustup
        head_rustup="$(command -v rustup || echo "$rustup_bin")"
        local installed_ver
        installed_ver=$("$head_rustup" --version 2>/dev/null | head -1 || true)
        local installed_toolchains
        installed_toolchains=$("$head_rustup" toolchain list 2>/dev/null | grep -oE '^[a-z0-9.-]+' || true)

        log_warn "检测到已安装的 Rust: ${installed_ver:-未知版本} ($head_rustup)"
        if echo "$installed_toolchains" | grep -qx "$TOOLCHAIN"; then
            log_info "目标工具链 $TOOLCHAIN 已存在"
        else
            log_info "目标工具链 $TOOLCHAIN 尚未安装"
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] 真实运行时会询问是否重新安装"
            return
        fi

        # 已安装则询问是否重新安装（-y/--yes 跳过询问，直接重装）
        if [[ "$SKIP_CONFIRM" != "true" ]]; then
            read -rp "是否重新安装 Rust ${TOOLCHAIN}? [y/N] " -n 1
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "已取消，保留现有安装"
                log_info "如需升级现有工具链: rustup update $TOOLCHAIN"
                exit 0
            fi
        else
            log_info "检测到 -y/--yes 参数，直接重新安装"
        fi
        log_success "预检查通过（将重新安装）"
        return
    fi

    log_success "预检查通过"
}

# 显示安装计划
show_plan() {
    cat << EOF
========================================
Rust 安装计划
========================================
工具链:        ${TOOLCHAIN} (profile: ${PROFILE})
架构:          ${ARCH} (${RUST_TARGET})
安装位置:      ~/.cargo (rustup: ~/.rustup)
下载地址:      ${RUSTUP_INIT_URL}/dist/${RUST_TARGET}/rustup-init
下载源:        ${MIRROR}
配置 cargo 镜像: ${CONFIGURE_CARGO_MIRROR}
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

# 下载一个文件的通用函数（优先 wget，其次 curl；失败返回非 0）
try_download() {
    local url="$1"
    local out="$2"
    if command -v wget &>/dev/null; then
        wget -q --show-progress "$url" -O "$out"
    else
        curl -fSL --progress-bar "$url" -o "$out"
    fi
}

# 下载 rustup-init（自动回退：当前源 -> rsproxy -> 官方）
download_rustup_init() {
    local init_url="${RUSTUP_INIT_URL}/dist/${RUST_TARGET}/rustup-init"
    log_info "下载 rustup-init (${RUST_TARGET})..."

    run_cmd "mkdir -p \"$DOWNLOAD_DIR\""
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] wget -q --show-progress \"$init_url\" -O \"$DOWNLOAD_DIR/rustup-init\""
        return
    fi

    # 三组并列地址：init 下载地址 / RUSTUP_DIST_SERVER / RUSTUP_UPDATE_ROOT
    local -a fb_init=(
        "${RUSTUP_INIT_URL}"
        "https://rsproxy.cn/rustup"
        "https://static.rust-lang.org/rustup"
    )
    local -a fb_dist=(
        "${RUSTUP_DIST_SERVER}"
        "https://rsproxy.cn/rustup"
        "https://static.rust-lang.org"
    )
    local -a fb_update=(
        "${RUSTUP_UPDATE_ROOT}"
        "https://rsproxy.cn/rustup"
        "https://static.rust-lang.org/rustup"
    )

    local i idx=-1
    for i in "${!fb_init[@]}"; do
        local url="${fb_init[$i]}/dist/${RUST_TARGET}/rustup-init"
        # 跳过空地址与重复的当前源
        [[ -z "${fb_init[$i]}" ]] && continue
        log_info "尝试下载: $url"
        rm -f "$DOWNLOAD_DIR/rustup-init"
        if try_download "$url" "$DOWNLOAD_DIR/rustup-init" && [[ -s "$DOWNLOAD_DIR/rustup-init" ]]; then
            idx=$i
            break
        fi
        log_warn "下载失败，尝试下一个源..."
    done

    if [[ "$idx" -lt 0 ]]; then
        log_error "所有源下载均失败，请检查网络连接"
        log_error "可尝试: $0 --mirror auto 自动选择可用镜像"
        exit 1
    fi

    # 绑定实际下载成功的源，供后续工具链安装使用
    RUSTUP_DIST_SERVER="${fb_dist[$idx]}"
    RUSTUP_UPDATE_ROOT="${fb_update[$idx]}"
    # 若发生回退，cargo 镜像同步切换，避免依赖下载仍指向不可用的源
    case "$idx" in
        1) CARGO_MIRROR_URL="sparse+https://rsproxy.cn/index/" ;;   # 回退到 rsproxy
        2) CARGO_MIRROR_URL="" ;;                                   # 回退到官方，不配置镜像
    esac
    chmod +x "$DOWNLOAD_DIR/rustup-init"
    log_success "下载完成: $DOWNLOAD_DIR/rustup-init (来自 ${fb_init[$idx]})"
}

# 安装 Rust（以目标用户身份执行，确保安装到真实用户的 home）
install_rust() {
    log_info "安装 Rust 工具链 ${TOOLCHAIN} (profile: ${PROFILE})..."

    # 以目标用户身份执行 rustup-init（sudo 安装时切回真实用户，root 直接执行）
    local run_as=""
    if [[ "$EUID" -eq 0 && "$REAL_USER" != "root" ]]; then
        run_as="sudo -u $REAL_USER -H"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] HOME=$REAL_HOME RUSTUP_DIST_SERVER=$RUSTUP_DIST_SERVER RUSTUP_UPDATE_ROOT=$RUSTUP_UPDATE_ROOT"
        log_info "[DRY-RUN] $run_as $DOWNLOAD_DIR/rustup-init -y --default-toolchain $TOOLCHAIN --profile $PROFILE --no-modify-path"
        return
    fi

    # 除临时目录外的路径都指向目标用户 home；使 root 也能读到下载文件
    chmod -R a+rX "$DOWNLOAD_DIR" 2>/dev/null || true
    if ! HOME="$REAL_HOME" RUSTUP_HOME="$RUSTUP_HOME" CARGO_HOME="$CARGO_HOME" \
         RUSTUP_DIST_SERVER="$RUSTUP_DIST_SERVER" RUSTUP_UPDATE_ROOT="$RUSTUP_UPDATE_ROOT" \
         $run_as "$DOWNLOAD_DIR/rustup-init" -y \
         --default-toolchain "$TOOLCHAIN" \
         --profile "$PROFILE" \
         --no-modify-path; then
        log_error "安装失败，请查看上方错误信息"
        exit 1
    fi
    # 释放目标用户目录的写权限（rustup 默认创建的 umask 会影响用户后续操作）
    chown -R "$REAL_USER" "$REAL_HOME/.rustup" "$REAL_HOME/.cargo" 2>/dev/null || true

    log_success "Rust 安装完成"
}

# 配置环境变量 (source $CARGO_HOME/env)
configure_env() {
    log_info "配置环境变量..."

    local shell_rc=""
    local user_shell="${SHELL##*/}"
    if command -v getent &>/dev/null; then
        user_shell=$(getent passwd "$REAL_USER" | cut -d: -f7 | xargs basename)
    fi
    case "$user_shell" in
        bash)   shell_rc="$REAL_HOME/.bashrc" ;;
        zsh)    shell_rc="$REAL_HOME/.zshrc" ;;
        *)      shell_rc="$REAL_HOME/.profile" ;;
    esac

    # 安全校验：env 文件必须真实存在，避免写入悬空路径导致 bash 报错
    if [[ "$DRY_RUN" != "true" && ! -f "$CARGO_HOME/env" ]]; then
        log_error "未找到 $CARGO_HOME/env，安装可能未完成"
        log_error "请确认 rustup-init 已成功执行（可手动运行: ls $CARGO_HOME/bin）"
        return 1
    fi

    # 检查是否已配置 - 先清理旧配置
    if grep -q 'cargo/env' "$shell_rc" 2>/dev/null; then
        log_warn "检测到旧的 Rust 环境变量配置，将替换为新配置"
        sed -i '/# Rust 环境变量/,/^\. .*\.cargo\/env$/d' "$shell_rc"
    fi

    # 写入配置
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} cat >> \"$shell_rc\" << 'EOF'"
        echo -e "  # Rust 环境变量"
        echo -e "  . \"$CARGO_HOME/env\""
        echo -e "  ${YELLOW}EOF${NC}"
    else
        cat >> "$shell_rc" << EOF

# Rust 环境变量
. "$CARGO_HOME/env"
EOF
    fi
    log_success "环境变量已添加到 $shell_rc (用户: $REAL_USER)"

    # 当前会话生效
    if [[ "$DRY_RUN" != "true" && -f "$CARGO_HOME/env" ]]; then
        # shellcheck disable=SC1090
        . "$CARGO_HOME/env"
    fi
}

# 配置 cargo 国内镜像 (~/.cargo/config.toml)
configure_cargo_mirror() {
    if [[ "$CONFIGURE_CARGO_MIRROR" != "true" || "$MIRROR" == "official" ]]; then
        log_info "跳过 cargo 国内镜像配置"
        return
    fi

    local cargo_dir="$REAL_HOME/.cargo"
    local config_file="$cargo_dir/config.toml"

    log_info "配置 cargo 国内镜像 ($MIRROR): ${CARGO_MIRROR_URL}"

    run_cmd "mkdir -p \"$cargo_dir\""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} 写入 $config_file:"
        echo -e "  # Rust crates.io 镜像配置 (由 rust_install.sh 生成)"
        echo -e "  [source.crates-io]"
        echo -e "  replace-with = 'mirror'"
        echo -e "  [source.mirror]"
        echo -e "  registry = \"$CARGO_MIRROR_URL\""
        return
    fi

    # 备份已有配置文件
    if [[ -f "$config_file" ]] && grep -q '\[source\.crates-io\]' "$config_file" \
       && [[ ! -f "${config_file}.bak" ]]; then
        cp "$config_file" "${config_file}.bak"
        log_warn "已备份原配置文件到 ${config_file}.bak"
    elif [[ -f "$cargo_dir/config" ]] && [[ ! -f "$config_file" ]]; then
        cp "$cargo_dir/config" "${config_file}.bak"
        log_warn "检测到旧版配置文件 $cargo_dir/config，已备份到 ${config_file}.bak"
    fi

    # 移除旧的 crates-io 镜像配置块，避免残留冲突
    if [[ -f "$config_file" ]]; then
        sed -i '/^# Rust crates.io 镜像配置/,/^\[source\.\]*/d' "$config_file" 2>/dev/null || true
        sed -i '/^\[source\.crates-io\]$/,+2d' "$config_file"
    fi

    cat >> "$config_file" << EOF

# Rust crates.io 镜像配置 (由 rust_install.sh 生成)
[source.crates-io]
replace-with = 'mirror'

[source.mirror]
registry = "$CARGO_MIRROR_URL"
EOF

    log_success "cargo 镜像配置完成: $config_file"
    log_info "如需还原: mv ${config_file}.bak $config_file (若存在)"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] rustc --version"
        log_info "[DRY-RUN] cargo --version"
        log_info "[DRY-RUN] rustup --version"
        return
    fi

    local bin_dir="$CARGO_HOME/bin"

    if [[ -x "$bin_dir/rustc" ]]; then
        log_success "rustc 版本: $("$bin_dir/rustc" --version)"
    else
        log_error "rustc 验证失败，请检查安装"
        exit 1
    fi

    if [[ -x "$bin_dir/cargo" ]]; then
        log_success "cargo 版本: $("$bin_dir/cargo" --version)"
    fi
    if [[ -x "$bin_dir/rustup" ]]; then
        log_success "rustup 版本: $("$bin_dir/rustup" --version)"
        log_info "已安装工具链: $("$bin_dir/rustup" toolchain list | tr '\n' ' ')"
    fi
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
    echo -e "${BLUE}     Rust 安装脚本 (rustup 官方工具链)${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo

    validate_options
    preflight_check
    show_plan

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "模拟运行模式，不执行实际操作"
        echo
    fi

    download_rustup_init
    install_rust
    configure_env
    configure_cargo_mirror
    verify_installation
    cleanup

    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}     安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "请运行以下命令使环境变量立即生效:"
    echo -e "  ${YELLOW}source ~/.cargo/env${NC}  (或重新打开终端)"
    echo
    echo -e "验证安装:"
    echo -e "  ${YELLOW}rustc --version${NC}"
    echo -e "  ${YELLOW}cargo --version${NC}"
    echo
    echo -e "开始编程:"
    echo -e "  ${YELLOW}cargo new hello_world && cd hello_world${NC}"
    echo -e "  ${YELLOW}cargo run${NC}"
    echo
    echo -e "常用命令:"
    echo -e "  ${YELLOW}rustup update${NC}            升级工具链"
    echo -e "  ${YELLOW}rustup component add rustfmt${NC}  安装 rustfmt 格式化组件 (默认已含)"
    echo -e "  ${YELLOW}rustup self uninstall${NC}    卸载 Rust"
}

# 捕获中断信号
trap cleanup EXIT INT TERM

# 运行主函数
main "$@"