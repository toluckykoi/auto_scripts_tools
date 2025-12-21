#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-12-20 23:48:26
# @version     : bash
# @Update time :
# @Description : Linux网络优先级设置


set -e  # 遇错退出

if ! command -v sudo &> /dev/null; then
    echo "本脚本需要 sudo 权限，请安装 sudo 或以 root 身份运行。"
    exit 1
fi

echo "网络优先级设置工具"
echo "===================="

echo -e "\n当前路由表: "
ip route show

echo -e "\n当前生效的默认路由及其优先级: "
echo "(系统会优先使用 metric 最小的默认路由)"
echo "------------------------------------------"

default_routes=$(ip route show default)

if [[ -z "$default_routes" ]]; then
    echo "⚠️ 未检测到任何默认路由(default route)"
else
    # 按行处理每个 default 路由
    echo "$default_routes" | while read -r line; do
        if [[ "$line" == default* ]]; then
            # 提取字段: 按空格分割
            fields=($line)
            # dev 索引: 找 "dev" 后一个字段
            for i in "${!fields[@]}"; do
                if [[ "${fields[i]}" == "dev" ]]; then
                    dev_index=$((i + 1))
                fi
                if [[ "${fields[i]}" == "metric" ]]; then
                    metric_index=$((i + 1))
                fi
            done
            dev="${fields[$dev_index]}"
            metric="${fields[$metric_index]}"
            printf "• 网卡: %-20s | metric: %-5s \n" "$dev" "$metric"
        fi
    done

    # 找出最优(metric 最小)的默认路由
    best_dev=$(echo "$default_routes" | awk '/^default/ {print $5, $NF}' | sort -k2,2n | head -n1 | awk '{print $1}')
    best_metric=$(echo "$default_routes" | awk '/^default/ {print $5, $NF}' | sort -k2,2n | head -n1 | awk '{print $2}')
    echo ""
    echo "当前生效的默认上网网卡: $best_dev (metric=$best_metric)"
fi

echo ""

# 获取 NetworkManager 连接列表
echo "检测到的网络连接: "
nmcli -t -f NAME,TYPE,DEVICE connection show

# 提取有线(ethernet)和无线(wifi)连接
wired_connections=($(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="802-3-ethernet" {print $1}'))
wifi_connections=($(nmcli -t -f NAME,TYPE connection show | awk -F: '$2=="802-11-wireless" {print $1}'))

echo -e "\n请选择要配置的网络类型: "
PS3="请输入选项编号: "
select mode in "配置有线网络" "配置无线网络"; do
    case $REPLY in
        1|2) break ;;
        *) echo "输入错误，请输入 1、2" ;;
    esac
done

wired=""
wifi=""

# 配置有线
if [ "$REPLY" == "1" ]; then
    if [ ${#wired_connections[@]} -eq 0 ]; then
        echo "⚠️ 未检测到有线网络连接！请确保已插入网线并通过 NetworkManager 配置。"
        exit 1
    fi
    
    echo -e "\n配置有线网络优先级为高."
    # 让用户选择有线连接
    echo -e "请选择要用于本地通信的有线连接: "
    select wired in "${wired_connections[@]}"; do
        if [[ -n "$wired" ]]; then
            echo "已选择有线连接: $wired"
            echo -e "\n正在配置路由优先级..."
            while true; do
                read -p "请输入有线连接 '$wired' 的路由优先级(metric推荐 100-800, 数值越小优先级越高): " wired_metric
                if [[ "$wired_metric" =~ ^[0-9]+$ ]] && [ "$wired_metric" -ge 0 ] && [ "$wired_metric" -le 9999 ]; then
                    break
                else
                    echo "[ERROR] 请输入一个 0 到 9999 之间的整数。"
                fi
            done
            sudo nmcli connection modify "$wired" ipv4.route-metric "$wired_metric"
            echo "有线连接 '$wired' 的 route-metric 已设为 $wired_metric"            
            echo -e "\n正在重启网络连接..."
            sudo nmcli connection down "$wired" >/dev/null 2>&1 || true
            sleep 2
            sudo nmcli connection up "$wired" >/dev/null 2>&1 || true
            break
        else
            echo "无效选择，请重试。"
        fi
    done
fi

# 配置无线
if [ "$REPLY" == "2" ]; then
    if [ ${#wifi_connections[@]} -eq 0 ]; then
        echo "⚠️ 未检测到无线网络连接！请先连接 WiFi。"
        exit 1
    fi
    
    echo -e "\n配置无线网络优先级为高."
    # 让用户选择无线连接
    echo -e "请选择要用于访问外网的无线连接: "
    select wifi in "${wifi_connections[@]}"; do
        if [[ -n "$wifi" ]]; then
            echo "已选择无线连接: $wifi"
            echo -e "\n正在配置路由优先级..."
            while true; do
                read -p "请输入无线连接 '$wifi' 的路由优先级(metric推荐 100-800, 数值越小优先级越高): " wifi_metric
                if [[ "$wifi_metric" =~ ^[0-9]+$ ]] && [ "$wifi_metric" -ge 0 ] && [ "$wifi_metric" -le 9999 ]; then
                    break
                else
                    echo "[ERROR] 请输入一个 0 到 9999 之间的整数。"
                fi
            done
            sudo nmcli connection modify "$wifi" ipv4.route-metric "$wifi_metric"
            echo "无线连接 '$wifi' 的 route-metric 已设为 $wifi_metric"
            echo -e "\n正在重启网络连接..."
            sudo nmcli connection down "$wifi" >/dev/null 2>&1 || true
            sleep 2
            sudo nmcli connection up "$wifi" >/dev/null 2>&1 || true
            break
        else
            echo "无效选择，请重试。"
        fi
    done
fi

# 验证结果
echo -e "\n新的路由表: "
sleep 3
ip route show

echo -e "\n正在测试外网连通性 (ping baidu.com)..."
if timeout 5 ping -c 2 baidu.com &>/dev/null; then
    echo "外网访问正常！"
else
    echo "无法访问外网!"
fi

echo -e "\n配置完成!"
