#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-05-03 23:55:42
# @version     : bash
# @Update time : 2026-05-03
# @Description : 快速创建 Dockerfile 文件，支持多种基础镜像和常用配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认输出目录
OUTPUT_DIR="$(pwd)"
DOCKERFILE_PATH=""

# 基础镜像选项
BASE_IMAGES=(
    "ubuntu:22.04"
    "ubuntu:20.04"
    "debian:12"
    "debian:11"
    "centos:7"
    "centos:8"
    "alpine:3.18"
    "node:18-alpine"
    "node:16-alpine"
    "python:3.11-slim"
    "python:3.10-slim"
    "openjdk:17-slim"
    "openjdk:11-slim"
    "golang:1.21-alpine"
    "nginx:alpine"
    "mysql:8.0"
    "redis:7-alpine"
)

# 打印信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示用法
show_usage() {
    cat << EOF
用法: $0 [选项]

快速创建 Dockerfile 文件

选项:
    -o, --output DIR     指定输出目录 (默认: 当前目录)
    -n, --name NAME      指定 Dockerfile 名称 (默认: Dockerfile)
    -b, --base IMAGE     指定基础镜像
    -h, --help           显示帮助信息

示例:
    $0                          # 交互式创建
    $0 -b ubuntu:22.04         # 使用指定基础镜像
    $0 -o ./myapp -n Dockerfile # 指定输出目录和文件名

EOF
}

# 交互式选择基础镜像
select_base_image() {
    echo "请选择基础镜像:"
    echo ""
    for i in "${!BASE_IMAGES[@]}"; do
        echo "  $((i+1)). ${BASE_IMAGES[$i]}"
    done
    echo ""
    read -ep "请输入选项 [1-${#BASE_IMAGES[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#BASE_IMAGES[@]} ]; then
        SELECTED_BASE_IMAGE="${BASE_IMAGES[$((choice-1))]}"
    else
        print_error "无效的选择，使用默认镜像"
        SELECTED_BASE_IMAGE="ubuntu:22.04"
    fi
}

# 检查并设置包管理器
detect_package_manager() {
    local base_image="$1"
    case "$base_image" in
        *alpine*)
            echo "apk"
            ;;
        *centos*|*rhel*)
            echo "yum"
            ;;
        *debian*|*ubuntu*)
            echo "apt"
            ;;
        *)
            echo "apt"
            ;;
    esac
}

# 生成 apk 包管理器安装命令
gen_apk_install() {
    cat << 'EOF'
RUN apk update && apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    tzdata \
    openssh-client \
    && rm -rf /var/cache/apk/*

EOF
}

# 生成 yum 包管理器安装命令
gen_yum_install() {
    cat << 'EOF'
RUN yum -y update && yum install -y \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    tzdata \
    openssh-clients \
    && yum clean all \
    && rm -rf /var/cache/yum

EOF
}

# 生成 apt 包管理器安装命令
gen_apt_install() {
    cat << 'EOF'
RUN apt-get update && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    tzdata \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

EOF
}

# 显示常用工具菜单并获取用户选择
show_tools_menu() {
    echo ""
    echo "请选择要安装的常用工具 (多选，用空格分隔，如: 1 2 3):"
    echo ""
    echo "  1. [基础工具] bash, curl, wget, git, vim"
    echo "  2. [开发工具] gcc, g++, make, cmake, python3, python3-pip"
    echo "  3. [Node.js环境] nodejs, npm (仅非Node基础镜像)"
    echo "  4. [Python环境] python3, pip (仅非Python基础镜像)"
    echo "  5. [Java环境] openjdk (仅非Java基础镜像)"
    echo "  6. [Go环境] go (仅非Go基础镜像)"
    echo "  7. [Docker工具] docker-cli, docker-compose"
    echo "  8. [Kubernetes工具] kubectl, helm"
    echo "  9. [网络工具] iputils-ping, net-tools, tcpdump, nmap"
    echo " 10. [文本处理] grep, awk, sed, coreutils"
    echo ""
    printf "请输入选项: "
}

# 生成工具安装命令
gen_tool_installation() {
    local choices=("$@")
    local pkg_manager="$1"
    local base_image="$2"
    local install_cmds=""

    # 判断是否为基础镜像自带
    is_nodejs_base=false
    is_python_base=false
    is_java_base=false
    is_go_base=false

    [[ "$base_image" == node:* ]] && is_nodejs_base=true
    [[ "$base_image" == nodejs:* ]] && is_nodejs_base=true
    [[ "$base_image" == python:* ]] && is_python_base=true
    [[ "$base_image" == openjdk:* ]] && is_java_base=true
    [[ "$base_image" == golang:* ]] && is_go_base=true

    for choice in "${choices[@]}"; do
        case "$choice" in
            1)
                # 基础工具
                case "$pkg_manager" in
                    apk) install_cmds+=$(gen_apk_install) ;;
                    yum) install_cmds+=$(gen_yum_install) ;;
                    apt) install_cmds+=$(gen_apt_install) ;;
                esac
                ;;
            2)
                # 开发工具
                case "$pkg_manager" in
                    apk)
                        install_cmds+='RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    cmake \
    python3 \
    py3-pip \
    && rm -rf /var/cache/apk/*

'
                        ;;
                    yum)
                        install_cmds+='RUN yum -y install \
    gcc \
    gcc-c++ \
    make \
    cmake \
    python3 \
    python3-pip \
    && yum clean all

'
                        ;;
                    apt)
                        install_cmds+='RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

'
                        ;;
                esac
                ;;
            3)
                # Node.js环境
                if [[ "$is_nodejs_base" == false ]]; then
                    case "$pkg_manager" in
                        apk) install_cmds+='RUN apk add --no-cache nodejs npm

' ;;
                        yum) install_cmds+='RUN curl -fsSL https://rpm.nodesource.com/setup18.x | bash - && yum install -y nodejs

' ;;
                        apt) install_cmds+='RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs

' ;;
                    esac
                fi
                ;;
            4)
                # Python环境
                if [[ "$is_python_base" == false ]]; then
                    case "$pkg_manager" in
                        apk) install_cmds+='RUN apk add --no-cache python3 py3-pip

' ;;
                        yum) install_cmds+='RUN yum -y install python3 python3-pip

' ;;
                        apt) install_cmds+='RUN apt-get update && apt-get install -y python3 python3-pip

' ;;
                    esac
                fi
                ;;
            5)
                # Java环境
                if [[ "$is_java_base" == false ]]; then
                    case "$pkg_manager" in
                        apk) install_cmds+='RUN apk add --no-cache openjdk17-jre-headless

' ;;
                        yum) install_cmds+='RUN yum install -y java-17-openjdk java-17-openjdk-devel

' ;;
                        apt) install_cmds+='RUN apt-get update && apt-get install -y openjdk-17-jre-headless openjdk-17-jdk

' ;;
                    esac
                fi
                ;;
            6)
                # Go环境
                if [[ "$is_go_base" == false ]]; then
                    case "$pkg_manager" in
                        apk) install_cmds+='RUN apk add --no-cache go

' ;;
                        yum) install_cmds+='RUN yum -y install golang

' ;;
                        apt) install_cmds+='RUN apt-get update && apt-get install -y golang-go

' ;;
                    esac
                fi
                ;;
            7)
                # Docker工具
                case "$pkg_manager" in
                    apk) install_cmds+='RUN apk add --no-cache docker-cli docker-compose

' ;;
                    yum) install_cmds+='RUN yum -y install docker-cli docker-compose

' ;;
                    apt) install_cmds+='RUN apt-get update && apt-get install -y docker.io docker-compose

' ;;
                esac
                ;;
            8)
                # Kubernetes工具
                case "$pkg_manager" in
                    apk)
                        install_cmds+='RUN wget -qO /usr/local/bin/kubectl https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    wget -qO /usr/local/bin/helm https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz && \
    tar -xzf /usr/local/bin/helm -C /usr/local/bin && \
    rm /usr/local/bin/helm

'
                        ;;
                    yum|apt)
                        install_cmds+='RUN curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/ && \
    curl -L https://get.helm.sh/helm-v3.13.0-linux-amd64.tar.gz -o /tmp/helm.tar.gz && \
    tar -zxf /tmp/helm.tar.gz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/ && \
    rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

'
                        ;;
                esac
                ;;
            9)
                # 网络工具
                case "$pkg_manager" in
                    apk) install_cmds+='RUN apk add --no-cache iputils postgresql-client mariadb-client net-tools tcpdump nmap

' ;;
                    yum) install_cmds+='RUN yum -y install iputils postgresql mysql mariadb net-tools tcpdump nmap

' ;;
                    apt) install_cmds+='RUN apt-get update && apt-get install -y iputils-ping postgresql-client default-mysql-client net-tools tcpdump nmap

' ;;
                esac
                ;;
            10)
                # 文本处理工具
                case "$pkg_manager" in
                    apk) install_cmds+='RUN apk add --no-cache grep awk sed coreutils findutils

' ;;
                    yum) install_cmds+='RUN yum -y install grep gawk sed coreutils findutils

' ;;
                    apt) install_cmds+='RUN apt-get update && apt-get install -y grep gawk sed coreutils findutils

' ;;
                esac
                ;;
        esac
    done

    echo "$install_cmds"
}

# 交互式配置端口和环境变量
configure_ports_and_env() {
    echo ""
    read -ep "是否配置端口映射? (y/N): " configure_ports
    if [[ "$configure_ports" =~ ^[Yy]$ ]]; then
        read -ep "请输入要暴露的端口 (多个用空格分隔，如: 80 443 8080): " -ea PORTS
        if [ ${#PORTS[@]} -gt 0 ]; then
            for port in "${PORTS[@]}"; do
                echo "EXPOSE $port" >> "$DOCKERFILE_PATH"
            done
        fi
    fi

    echo ""
    read -ep "是否配置环境变量? (y/N): " configure_env
    if [[ "$configure_env" =~ ^[Yy]$ ]]; then
        read -ep "请输入环境变量 (格式: KEY=VALUE，多个用空格分隔): " -ea ENV_VARS
        if [ ${#ENV_VARS[@]} -gt 0 ]; then
            for env_var in "${ENV_VARS[@]}"; do
                echo "ENV $env_var" >> "$DOCKERFILE_PATH"
            done
        fi
    fi
}

# 创建 Dockerfile
create_dockerfile() {
    local base_image="$1"
    local output_dir="$2"
    local filename="$3"

    DOCKERFILE_PATH="$output_dir/$filename"
    local pkg_manager=$(detect_package_manager "$base_image")

    print_info "正在创建 Dockerfile: $DOCKERFILE_PATH"
    print_info "基础镜像: $base_image"
    print_info "包管理器: $pkg_manager"

    # 写入文件头
    cat > "$DOCKERFILE_PATH" << EOF
# ===========================================
# 容器名称: ${filename%.dockerfile}
# 基础镜像: $base_image
# 创建时间: $(date '+%Y-%m-%d %H:%M:%S')
# ===========================================

FROM $base_image

# 防止交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 基础配置
EOF

    # 选择常用工具
    show_tools_menu
    read -ea TOOL_CHOICES

    # 生成工具安装命令
    TOOL_INSTALL=$(gen_tool_installation "$pkg_manager" "$base_image" "${TOOL_CHOICES[@]}")
    echo "$TOOL_INSTALL" >> "$DOCKERFILE_PATH"

    # 配置工作目录
    echo ""
    read -ep "是否设置工作目录? (y/N, 默认 /app): " set_workdir
    if [[ "$set_workdir" =~ ^[Yy]$ ]]; then
        read -ep "请输入工作目录 [默认 /app]: " WORKDIR
        WORKDIR=${WORKDIR:-/app}
    else
        WORKDIR="/app"
    fi
    echo "WORKDIR $WORKDIR" >> "$DOCKERFILE_PATH"

    # 配置端口和环境变量
    configure_ports_and_env

    # 配置启动命令
    echo ""
    read -ep "是否配置启动命令? (y/N): " set_cmd
    if [[ "$set_cmd" =~ ^[Yy]$ ]]; then
        read -ep "请输入启动命令 (如: python app.py 或 /bin/bash): " START_CMD
        if [ -n "$START_CMD" ]; then
            echo "" >> "$DOCKERFILE_PATH"
            echo "# 启动命令" >> "$DOCKERFILE_PATH"
            echo "CMD $START_CMD" >> "$DOCKERFILE_PATH"
        fi
    fi

    # 配置 COPY 命令
    echo ""
    read -ep "是否配置 COPY 文件/目录? (y/N): " set_copy
    if [[ "$set_copy" =~ ^[Yy]$ ]]; then
        echo ""
        echo "请输入要拷贝的内容 (格式: 源路径 目标路径, 多组用空格分隔)"
        echo "示例: ./src /app/src  或  ./config.json /app/config.json"
        echo ""
        read -ep "请输入: " -ea COPY_PATHS
        if [ ${#COPY_PATHS[@]} -gt 0 ]; then
            echo "" >> "$DOCKERFILE_PATH"
            echo "# 拷贝文件/目录" >> "$DOCKERFILE_PATH"
            # COPY_PATHS 是数组，每两个元素为一组: [源1, 目标1, 源2, 目标2, ...]
            local i=0
            while [ $i -lt $((${#COPY_PATHS[@]} - 1)) ]; do
                local src="${COPY_PATHS[$i]}"
                local dest="${COPY_PATHS[$((i+1))]}"
                echo "COPY $src $dest" >> "$DOCKERFILE_PATH"
                i=$((i+2))
            done
        fi
    fi

    print_success "Dockerfile 创建成功!"
    echo ""
    echo "文件位置: $DOCKERFILE_PATH"
    echo ""
    echo "=== Dockerfile 内容预览 ==="
    cat "$DOCKERFILE_PATH"
    echo ""
    echo "=== 预览结束 ==="
}

# 解析命令行参数
parse_args() {
    SELECTED_BASE_IMAGE=""
    OUTPUT_DIR="$(pwd)"
    DOCKERFILE_NAME="Dockerfile"

    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -n|--name)
                DOCKERFILE_NAME="$2"
                shift 2
                ;;
            -b|--base)
                SELECTED_BASE_IMAGE="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # 验证输出目录
    if [ ! -d "$OUTPUT_DIR" ]; then
        print_info "输出目录不存在，正在创建: $OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi

    # 选择基础镜像
    if [ -z "$SELECTED_BASE_IMAGE" ]; then
        select_base_image
    else
        SELECTED_BASE_IMAGE="$SELECTED_BASE_IMAGE"
    fi

    # 创建 Dockerfile
    create_dockerfile "$SELECTED_BASE_IMAGE" "$OUTPUT_DIR" "$DOCKERFILE_NAME"
}

# 主函数
main() {
    if [[ $# -eq 0 ]]; then
        # 交互式模式
        select_base_image
        OUTPUT_DIR="$(pwd)"
        DOCKERFILE_NAME="Dockerfile"
        create_dockerfile "$SELECTED_BASE_IMAGE" "$OUTPUT_DIR" "$DOCKERFILE_NAME"
    else
        parse_args "$@"
    fi
}

main "$@"
