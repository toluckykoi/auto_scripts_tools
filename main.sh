#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-07-26 17:33:33
# @version     : bash
# @Update time :
# @Description : Auto Scripts Tools 一键脚本主程序


trap 'echo -e "\n${YELLOW}[!] 使用 q 键退出，不要用 Ctrl+C 哦~${NC}"' SIGINT SIGTERM

# ═══════════════════════════════════════════════════════════════
#  全局配置区
# ═══════════════════════════════════════════════════════════════

export LANG=en_US.UTF-8
ROOT_PPATH=$(cd "$(dirname "$0")" && pwd)
VERSION="v2.0.0"

# ---- 颜色定义 ----
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
PURPLE=$'\033[0;35m'
CYAN=$'\033[0;36m'
WHITE=$'\033[1;37m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# ---- 环境检测 ----
if [ -n "$DISPLAY" ] && xset q &>/dev/null 2>&1; then
    ENV_TYPE="${GREEN}[Desktop]${NC}"
    ENV_WARN="${YELLOW}[!] 桌面环境，请谨慎使用一键脚本！${NC}"
else
    ENV_TYPE="${CYAN}[Server]${NC}"
    ENV_WARN=""
fi

# ═══════════════════════════════════════════════════════════════
#  框绘制函数
#  右侧 ║ 用 ANSI 光标定位 (\033[75G)，让终端自己算列宽
#  不依赖 wc / tput / Python，所有终端 CJK 宽度都正确
# ═══════════════════════════════════════════════════════════════

# 跳转到第 64 列的 ANSI 序列 (CHA: Cursor Horizontal Absolute)
readonly GOTO_75=$'\033[75G'

# 硬编码边框 (每条含 73 个 ═，加角符总宽 75)
readonly BORDER_TOP="${CYAN}╔═════════════════════════════════════════════════════════════════════════╗${NC}"
readonly BORDER_SEP="${CYAN}╠═════════════════════════════════════════════════════════════════════════╣${NC}"
readonly BORDER_BOT="${CYAN}╚═════════════════════════════════════════════════════════════════════════╝${NC}"

box_top()    { echo -e "$BORDER_TOP"; }
box_bottom() { echo -e "$BORDER_BOT"; }
box_sep()    { echo -e "$BORDER_SEP"; }

box_empty() {
    printf "${CYAN}║${NC}${GOTO_75}${CYAN}║${NC}\n"
}

box_line() {
    local content="$1"
    local border_color="${2:-${CYAN}}"
    printf "${border_color}║${NC} %s${GOTO_75}${border_color}║${NC}\n" "$content"
}

# 纯 bash 计算字符串终端显示宽度 (ASCII=1, CJK/全角=2)
# 只依赖 bash 内置，不调用 wc / tput 等外部命令
_str_width() {
    local str="$1" width=0 i len first_byte
    len=${#str}  # bash 按字符数 (非字节)
    for ((i = 0; i < len; i++)); do
        first_byte=$(LC_ALL=C printf '%d' "'${str:$i:1}")
        if [ "$first_byte" -lt 128 ]; then
            width=$((width + 1))       # ASCII
        elif [ "$first_byte" -lt 224 ]; then
            width=$((width + 1))       # 2-byte UTF-8 (Latin ext)
        elif [ "$first_byte" -lt 240 ]; then
            width=$((width + 2))       # 3-byte UTF-8 (CJK)
        else
            width=$((width + 2))       # 4-byte UTF-8 (emoji)
        fi
    done
    echo "$width"
}

# 居中内容行
# 纯 bash 算文字宽 + ANSI 绝对列定位起笔
# 公式: 起笔列 = 左边距 3 + (可用宽 72 - 文字宽) / 2
box_center() {
    local content="$1"
    local border_color="${2:-${CYAN}}"
    local esc cleaned text_width
    esc=$(printf '\033')
    cleaned=$(printf '%s' "$content" | sed "s/${esc}\[[0-9;]*m//g")
    text_width=$(_str_width "$cleaned")
    local start_col=$(( 3 + (72 - text_width) / 2 ))
    [ $start_col -lt 3 ] && start_col=3
    printf "${border_color}║${NC}\033[${start_col}G%s${GOTO_75}${border_color}║${NC}\n" "$content"
}

# ═══════════════════════════════════════════════════════════════
#  菜单公共渲染函数
# ═══════════════════════════════════════════════════════════════

print_menu_item() {
    local num="$1"
    local name="$2"
    local desc="$3"
    box_line "  ${GREEN}${num}${NC}   | ${WHITE}${name}${NC}"
    if [ -n "$desc" ]; then
        box_line "        └── ${CYAN}${desc}${NC}"
    fi
}

print_sub_menu_item() {
    local num="$1"
    local name="$2"
    box_line "  ${GREEN}${num}${NC}  | ${WHITE}${name}${NC}"
}

draw_footer() {
    box_sep
    box_line "${YELLOW}0${NC} / ${YELLOW}b${NC} = 返回上级    ${YELLOW}q${NC} = 退出程序"
    box_bottom
}

draw_main_header() {
    clear
    box_top
    box_empty
    box_center "${BOLD}${GREEN}Auto Scripts Tools 一键脚本主界面 ${WHITE}${VERSION}${NC}"
    box_empty
    box_sep
    box_line "检测到当前环境：${ENV_TYPE}"
    if [ -n "$ENV_WARN" ]; then
        box_line "${ENV_WARN}"
    fi
    box_sep
    box_line "${WHITE}编号 | 功能分类${NC}"
    box_sep
}

draw_section_header() {
    local title="$1"
    clear
    box_top
    box_center "${BOLD}${GREEN}Auto Scripts Tools${NC}"
    box_line "${WHITE}${title}${NC}"
    box_sep
    box_line "${WHITE}编号 | 功能说明${NC}"
    box_sep
}

# ═══════════════════════════════════════════════════════════════
#  脚本执行工具
# ═══════════════════════════════════════════════════════════════

press_any_key() {
    echo ""
    echo -ne "${YELLOW}>>> 按任意键返回菜单...${NC}"
    read -n 1 -s -r
    echo ""
}

run_script() {
    local dir="$1"
    local script="$2"
    local type="${3:-sh}"

    clear
    box_top
    box_line "${BOLD}${PURPLE}=> 正在启动: ${script}${NC}"
    box_bottom
    echo ""

    local script_path="$ROOT_PPATH/$dir/$script"

    if [ ! -f "$script_path" ]; then
        echo -e "${RED}[X] 错误: 脚本不存在 -- $script_path${NC}"
        echo ""
        echo -e "${YELLOW}请检查仓库文件是否完整。${NC}"
        press_any_key
        return 1
    fi

    trap - SIGINT SIGTERM
    cd "$ROOT_PPATH/$dir"

    case "$type" in
        sudo) sudo bash "$script" ;;
        py)   python3 "$script" ;;
        *)    bash "$script" ;;
    esac

    local exit_code=$?
    cd "$ROOT_PPATH"
    trap 'echo -e "\n${YELLOW}[!] 使用 q 键退出，不要用 Ctrl+C 哦~${NC}"' SIGINT SIGTERM

    echo ""
    if [ $exit_code -eq 0 ] || [ $exit_code -eq 130 ]; then
        echo -e "${GREEN}[OK] 脚本执行结束 (退出码: $exit_code)${NC}"
    else
        echo -e "${RED}[X] 脚本执行异常 (退出码: $exit_code)${NC}"
    fi
    press_any_key
    return 0
}

# ═══════════════════════════════════════════════════════════════
#  子菜单函数区 (大分类的子菜单)
# ═══════════════════════════════════════════════════════════════

# ---- 1. 系统信息查询 ----
menu_sys_info() {
    while true; do
        draw_section_header "[1] 系统信息查询"
        print_sub_menu_item "1" "查看系统综合信息 (system_info)"
        print_sub_menu_item "2" "快速获取系统基本信息 (common_info)"
        box_sep
        print_sub_menu_item "s" "快速显示 neofetch 系统信息"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "system_info.sh" "sh" ;;
            2) run_script "Linux_auto_scripts" "common_info_acquisition.sh" "sh" ;;
            [sS]) clear; neofetch 2>/dev/null || echo -e "${YELLOW}neofetch 未安装，请先安装 neofetch${NC}"; press_any_key ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 2. 系统管理工具 ----
menu_sys_mgmt() {
    while true; do
        draw_section_header "[2] 系统管理工具"
        print_sub_menu_item "1"  "一键系统初始化 (完整配置新系统)"
        print_sub_menu_item "2"  "虚拟内存 / swap 管理"
        print_sub_menu_item "3"  "自动挂载未分区磁盘"
        print_sub_menu_item "4"  "修改主机名"
        print_sub_menu_item "5"  "更换系统软件源镜像 (USTC/Tsinghua)"
        print_sub_menu_item "6"  "iptables 防火墙管理"
        print_sub_menu_item "7"  "Crontab 定时任务管理"
        print_sub_menu_item "8"  "网络优先级设置 (多网卡路由)"
        print_sub_menu_item "9"  "路由器连通性监控 (ping 日志)"
        print_sub_menu_item "10" "SSH 登录监控 & 防暴力破解"
        print_sub_menu_item "11" "Debian 最小化安装 sudo 初始化"
        print_sub_menu_item "12" "中文目录名 -> 英文目录名"
        print_sub_menu_item "13" "修复 CH340/CH341 USB 串口驱动冲突"
        print_sub_menu_item "14" "创建虚拟串口对 (socat)"
        print_sub_menu_item "15" "VMware 共享文件夹挂载"
        print_sub_menu_item "16" "Conda 初始化 & 镜像配置"
        print_sub_menu_item "17" "GNOME 桌面壁纸自动切换"
        print_sub_menu_item "18" "Python 虚拟环境部署"
        print_sub_menu_item "19" "更换系统软件源镜像 (root 直装版)"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1)  run_script "Linux_auto_scripts/System_Init_Scripts" "linux_init_script.sh" "sudo" ;;
            2)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "swap_set.sh" "sudo" ;;
            3)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "auto_mount_disk.sh" "sudo" ;;
            4)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "change_hostname.sh" "sudo" ;;
            5)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "change_source_mirror.sh" "sudo" ;;
            6)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "iptables_manage.sh" "sudo" ;;
            7)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "crontab_helper.sh" "sh" ;;
            8)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "network_priority_set.sh" "sudo" ;;
            9)  run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "check_router.sh" "sh" ;;
            10) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "monitoring_ssh_login.sh" "sudo" ;;
            11) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "debian_mini_system_init.sh" "sudo" ;;
            12) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "change_home_dir_name.sh" "sh" ;;
            13) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "fix_ch34x_brltty.sh" "sudo" ;;
            14) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "virtual_serial_set.sh" "sh" ;;
            15) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "vm_mount_share_folder.sh" "sh" ;;
            16) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "conda_init.sh" "sh" ;;
            17) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "gnome_change_wallpaper.sh" "sh" ;;
            18) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "py_virtual_env_dep.sh" "sh" ;;
            19) run_script "Linux_auto_scripts/Shell_Scripts_Correlation" "root_change_source_mirror.sh" "sudo" ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 3. 基础工具管理 ----
menu_basic_tools() {
    while true; do
        draw_section_header "[3] 基础工具管理 (apt / 源码编译安装)"
        print_sub_menu_item "1"  "Node.js (NVM) 安装 & 镜像加速"
        print_sub_menu_item "2"  "PM2 进程管理器安装"
        print_sub_menu_item "3"  "Python 源码编译安装 (2.7 / 3.8)"
        print_sub_menu_item "4"  "Python virtualenvwrapper 安装配置"
        print_sub_menu_item "5"  "Python pip 镜像源初始化"
        print_sub_menu_item "6"  "Jupyter 安装 / 卸载 (虚拟环境)"
        print_sub_menu_item "7"  "Protobuf 源码编译安装"
        print_sub_menu_item "8"  "Nginx + Nginx UI 面板安装"
        print_sub_menu_item "9"  "Boot-Repair 启动修复工具"
        print_sub_menu_item "10" "内网穿透工具部署 (ZeroTier / Tailscale / Frp)"
        print_sub_menu_item "11" "NPS 内网穿透服务端安装"
        print_sub_menu_item "12" "编程字体安装 (CascadiaCode / JetBrainsMono)"
        print_sub_menu_item "13" "Windows 兼容字体安装"
        print_sub_menu_item "14" "WPS Office 符号字体修复"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1)  run_script "Linux_auto_scripts/Linux_software_install" "nvm_nodejs_install.sh" "sh" ;;
            2)  run_script "Linux_auto_scripts/Linux_software_install" "install_pm2.sh" "sh" ;;
            3)  run_script "Linux_auto_scripts/Linux_software_install" "python_install.sh" "sh" ;;
            4)  run_script "Linux_auto_scripts/Linux_software_install" "py_virtualenv_install.sh" "sh" ;;
            5)  run_script "Python_Correlation" "pip_initialize.sh" "sh" ;;
            6)  run_script "Linux_auto_scripts/Linux_software_install" "jupyter_install.sh" "sh" ;;
            7)  run_script "Linux_auto_scripts/Linux_software_install" "protobuf_build_install.sh" "sh" ;;
            8)  run_script "Linux_auto_scripts/Linux_software_install" "nginx_ui_install.sh" "sh" ;;
            9)  run_script "Linux_auto_scripts/Linux_software_install" "boot-repair_install.sh" "sh" ;;
            10) run_script "Linux_auto_scripts/Linux_software_install" "int_penetration_deploy.sh" "sh" ;;
            11) run_script "Linux_auto_scripts/Linux_software_install" "nps_install.sh" "sh" ;;
            12) run_script "Linux_auto_scripts/Shell_Scripts_Correlation/linux_fonts" "linux_fonts_install.sh" "sh" ;;
            13) run_script "Linux_auto_scripts/Shell_Scripts_Correlation/linux_fonts" "windows_fonts_install.sh" "sh" ;;
            14) run_script "Linux_auto_scripts/Shell_Scripts_Correlation/linux_fonts" "wps_fonts_repair.sh" "sh" ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 4. Docker 管理专栏 ----
menu_docker() {
    while true; do
        draw_section_header "[4] Docker 管理专栏"
        print_sub_menu_item "1" "一键安装 Docker + Docker Compose"
        print_sub_menu_item "2" "单独安装 Docker Compose"
        print_sub_menu_item "3" "交互式 Dockerfile 生成器"
        print_sub_menu_item "4" "NVIDIA Container Toolkit 安装"
        print_sub_menu_item "5" "Docker ROS Melodic 容器初始化"
        print_sub_menu_item "6" "Docker ROS Noetic 容器初始化"
        print_sub_menu_item "7" "Docker ROS 安装 (Python 脚本)"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1) run_script "Docker_Correlation" "docker_install.sh" "sudo" ;;
            2) run_script "Docker_Correlation" "docker_compose_install.sh" "sudo" ;;
            3) run_script "Docker_Correlation" "create_dockerfile.sh" "sh" ;;
            4) run_script "Linux_auto_scripts/nvidia-container-toolkit-install" "nvidia-container-toolkit-script.sh" "sudo" ;;
            5) run_script "Ros_Correlation" "docker_melodic_init.sh" "sh" ;;
            6) run_script "Ros_Correlation" "docker_noetic_init.sh" "sh" ;;
            7) run_script "Ros_Correlation/fishros_mod" "install_ros_with_docker.py" "py" ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 5. ROS 管理专栏 ----
menu_ros() {
    while true; do
        draw_section_header "[5] ROS 管理专栏"
        print_sub_menu_item "1"  "一键安装 ROS (Kinetic/Melodic/Noetic/Foxy/Galactic/Humble)"
        print_sub_menu_item "2"  "rosdep 初始化 (USTC 镜像加速)"
        print_sub_menu_item "3"  "修复 ROS APT 源 (NJU/Tsinghua/USTC)"
        print_sub_menu_item "4"  "安装 ROS 常用依赖包"
        print_sub_menu_item "5"  "编译安装 cJSON (C JSON 库)"
        print_sub_menu_item "6"  "编译安装 OpenCV (可自定义版本)"
        print_sub_menu_item "7"  "安装 Mapviz 依赖"
        print_sub_menu_item "8"  "ROS1 Melodic 批量依赖安装"
        print_sub_menu_item "9"  "ROS1 Noetic 批量依赖安装"
        print_sub_menu_item "10" "ROS2 Humble 批量依赖安装"
        print_sub_menu_item "11" "虚拟 CAN 接口管理 (VCAN)"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1)  run_script "Ros_Correlation" "install_ros.sh" "sudo" ;;
            2)  run_script "Ros_Correlation" "rosdistro_init.sh" "sh" ;;
            3)  run_script "Ros_Correlation" "fix_ros_sources.sh" "sudo" ;;
            4)  run_script "Ros_Correlation" "install_add_pkgs.sh" "sh" ;;
            5)  run_script "Ros_Correlation" "build_cJSON.sh" "sh" ;;
            6)  run_script "Ros_Correlation" "build_opencv_xxx.sh" "sh" ;;
            7)  run_script "Ros_Correlation" "mapviz_depend.sh" "sh" ;;
            8)  run_script "Envs_install/ros_env_install" "ros1_melodic_env.sh" "sh" ;;
            9)  run_script "Envs_install/ros_env_install" "ros1_noetic_env.sh" "sh" ;;
            10) run_script "Envs_install/ros_env_install" "ros2_humble_env.sh" "sh" ;;
            11) run_script "CAN" "vcan_manager.sh" "sh" ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 6. 服务器专栏 ----
menu_server() {
    while true; do
        draw_section_header "[6] 服务器专栏"
        print_sub_menu_item "1" "服务器巡检 (健康检查报告)"
        print_sub_menu_item "2" "MySQL 8.0 安装 (Debian)"
        print_sub_menu_item "3" "Ubuntu 18.04 常用依赖一键安装"
        print_sub_menu_item "4" "Hexo 博客环境部署"
        print_sub_menu_item "5" "宝塔面板 + Docker 系统初始化"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1) run_script "Server_Patrol_Script" "server_patrol.sh" "sh" ;;
            2) run_script "Mysql" "mysql8.0_install.sh" "sh" ;;
            3) run_script "Envs_install/system_env_install" "ubuntu18_common.sh" "sh" ;;
            4) run_script "Linux_auto_scripts/System_Init_Scripts" "setup_hexo.sh" "sh" ;;
            5) run_script "Linux_auto_scripts/System_Init_Scripts" "linux_init_script.sh" "sudo" ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 7. 应用市场 ----
menu_app_store() {
    while true; do
        draw_section_header "[7] 应用市场"
        print_sub_menu_item "1"  "Claude Code CLI 安装"
        print_sub_menu_item "2"  "OpenClaw AI 编程工具安装"
        print_sub_menu_item "3"  "Google Chrome 浏览器安装"
        print_sub_menu_item "4"  "Microsoft Edge 浏览器安装"
        print_sub_menu_item "5"  "RustDesk 远程桌面安装"
        print_sub_menu_item "6"  "X-UI (Xray 面板) 安装"
        print_sub_menu_item "7"  "Kangle Web 服务器面板"
        print_sub_menu_item "8"  "云锁安全 Agent 安装"
        print_sub_menu_item "9"  "Synology ABB Agent 安装"
        print_sub_menu_item "10" "EMQX MQTT Broker 安装 (Debian)"
        print_sub_menu_item "11" "mkfile_manager -- 创建/管理脚本文件模板"
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1)  run_script "AI_platform" "claude_code_install.sh" "sh" ;;
            2)  run_script "AI_platform" "openclaw_install.sh" "sh" ;;
            3)  run_script "Linux_auto_scripts/Linux_software_install" "install-chrome.sh" "sh" ;;
            4)  run_script "Linux_auto_scripts/Linux_software_install" "install-edge.sh" "sh" ;;
            5)  run_script "Linux_auto_scripts/Linux_software_install" "rustdesk_install.sh" "sh" ;;
            6)  run_script "Linux_auto_scripts/Linux_software_install" "x-ui_install.sh" "sh" ;;
            7)  run_script "Linux_auto_scripts/Linux_software_install" "Kangle_install.sh" "sh" ;;
            8)  run_script "Linux_auto_scripts/Linux_software_install" "yunsuo_install.sh" "sh" ;;
            9)  run_script "Linux_auto_scripts/Linux_software_install" "synology_abb_install.sh" "sh" ;;
            10) run_script "Linux_auto_scripts/Linux_software_install" "install-emqx-deb.sh" "sh" ;;
            11) run_script "Linux_auto_scripts" "mkfile_manager.sh" "sh" ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ---- 8. SSH 后台工作区 ----
menu_ssh_workspace() {
    while true; do
        local screen_installed=true
        if ! command -v screen &>/dev/null; then
            screen_installed=false
        fi

        draw_section_header "[8] SSH 后台工作区 (Screen 会话管理)"
        box_line "${CYAN}当前 Screen 会话列表:${NC}"

        if $screen_installed; then
            local sessions
            sessions=$(screen -ls 2>/dev/null | grep -E '^\s+[0-9]+\.' || true)
            if [ -z "$sessions" ]; then
                box_line "  ${YELLOW}(暂无运行中的会话)${NC}"
            else
                while IFS= read -r line; do
                    local sess_info
                    sess_info=$(echo "$line" | awk '{print $1, $NF}')
                    box_line "  ${GREEN}- ${sess_info}${NC}"
                done <<< "$sessions"
            fi
        else
            box_line "  ${RED}[X] screen 未安装${NC}"
        fi

        box_sep
        print_sub_menu_item "1" "创建新的 Screen 后台会话"
        print_sub_menu_item "2" "查看所有 Screen 会话"
        print_sub_menu_item "3" "接入 (Attach) 已有会话"
        print_sub_menu_item "4" "删除 (Kill) 指定会话"
        if ! $screen_installed; then
            print_sub_menu_item "i" "安装 screen 工具"
        fi
        draw_footer

        read -ep "请输入序号: " choice
        case "$choice" in
            1)
                if ! $screen_installed; then
                    echo -e "${RED}[X] screen 未安装，请先选择 [i] 安装 screen${NC}"
                    press_any_key
                    continue
                fi
                echo ""
                echo -ne "${GREEN}请输入新会话名称: ${NC}"
                read -r sess_name
                if [ -z "$sess_name" ]; then
                    echo -e "${RED}[X] 会话名称不能为空${NC}"
                    press_any_key
                    continue
                fi
                clear
                echo -e "${GREEN}[OK] 正在创建 Screen 会话: $sess_name${NC}"
                echo -e "${YELLOW}提示: 使用 Ctrl+A 再按 D 可分离会话（后台运行）${NC}"
                echo ""
                sleep 1
                screen -S "$sess_name"
                ;;
            2)
                if ! $screen_installed; then
                    echo -e "${RED}[X] screen 未安装，请先选择 [i] 安装 screen${NC}"
                    press_any_key
                    continue
                fi
                clear
                echo -e "${CYAN}========== Screen 会话列表 ==========${NC}"
                screen -ls 2>/dev/null || echo -e "${YELLOW}暂无运行中的 Screen 会话${NC}"
                echo ""
                press_any_key
                ;;
            3)
                if ! $screen_installed; then
                    echo -e "${RED}[X] screen 未安装，请先选择 [i] 安装 screen${NC}"
                    press_any_key
                    continue
                fi
                echo ""
                local sess_list
                sess_list=$(screen -ls 2>/dev/null | grep -E '^\s+[0-9]+\.' | awk '{print $1}' || true)
                if [ -z "$sess_list" ]; then
                    echo -e "${YELLOW}暂无运行中的 Screen 会话${NC}"
                    press_any_key
                    continue
                fi
                echo -e "${GREEN}可用的会话:${NC}"
                local i=1
                local sess_array=()
                while IFS= read -r s; do
                    echo -e "  ${GREEN}$i${NC}. $s"
                    sess_array+=("$s")
                    ((i++))
                done <<< "$sess_list"
                echo ""
                echo -ne "${GREEN}请选择要接入的会话编号 (或直接输入会话ID): ${NC}"
                read -r sess_choice
                local target
                if [[ "$sess_choice" =~ ^[0-9]+$ ]] && [ "$sess_choice" -ge 1 ] 2>/dev/null && [ "$sess_choice" -le "${#sess_array[@]}" ]; then
                    target="${sess_array[$((sess_choice - 1))]}"
                else
                    target="$sess_choice"
                fi
                clear
                echo -e "${GREEN}[OK] 正在接入会话: $target${NC}"
                echo -e "${YELLOW}提示: 使用 Ctrl+A 再按 D 可分离会话${NC}"
                echo ""
                sleep 0.5
                screen -r "$target" 2>&1 || {
                    echo ""
                    echo -e "${RED}[X] 接入失败，请检查会话ID是否正确${NC}"
                    press_any_key
                }
                ;;
            4)
                if ! $screen_installed; then
                    echo -e "${RED}[X] screen 未安装，请先选择 [i] 安装 screen${NC}"
                    press_any_key
                    continue
                fi
                echo ""
                local sess_list
                sess_list=$(screen -ls 2>/dev/null | grep -E '^\s+[0-9]+\.' | awk '{print $1}' || true)
                if [ -z "$sess_list" ]; then
                    echo -e "${YELLOW}暂无运行中的 Screen 会话${NC}"
                    press_any_key
                    continue
                fi
                echo -e "${GREEN}可用的会话:${NC}"
                local i=1
                local sess_array=()
                while IFS= read -r s; do
                    echo -e "  ${GREEN}$i${NC}. $s"
                    sess_array+=("$s")
                    ((i++))
                done <<< "$sess_list"
                echo ""
                echo -ne "${RED}请选择要删除的会话编号 (或直接输入会话ID): ${NC}"
                read -r sess_choice
                local target
                if [[ "$sess_choice" =~ ^[0-9]+$ ]] && [ "$sess_choice" -ge 1 ] 2>/dev/null && [ "$sess_choice" -le "${#sess_array[@]}" ]; then
                    target="${sess_array[$((sess_choice - 1))]}"
                else
                    target="$sess_choice"
                fi
                echo -ne "${RED}确认删除会话 $target ? (y/N): ${NC}"
                read -r confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    screen -S "$target" -X quit 2>/dev/null
                    echo -e "${GREEN}[OK] 会话已删除${NC}"
                else
                    echo -e "${YELLOW}已取消删除${NC}"
                fi
                press_any_key
                ;;
            [iI])
                echo ""
                echo -e "${GREEN}正在安装 screen...${NC}"
                sudo apt-get update -qq && sudo apt-get install -y screen
                if command -v screen &>/dev/null; then
                    echo -e "${GREEN}[OK] screen 安装成功！${NC}"
                else
                    echo -e "${RED}[X] screen 安装失败，请手动安装${NC}"
                fi
                press_any_key
                ;;
            [bB]|0) return ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════
#  主菜单
# ═══════════════════════════════════════════════════════════════

main_menu() {
    while true; do
        draw_main_header
        print_menu_item "1" "系统信息查询"       "查看系统综合信息、快速基本信息"
        print_menu_item "2" "系统管理工具"       "一键初始化、磁盘挂载、虚拟内存、网络、环境部署等工具"
        print_menu_item "3" "基础工具管理"       "Node.js / Python / Jupyter / Nginx / 内网穿透等工具"
        print_menu_item "4" "Docker 管理专栏"    "Docker 安装 / Compose / Dockerfile / GPU Toolkit 等工具"
        print_menu_item "5" "ROS 管理专栏"       "ROS 安装、依赖、cJSON/OpenCV 编译、VCAN 管理等工具"
        print_menu_item "6" "服务器专栏"         "服务器巡检、MySQL、系统初始化、Hexo 部署等工具"
        print_menu_item "7" "应用市场"           "浏览器、远程桌面、AI 工具、服务器面板等应用软件安装"
        print_menu_item "8" "SSH 后台工作区"     "Screen 会话管理，后台运行不中断"
        box_sep
        box_line "  ${RED}q${NC}   | ${RED}退出程序${NC}"
        box_bottom
        echo ""

        read -ep "请输入序号进入: " choice
        case "$choice" in
            1) menu_sys_info ;;
            2) menu_sys_mgmt ;;
            3) menu_basic_tools ;;
            4) menu_docker ;;
            5) menu_ros ;;
            6) menu_server ;;
            7) menu_app_store ;;
            8) menu_ssh_workspace ;;
            [qQ]) safe_exit ;;
            *) ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════
#  退出
# ═══════════════════════════════════════════════════════════════

safe_exit() {
    clear
    box_top
    box_empty
    box_center "${BOLD}感谢使用 Auto Scripts Tools，再见！${NC}"
    box_empty
    box_bottom
    echo ""
    exit 0
}

main_menu
