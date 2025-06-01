#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-06-02 00:09:34
# @version     : bash
# @Update time :
# @Description : 用于简化crontab任务的配置, 支持添加、查看和删除定时任务


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Crontab任务管理助手 ===${NC}"
echo "1. 添加新定时任务"
echo "2. 查看现有定时任务"
echo "3. 删除定时任务"
echo "4. 退出"
echo "--------------------------------"

# 检查是否已安装crontab
if ! command -v crontab &> /dev/null; then
    echo -e "${RED}错误：未找到crontab，请先安装cron服务${NC}"
    exit 1
fi

# 函数：解释cron时间表达式
explain_cron() {
    local minute=$1 hour=$2 day=$3 month=$4 weekday=$5
    local explanation=""

    # 解释月份
    if [[ $month != "*" ]]; then
        explanation+="在${month}月"
    fi

    # 解释日期
    if [[ $day == "*" ]]; then
        if [[ $month != "*" ]]; then
            explanation+="的"
        fi
        explanation+="每天"
    elif [[ $day =~ ^[0-9,-]+$ ]]; then
        if [[ $month != "*" ]]; then
            explanation+="的"
        fi
        explanation+="${day}号"
    fi

    # 解释星期
    if [[ $weekday != "*" ]]; then
        explanation+="的星期${weekday//0/日}"
    fi

    # 解释小时
    if [[ $hour == "*" ]]; then
        explanation+="的每小时"
    elif [[ $hour == */?* ]]; then
        interval=${hour#*/}
        explanation+="的每${interval}小时"
    elif [[ $hour =~ ^[0-9,-]+$ ]]; then
        explanation+="的${hour}点"
    fi

    # 解释分钟
    if [[ $minute == "*" ]]; then
        explanation+="的每分钟"
    elif [[ $minute == */?* ]]; then
        interval=${minute#*/}
        explanation+="的每${interval}分钟"
    elif [[ $minute =~ ^[0-9,-]+$ ]]; then
        explanation+="的第${minute}分钟"
    fi

    echo -e "${BLUE}任务说明：${explanation}执行${NC}"
}

# 函数：验证数字范围
validate_number() {
    local num=$1
    local min=$2
    local max=$3
    local field=$4

    if [[ $num =~ ^[0-9*/,-]+([ ]*[0-9*/,-]+)*$ ]]; then
        if [[ $num != "*" ]]; then
            IFS=',' read -ra VALUES <<< "$num"
            for val in "${VALUES[@]}"; do
                # 处理范围值
                if [[ $val =~ - ]]; then
                    IFS='-' read -ra RANGE <<< "$val"
                    if [[ ${#RANGE[@]} -ne 2 ]]; then
                        echo -e "${RED}错误：$field 范围格式不正确${NC}"
                        return 1
                    fi
                    for r in "${RANGE[@]}"; do
                        if (( r < min || r > max )); then
                            echo -e "${RED}错误：$field 必须在 $min 和 $max 之间${NC}"
                            return 1
                        fi
                    done
                elif [[ $val =~ ^[0-9]+$ ]] && (( val < min || val > max )); then
                    echo -e "${RED}错误：$field 必须在 $min 和 $max 之间${NC}"
                    return 1
                fi
            done
        fi
        return 0
    else
        echo -e "${RED}错误：$field 格式不合法，仅允许数字、*, /、, 和 - 符号${NC}"
        return 1
    fi
}

# 函数：获取用户输入并验证
get_cron_field() {
    local prompt=$1
    local default=$2
    local min=$3
    local max=$4
    local field=$5
    
    while true; do
        read -ep "$prompt (默认: $default): " input
        input=${input:-$default}
        
        if validate_number "$input" "$min" "$max" "$field"; then
            echo "$input"
            break
        fi
    done
}

# 函数：添加定时任务
add_cron_job() {
    echo -e "\n${GREEN}=== 添加新定时任务 ===${NC}"
    
    minute=$(get_cron_field "请输入分钟 (0-59)" "*" 0 59 "分钟")
    hour=$(get_cron_field "请输入小时 (0-23)" "*" 0 23 "小时")
    day=$(get_cron_field "请输入日期 (1-31)" "*" 1 31 "日期")
    month=$(get_cron_field "请输入月份 (1-12)" "*" 1 12 "月份")
    weekday=$(get_cron_field "请输入星期 (0-6, 0=星期日)" "*" 0 6 "星期")

    # 获取要执行的命令
    while true; do
        read -ep "请输入要执行的命令: " command
        if [ -z "$command" ]; then
            echo -e "${RED}错误：命令不能为空${NC}"
        else
            break
        fi
    done

    # 显示配置摘要
    echo -e "\n${YELLOW}=== 配置摘要 ===${NC}"
    echo "时间表达式: $minute $hour $day $month $weekday"
    echo "执行的命令: $command"
    echo -e "完整的crontab条目: ${GREEN}$minute $hour $day $month $weekday $command${NC}"

    # 解释任务执行时间
    explain_cron "$minute" "$hour" "$day" "$month" "$weekday"

    # 确认是否添加
    while true; do
        read -ep "是否要添加此定时任务? [y/n]: " yn
        case $yn in
            [Yy]* )
                # 添加到当前用户的crontab
                (crontab -l 2>/dev/null; echo "$minute $hour $day $month $weekday $command") | crontab -
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}定时任务已成功添加!${NC}"
                else
                    echo -e "${RED}错误：添加定时任务失败${NC}"
                fi
                return
                ;;
            [Nn]* )
                echo "已取消添加定时任务"
                return
                ;;
            * )
                echo "请输入 y 或 n"
                ;;
        esac
    done
}

# 函数：查看定时任务
view_cron_jobs() {
    echo -e "\n${GREEN}=== 当前用户的定时任务 ===${NC}"
    local jobs=$(crontab -l 2>/dev/null)
    
    if [ -z "$jobs" ]; then
        echo -e "${YELLOW}当前没有设置任何定时任务${NC}"
    else
        local count=1
        while IFS= read -r line; do
            if [[ "$line" =~ ^# ]]; then
                continue
            fi
            if [[ -n "$line" ]]; then
                echo -e "${BLUE}[$count] ${line}${NC}"
                ((count++))
            fi
        done <<< "$jobs"
    fi
}

# 函数：删除定时任务
delete_cron_job() {
    view_cron_jobs
    
    local jobs=$(crontab -l 2>/dev/null | grep -v '^#')
    if [ -z "$jobs" ]; then
        echo -e "${YELLOW}没有可删除的定时任务${NC}"
        return
    fi
    
    while true; do
        read -ep "请输入要删除的任务编号(输入q退出): " num
        if [[ "$num" == "q" ]]; then
            return
        fi
        
        if [[ "$num" =~ ^[0-9]+$ ]]; then
            local total=$(echo "$jobs" | wc -l)
            if (( num >= 1 && num <= total )); then
                # 删除指定行
                crontab -l | grep -v '^#' | sed "${num}d" | crontab -
                echo -e "${GREEN}定时任务已成功删除!${NC}"
                return
            else
                echo -e "${RED}错误：无效的任务编号${NC}"
            fi
        else
            echo -e "${RED}错误：请输入有效的数字${NC}"
        fi
    done
}


# 主菜单
read -ep "请选择操作[1-4]: " choice
case $choice in
    1) add_cron_job ;;
    2) view_cron_jobs ;;
    3) delete_cron_job ;;
    4) exit 0 ;;
    *) echo -e "${RED}错误：无效的选择${NC}" ;;
esac

