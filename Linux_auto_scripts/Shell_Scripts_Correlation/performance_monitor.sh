#!/bin/bash
# @Author: luckykoi
# @Date:   2026-11-04 21:56:14
# @Last Modified time: 2026-11-04 21:56:14
# 系统性能监控脚本（类似任务管理器），在终端实时查看 CPU/内存/负载/网络/磁盘/进程

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# 全局变量
REFRESH_INTERVAL=2
SORT_BY="cpu"  # cpu, mem, pid, time
SHOW_PROCESSES=5
HISTORY_LENGTH=60

# 进程排序字段映射
declare -A SORT_FIELDS=(
    ["cpu"]="%cpu"
    ["mem"]="%mem"
    ["pid"]="pid"
    ["time"]="time"
)

# 彻底清屏（启动/退出/帮助时使用）
full_clear() {
    printf '\033[2J\033[H'
}

# 隐藏光标
hide_cursor() {
    printf '\033[?25l'
}

# 显示光标
show_cursor() {
    printf '\033[?25h'
}

# 获取终端尺寸
get_terminal_size() {
    TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
    TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
}

# 绘制水平线
draw_line() {
    local char="${1:-─}"
    local color="${2:-$NC}"
    printf "${color}%*s${NC}\n" "$TERM_WIDTH" | tr ' ' "$char"
}

# 格式化字节为人类可读格式
format_bytes() {
    local bytes=$1
    if [[ $bytes -ge 1099511627776 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1099511627776}") TB"
    elif [[ $bytes -ge 1073741824 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    else
        echo "${bytes} B"
    fi
}

# 获取CPU使用率
get_cpu_usage() {
    local cpu_line=$(head -n1 /proc/stat)
    local cpu_times=($cpu_line)
    local user=${cpu_times[1]}
    local nice=${cpu_times[2]}
    local system=${cpu_times[3]}
    local idle=${cpu_times[4]}
    local iowait=${cpu_times[5]}
    local irq=${cpu_times[6]}
    local softirq=${cpu_times[7]}
    local steal=${cpu_times[8]}
    local guest=${cpu_times[9]}
    local guest_nice=${cpu_times[10]}

    local total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    local idle_total=$((idle + iowait))

    echo "$total $idle_total"
}

# 计算CPU使用率百分比
calc_cpu_percent() {
    local prev_total=$1
    local prev_idle=$2
    local curr_total=$3
    local curr_idle=$4

    local total_diff=$((curr_total - prev_total))
    local idle_diff=$((curr_idle - prev_idle))

    if [[ $total_diff -eq 0 ]]; then
        echo "0.0"
    else
        awk "BEGIN {printf \"%.1f\", (($total_diff - $idle_diff) * 100) / $total_diff}"
    fi
}

# 获取内存信息
get_memory_info() {
    local mem_info=$(cat /proc/meminfo)
    local mem_total=$(echo "$mem_info" | grep "MemTotal:" | awk '{print $2}')
    local mem_free=$(echo "$mem_info" | grep "MemFree:" | awk '{print $2}')
    local mem_available=$(echo "$mem_info" | grep "MemAvailable:" | awk '{print $2}')
    local buffers=$(echo "$mem_info" | grep "Buffers:" | awk '{print $2}')
    local cached=$(echo "$mem_info" | grep "^Cached:" | awk '{print $2}')
    local swap_total=$(echo "$mem_info" | grep "SwapTotal:" | awk '{print $2}')
    local swap_free=$(echo "$mem_info" | grep "SwapFree:" | awk '{print $2}')

    # 转换为字节
    mem_total=$((mem_total * 1024))
    mem_free=$((mem_free * 1024))
    mem_available=$((mem_available * 1024))
    buffers=$((buffers * 1024))
    cached=$((cached * 1024))
    swap_total=$((swap_total * 1024))
    swap_free=$((swap_free * 1024))

    local mem_used=$((mem_total - mem_available))
    local mem_used_percent=$(awk "BEGIN {printf \"%.1f\", ($mem_used * 100) / $mem_total}")
    local swap_used=$((swap_total - swap_free))
    local swap_used_percent=0
    if [[ $swap_total -gt 0 ]]; then
        swap_used_percent=$(awk "BEGIN {printf \"%.1f\", ($swap_used * 100) / $swap_total}")
    fi

    echo "$mem_total $mem_used $mem_free $mem_available $buffers $cached $mem_used_percent $swap_total $swap_used $swap_free $swap_used_percent"
}

# 获取磁盘信息
get_disk_info() {
    df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | tail -n +2
}

# 获取网络信息
get_network_info() {
    local net_dev=$(cat /proc/net/dev | tail -n +3)
    local rx_bytes=0
    local tx_bytes=0
    local rx_packets=0
    local tx_packets=0

    while IFS= read -r line; do
        local fields=($line)
        local iface=${fields[0]%:}
        # 跳过回环接口
        if [[ $iface != "lo" ]]; then
            rx_bytes=$((rx_bytes + ${fields[1]}))
            tx_bytes=$((tx_bytes + ${fields[9]}))
            rx_packets=$((rx_packets + ${fields[2]}))
            tx_packets=$((tx_packets + ${fields[10]}))
        fi
    done <<< "$net_dev"

    echo "$rx_bytes $tx_bytes $rx_packets $tx_packets"
}

# 计算网络速度
calc_network_speed() {
    local prev_rx=$1
    local prev_tx=$2
    local curr_rx=$3
    local curr_tx=$4
    local interval=$5

    local rx_speed=$(awk "BEGIN {printf \"%.0f\", ($curr_rx - $prev_rx) / $interval}")
    local tx_speed=$(awk "BEGIN {printf \"%.0f\", ($curr_tx - $prev_tx) / $interval}")

    echo "$rx_speed $tx_speed"
}

# 获取系统负载
get_load_avg() {
    cat /proc/loadavg | awk '{print $1, $2, $3}'
}

# 获取运行时间
get_uptime() {
    local uptime_seconds=$(cat /proc/uptime | awk '{print int($1)}')
    local days=$((uptime_seconds / 86400))
    local hours=$(( (uptime_seconds % 86400) / 3600 ))
    local minutes=$(( (uptime_seconds % 3600) / 60 ))
    local seconds=$((uptime_seconds % 60))

    if [[ $days -gt 0 ]]; then
        echo "${days}天 ${hours}小时 ${minutes}分"
    elif [[ $hours -gt 0 ]]; then
        echo "${hours}小时 ${minutes}分 ${seconds}秒"
    elif [[ $minutes -gt 0 ]]; then
        echo "${minutes}分 ${seconds}秒"
    else
        echo "${seconds}秒"
    fi
}

# 获取进程列表
get_process_list() {
    local sort_field="${SORT_FIELDS[$SORT_BY]}"
    ps -eo pid,ppid,user,%cpu,%mem,cmd,time --sort=-"$sort_field" | head -n $((SHOW_PROCESSES + 1))
}

# 绘制进度条
draw_progress_bar() {
    local percent=$1
    local width=$2
    local color=$3
    # 使用 awk 处理浮点数计算
    local filled=$(awk "BEGIN {printf \"%d\", $percent * $width / 100}")
    local empty=$((width - filled))

    printf "${color}"
    printf "%${filled}s" | tr ' ' '█'
    printf "${DIM}"
    printf "%${empty}s" | tr ' ' '░'
    printf "${NC}"
}

# 显示帮助信息
show_help() {
    full_clear
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║           性能监控器 - 帮助信息                              ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${BOLD}键盘快捷键:${NC}"
    echo -e "  ${GREEN}q${NC} / ${GREEN}Q${NC} / ${GREEN}Esc${NC}     - 退出程序"
    echo -e "  ${GREEN}h${NC} / ${GREEN}H${NC} / ${GREEN}?${NC}       - 显示/隐藏帮助"
    echo -e "  ${GREEN}r${NC} / ${GREEN}R${NC}         - 强制刷新"
    echo -e "  ${GREEN}1${NC}             - 按 CPU 使用率排序进程"
    echo -e "  ${GREEN}2${NC}             - 按内存使用率排序进程"
    echo -e "  ${GREEN}3${NC}             - 按 PID 排序进程"
    echo -e "  ${GREEN}4${NC}             - 按运行时间排序进程"
    echo -e "  ${GREEN}+${NC} / ${GREEN}=${NC}         - 增加显示进程数量"
    echo -e "  ${GREEN}-${NC} / ${GREEN}_${NC}         - 减少显示进程数量"
    echo -e "  ${GREEN}Space${NC}       - 暂停/继续刷新"
    echo -e "  ${GREEN}Up/Down${NC}     - 调整刷新间隔 (0.5-10秒)"
    echo -e "  ${GREEN}c${NC}             - 切换颜色模式"
    echo
    echo -e "${BOLD}显示内容说明:${NC}"
    echo -e "  ${CYAN}CPU${NC}      - 总体 CPU 使用率，平均负载"
    echo -e "  ${BLUE}内存${NC}     - 物理内存使用情况 (已用/可用/总计)"
    echo -e "  ${YELLOW}Swap${NC}     - 交换分区使用情况"
    echo -e "  ${MAGENTA}负载${NC}     - 1/5/15 分钟平均负载"
    echo -e "  ${GREEN}网络${NC}     - 接收/发送速度"
    echo -e "  ${WHITE}磁盘${NC}     - 主要挂载点使用情况"
    echo -e "  进程列表   - TOP 进程 (默认按 CPU 排序)"
    echo
    echo -e "${BOLD}颜色含义:${NC}"
    echo -e "  ${GREEN}绿色${NC} - 正常/低负载"
    echo -e "  ${YELLOW}黄色${NC} - 中等负载"
    echo -e "  ${RED}红色${NC} - 高负载/警告"
    echo
    echo -e "按任意键返回监控界面..."
    read -n1 -s
}

# 绘制头部信息（单行紧凑）
draw_header() {
    local hostname=$(hostname)
    local uptime=$(get_uptime)
    local datetime=$(date '+%Y-%m-%d %H:%M:%S')

    printf "${BOLD}${CYAN}━━━ 性能监控 ━━━${NC} ${WHITE}%s${NC} ${DIM}|${NC} ${WHITE}%s${NC} ${DIM}|${NC} 运行 ${YELLOW}%s${NC}\n" \
        "$hostname" "$datetime" "$uptime"
}

# 绘制CPU总体 + 系统负载（一行）
draw_cpu_section() {
    local cpu_percent=$1
    local load1=$2
    local load5=$3
    local load15=$4
    local cpu_cores=$(nproc)

    local cpu_color=$GREEN
    if (( $(echo "$cpu_percent > 80" | bc -l 2>/dev/null || echo 0) )); then
        cpu_color=$RED
    elif (( $(echo "$cpu_percent > 50" | bc -l 2>/dev/null || echo 0) )); then
        cpu_color=$YELLOW
    fi

    local load_color=$GREEN
    if (( $(echo "$load1 > $cpu_cores * 2" | bc -l 2>/dev/null || echo 0) )); then
        load_color=$RED
    elif (( $(echo "$load1 > $cpu_cores" | bc -l 2>/dev/null || echo 0) )); then
        load_color=$YELLOW
    fi

    printf "${BOLD}CPU ${NC} "
    draw_progress_bar "$cpu_percent" 20 "$cpu_color"
    printf " ${cpu_color}%5s%%${NC}" "$cpu_percent"
    printf "   ${BOLD}负载${NC} ${load_color}%.2f %.2f %.2f${NC} (${CYAN}%d核${NC})\n" \
        "$load1" "$load5" "$load15" "$cpu_cores"
}

# 绘制内存 + Swap（两行紧凑）
draw_memory_section() {
    local mem_total=$1
    local mem_used=$2
    local mem_free=$3
    local mem_available=$4
    local buffers=$5
    local cached=$6
    local mem_used_percent=$7
    local swap_total=$8
    local swap_used=$9
    local swap_free=${10}
    local swap_used_percent=${11}

    local mem_color=$GREEN
    if (( $(echo "$mem_used_percent > 85" | bc -l 2>/dev/null || echo 0) )); then
        mem_color=$RED
    elif (( $(echo "$mem_used_percent > 70" | bc -l 2>/dev/null || echo 0) )); then
        mem_color=$YELLOW
    fi

    printf "${BOLD}内存${NC} "
    draw_progress_bar "$mem_used_percent" 20 "$mem_color"
    printf " ${mem_color}%5s%%${NC}  ${YELLOW}%s${NC}/${WHITE}%s${NC} (可用 ${GREEN}%s${NC})\n" \
        "$mem_used_percent" "$(format_bytes $mem_used)" "$(format_bytes $mem_total)" "$(format_bytes $mem_available)"

    if [[ $swap_total -gt 0 ]]; then
        printf "${BOLD}Swap${NC} "
        draw_progress_bar "$swap_used_percent" 20 "$YELLOW"
        printf " ${YELLOW}%5s%%${NC}  %s/%s\n" \
            "$swap_used_percent" "$(format_bytes $swap_used)" "$(format_bytes $swap_total)"
    else
        printf "${BOLD}Swap${NC} ${DIM}未配置${NC}\n"
    fi
}

# 绘制网络流量（一行紧凑）
draw_network_section() {
    local rx_speed=$1
    local tx_speed=$2
    local rx_total=$3
    local tx_total=$4

    printf "${BOLD}网络${NC} ${CYAN}↓ %s/s${NC}  ${YELLOW}↑ %s/s${NC}   累计 ${DIM}↓${NC}%s ${DIM}↑${NC}%s\n" \
        "$(format_bytes $rx_speed)" "$(format_bytes $tx_speed)" \
        "$(format_bytes $rx_total)" "$(format_bytes $tx_total)"
}

# 绘制磁盘使用（每个挂载点紧凑一行）
draw_disk_section() {
    local disk_info=$1

    local first=true
    while IFS= read -r line; do
        [[ -z $line ]] && continue
        local fields=($line)
        local size=${fields[1]}
        local used=${fields[2]}
        local pcent=${fields[4]%\%}
        local mount=${fields[5]}

        local color=$GREEN
        if [[ $pcent -gt 90 ]]; then
            color=$RED
        elif [[ $pcent -gt 70 ]]; then
            color=$YELLOW
        fi

        if $first; then
            printf "${BOLD}磁盘${NC} "
            first=false
        else
            printf "     "
        fi
        printf "%s ${DIM}%s/%s${NC} ${color}%s%%${NC}\n" "$mount" "$used" "$size" "$pcent"
    done <<< "$disk_info"
}

# 绘制进程列表（紧凑表格）
draw_process_section() {
    local process_list=$1

    draw_line "─" "$DIM"
    printf "${BOLD}${CYAN}%-7s %6s %6s %-10s %s${NC} ${DIM}(按%s排序)${NC}\n" \
        "PID" "CPU%" "MEM%" "用户" "命令" "${SORT_BY^^}"

    local line_num=0
    while IFS= read -r line; do
        [[ $line_num -eq 0 ]] && { line_num=1; continue; }  # 跳过标题行
        [[ $line_num -gt $SHOW_PROCESSES ]] && break

        local fields=($line)
        local pid=${fields[0]}
        local ppid=${fields[1]}
        local user=${fields[2]}
        local cpu=${fields[3]}
        local mem=${fields[4]}
        # ps 列顺序为 pid,ppid,user,%cpu,%mem,cmd,time —— time 在最后一列
        local time=${fields[${#fields[@]}-1]}
        local cmd="${fields[*]:5:${#fields[@]}-6}"

        # 截断过长的命令
        local max_cmd_len=$((TERM_WIDTH - 36))
        [[ ${#cmd} -gt $max_cmd_len ]] && cmd="${cmd:0:$((max_cmd_len-3))}..."

        # 高亮高资源占用进程
        local color=$NC
        if (( $(echo "$cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
            color=$RED
        elif (( $(echo "$cpu > 20" | bc -l 2>/dev/null || echo 0) )); then
            color=$YELLOW
        elif (( $(echo "$mem > 20" | bc -l 2>/dev/null || echo 0) )); then
            color=$MAGENTA
        fi

        printf "${color}%-7s %6s %6s %-10s %s${NC}\n" \
            "$pid" "$cpu" "$mem" "$user" "$cmd"
        line_num=$((line_num + 1))
    done <<< "$process_list"

    # 填充空行
    for ((i=line_num; i<=SHOW_PROCESSES; i++)); do
        printf "\n"
    done
}

# 绘制底部状态栏（单行紧凑）
draw_footer() {
    local sort_desc=""
    case $SORT_BY in
        cpu) sort_desc="CPU" ;;
        mem) sort_desc="内存" ;;
        pid) sort_desc="PID" ;;
        time) sort_desc="时间" ;;
    esac

    draw_line "─" "$DIM"
    printf "${DIM}刷新${NC}${YELLOW}%.1fs${NC} ${DIM}|${NC} 排序${NC}${CYAN}%s${NC} ${DIM}|${NC} 进程${NC}${GREEN}%d${NC} ${DIM}|${NC} ${GREEN}h${NC}帮助 ${GREEN}q${NC}退出 ${GREEN}1-4${NC}排序 ${GREEN}+/-${NC}进程 ${GREEN}↑↓${NC}间隔\n" \
        "$REFRESH_INTERVAL" "$sort_desc" "$SHOW_PROCESSES"
}

# 处理键盘输入
handle_input() {
    local key=$1
    case $key in
        q|Q|$'\e')
            return 1  # 退出
            ;;
        h|H|'?')
            show_help
            ;;
        r|R)
            # 强制刷新，什么都不做，主循环会重绘
            ;;
        1)
            SORT_BY="cpu"
            ;;
        2)
            SORT_BY="mem"
            ;;
        3)
            SORT_BY="pid"
            ;;
        4)
            SORT_BY="time"
            ;;
        '+'|'=')
            ((SHOW_PROCESSES++))
            [[ $SHOW_PROCESSES -gt 50 ]] && SHOW_PROCESSES=50
            ;;
        '-'|'_')
            ((SHOW_PROCESSES--))
            [[ $SHOW_PROCESSES -lt 5 ]] && SHOW_PROCESSES=5
            ;;
        $'\e[A')  # Up arrow
            REFRESH_INTERVAL=$(awk "BEGIN {printf \"%.1f\", $REFRESH_INTERVAL + 0.5}")
            [[ $(echo "$REFRESH_INTERVAL > 10" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && REFRESH_INTERVAL=10
            ;;
        $'\e[B')  # Down arrow
            REFRESH_INTERVAL=$(awk "BEGIN {printf \"%.1f\", $REFRESH_INTERVAL - 0.5}")
            [[ $(echo "$REFRESH_INTERVAL < 0.5" | bc -l 2>/dev/null || echo 0) -eq 1 ]] && REFRESH_INTERVAL=0.5
            ;;
        ' ')
            # 暂停/继续 - 这里简单处理为等待按键
            read -n1 -s -p "已暂停，按任意键继续..."
            ;;
        c|C)
            # 切换颜色模式 - 简单切换
            if [[ -z $COLOR_MODE ]]; then
                COLOR_MODE=1
            else
                COLOR_MODE=0
            fi
            ;;
    esac
    return 0
}

# 主监控循环
main_loop() {
    hide_cursor
    # 启动时彻底清屏，避免显示上一次终端内容
    full_clear
    trap 'show_cursor; full_clear; exit 0' INT TERM EXIT

    # 初始化数据
    local prev_cpu=($(get_cpu_usage))
    local prev_net=($(get_network_info))
    local prev_time=$(date +%s.%N)

    # 检查 bc 是否可用
    if ! command -v bc &> /dev/null; then
        echo "警告: 未安装 bc 命令，部分计算功能可能受限"
        sleep 2
    fi

    # 第一次循环不绘制，只更新前值以建立基准 - 增加等待时间
    sleep 1
    prev_cpu=($(get_cpu_usage))
    prev_net=($(get_network_info))
    prev_time=$(date +%s.%N)

    # 上一帧的各行内容，用于差异刷新
    local -a prev_lines=()

    while true; do
        get_terminal_size

        # 获取当前数据
        local curr_cpu=($(get_cpu_usage))
        local cpu_percent=$(calc_cpu_percent "${prev_cpu[0]}" "${prev_cpu[1]}" "${curr_cpu[0]}" "${curr_cpu[1]}")

        local mem_info=($(get_memory_info))

        local load_avg=($(get_load_avg))

        local curr_net=($(get_network_info))
        local curr_time=$(date +%s.%N)
        local interval=$(awk "BEGIN {printf \"%.3f\", $curr_time - $prev_time}")
        [[ $(echo "$interval < 0.001" | bc -l 2>/dev/null || echo 1) -eq 1 ]] && interval=1
        local net_speed=($(calc_network_speed "${prev_net[0]}" "${prev_net[1]}" "${curr_net[0]}" "${curr_net[1]}" "$interval"))

        local disk_info=$(get_disk_info)

        local process_list=$(get_process_list)

        # 先在内存中生成整帧内容
        local frame
        frame=$(
            draw_header
            draw_cpu_section "$cpu_percent" "${load_avg[0]}" "${load_avg[1]}" "${load_avg[2]}"
            draw_memory_section "${mem_info[@]}"
            draw_network_section "${net_speed[0]}" "${net_speed[1]}" "${curr_net[0]}" "${curr_net[1]}"
            draw_disk_section "$disk_info"
            draw_process_section "$process_list"
            draw_footer
        )

        local -a new_lines
        mapfile -t new_lines <<< "$frame"

        # 逐行对比，只重绘变化的行，避免整屏上下刷新
        local row max_rows=${#new_lines[@]}
        [[ $max_rows -gt $TERM_HEIGHT ]] && max_rows=$TERM_HEIGHT
        local prev_rows=${#prev_lines[@]}
        [[ $prev_rows -gt $TERM_HEIGHT ]] && prev_rows=$TERM_HEIGHT
        for ((row = 0; row < max_rows; row++)); do
            if [[ "${new_lines[row]}" != "${prev_lines[row]}" ]]; then
                printf '\033[%d;1H%s\033[0m\033[K' "$((row + 1))" "${new_lines[row]}"
            fi
        done
        # 清除上一帧多出来的行（限制在屏幕范围内，避免滚动）
        for ((row = max_rows; row < prev_rows; row++)); do
            printf '\033[%d;1H\033[K' "$((row + 1))"
        done
        prev_lines=("${new_lines[@]}")

        # 更新前值
        prev_cpu=("${curr_cpu[@]}")
        prev_net=("${curr_net[@]}")
        prev_time=$curr_time

        # 等待输入或超时
        if read -t "$REFRESH_INTERVAL" -n1 key 2>/dev/null; then
            # 读取可能的转义序列
            if [[ $key == $'\e' ]]; then
                read -t 0.01 -n2 more_key 2>/dev/null
                key="$key$more_key"
            fi
            if ! handle_input "$key"; then
                break
            fi
        fi
    done

    # 正常退出：先取消 trap，避免其再次清屏冲掉提示信息
    trap - INT TERM EXIT
    show_cursor
    full_clear
    echo -e "${GREEN}监控已停止${NC}"
}

# 显示版本信息
show_version() {
    echo "性能监控器 v1.0"
    echo "作者: luckykoi"
    echo "用于终端实时监控服务器性能"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                echo "用法: $0 [选项]"
                echo
                echo "选项:"
                echo "  -h, --help     显示帮助信息"
                echo "  -v, --version  显示版本信息"
                echo "  -i, --interval 设置刷新间隔 (秒，默认 2)"
                echo "  -n, --num      设置显示进程数量 (默认 5)"
                echo "  -s, --sort     设置排序方式: cpu, mem, pid, time (默认 cpu)"
                echo
                echo "运行时快捷键:"
                echo "  q/ESC    退出"
                echo "  h/?      显示帮助"
                echo "  1-4      切换排序 (CPU/内存/PID/时间)"
                echo "  +/-      调整显示进程数"
                echo "  ↑/↓      调整刷新间隔"
                echo "  Space    暂停/继续"
                echo "  r        强制刷新"
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -i|--interval)
                REFRESH_INTERVAL="$2"
                shift 2
                ;;
            -n|--num)
                SHOW_PROCESSES="$2"
                shift 2
                ;;
            -s|--sort)
                SORT_BY="$2"
                shift 2
                ;;
            *)
                echo "未知选项: $1"
                echo "使用 -h 查看帮助"
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    parse_args "$@"

    # 检查必要命令
    for cmd in ps df awk date; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "错误: 缺少必要命令: $cmd"
            exit 1
        fi
    done

    # 验证参数
    if ! [[ "$REFRESH_INTERVAL" =~ ^[0-9]+(\.[0-9]+)?$ ]] || (( $(echo "$REFRESH_INTERVAL < 0.1" | bc -l 2>/dev/null || echo 1) )); then
        REFRESH_INTERVAL=2
    fi

    if ! [[ "$SHOW_PROCESSES" =~ ^[0-9]+$ ]] || [[ $SHOW_PROCESSES -lt 1 ]]; then
        SHOW_PROCESSES=5
    fi

    if [[ ! -v SORT_FIELDS[$SORT_BY] ]]; then
        SORT_BY="cpu"
    fi

    # 启动主循环
    main_loop
}

# 运行主函数
main "$@"