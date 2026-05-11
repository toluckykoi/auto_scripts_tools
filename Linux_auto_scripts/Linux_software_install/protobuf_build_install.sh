#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-04-25 10:59:52
# @version     : bash
# @Update time :
# @Description : 编译安装ProtoBuf程序脚本

# 获取系统信息
get_system_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="${NAME}"
        OS_VERSION="${VERSION_ID}"
    elif [ -f /etc/redhat-release ]; then
        OS_NAME=$(cat /etc/redhat-release | awk '{print $1}')
        OS_VERSION=$(cat /etc/redhat-release | awk '{print $4}')
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
    fi
    echo "检测到系统: ${OS_NAME} ${OS_VERSION}"
}

# 获取总内存（MB）
get_total_memory_mb() {
    local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    echo $((mem_kb / 1024))
}

# 获取总Swap（MB）
get_total_swap_mb() {
    local swap_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
    echo $((swap_kb / 1024))
}

# 检查是否有Swap
has_swap() {
    local swap_mb=$(get_total_swap_mb)
    if [ "$swap_mb" -gt 0 ]; then
        return 0  # 有Swap
    else
        return 1  # 无Swap
    fi
}

# 检查总内存是否小于4GB
is_low_memory() {
    local mem_mb=$(get_total_memory_mb)
    local swap_mb=$(get_total_swap_mb)
    local total_mb=$((mem_mb + swap_mb))
    echo "总内存: ${total_mb} MB (内存: ${mem_mb} MB + Swap: ${swap_mb} MB)"
    if [ "$total_mb" -lt 4096 ]; then
        return 0  # 内存不足4G
    else
        return 1  # 内存充足
    fi
}

# 安装依赖
install_dependencies() {
    echo "========== 安装系统依赖 =========="
    get_system_info

    case "${OS_NAME}" in
        *Ubuntu*|*Debian*)
            sudo apt-get update
            sudo apt-get install autoconf automake libtool curl make g++ unzip -y
            ;;
        *CentOS*|*Red*|*Rocky*|*Alma*)
            sudo yum install -y autoconf automake libtool curl make gcc-c++ unzip
            ;;
        *Fedora*)
            sudo dnf install -y autoconf automake libtool curl make gcc-c++ unzip
            ;;
        *Alibaba*)
            sudo dnf install -y autoconf automake libtool curl make gcc-c++ unzip || \
            sudo yum install -y autoconf automake libtool curl make gcc-c++ unzip
            ;;
        *)
            echo "不支持的系统: ${OS_NAME}, 尝试使用 apt-get 安装依赖..."
            sudo apt-get install autoconf automake libtool curl make g++ unzip -y 2>/dev/null || \
            sudo yum install -y autoconf automake libtool curl make gcc-c++ unzip 2>/dev/null
            ;;
    esac
    echo "依赖安装完成"
}

# 下载并检查文件
download_protobuf() {
    local url="http://github.808066.xyz:38000/https://github.com/protocolbuffers/protobuf/releases/download/v21.11/protobuf-all-21.11.zip"
    local filename="protobuf-all-21.11.zip"
    local target_dir="~"

    echo "========== 下载 ProtoBuf 源码 =========="

    # 解析 ~ 为实际路径
    target_dir=$(eval echo "$target_dir")
    cd "$target_dir" || { echo "无法进入目录: $target_dir"; return 1; }

    echo "下载目录: $(pwd)"

    # 检查文件是否已存在且完整
    if [ -f "$filename" ]; then
        local existing_size=$(stat -c%s "$filename" 2>/dev/null || stat -f%z "$filename" 2>/dev/null)
        echo "文件已存在: $filename (${existing_size} bytes)"
        read -p "是否重新下载? (y/N): " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "使用现有文件"
        else
            echo "重新下载..."
            rm -f "$filename"
            wget -c "$url" || { echo "下载失败"; return 1; }
        fi
    else
        wget -c "$url" || { echo "下载失败"; return 1; }
    fi

    # 检查文件是否存在
    if [ ! -f "$filename" ]; then
        echo "错误: 文件下载失败"
        return 1
    fi

    # 检查文件大小是否合理（至少大于1MB）
    local file_size=$(stat -c%s "$filename" 2>/dev/null || stat -f%z "$filename" 2>/dev/null)
    if [ "$file_size" -lt 1048576 ]; then
        echo "错误: 文件大小异常 (${file_size} bytes)，可能下载不完整"
        return 1
    fi

    echo "文件检查通过: ${file_size} bytes"
    return 0
}

# 主函数
main() {
    local make_j_flag="-j$(nproc)"

    echo "========== 开始编译安装 ProtoBuf =========="
    echo "开始时间: $(date)"

    # 检查内存并设置编译参数
    if is_low_memory; then
        echo "检测到内存不足 4GB，使用单线程编译: -j1"
        make_j_flag="-j1"
    else
        echo "使用多线程编译: ${make_j_flag}"
    fi

    # 安装依赖
    install_dependencies

    # 下载源码
    download_protobuf || exit 1

    # 解压
    echo "========== 解压源码 =========="
    cd "$(eval echo ~)" || exit 1
    rm -rf protobuf-21.11
    unzip -o protobuf-all-21.11.zip

    cd protobuf-21.11

    # 编译
    echo "========== 编译 ProtoBuf =========="
    ./autogen.sh
    ./configure

    make ${make_j_flag}

    # 检查Swap，决定是否运行测试
    echo "========== 运行测试 =========="
    if has_swap; then
        echo "检测到Swap内存，运行测试..."
        make ${make_j_flag} check
    else
        echo "未检测到Swap内存，跳过测试 (make check)"
    fi

    # 安装
    echo "========== 安装 ProtoBuf =========="
    sudo make install
    sudo ldconfig

    # 验证
    echo "========== 验证安装 =========="
    protoc --version

    echo "完成时间: $(date)"
    echo "========== ProtoBuf 安装完成 =========="
}

main "$@"
