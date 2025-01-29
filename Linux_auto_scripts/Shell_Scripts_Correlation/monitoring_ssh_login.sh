#!/bin/bash
# @Author: 幸运的锦鲤
# @Date:   2024-11-13 22:30:06
# @Last Modified time: 
# 监控IP登录失败次数
# 主要功能：如果某个IP的登录失败次数超过设定的最大次数，则阻止该IP的进一步登录尝试。
# 通过iptables防火墙阻止连接，当一个IP尝试登录次数超过5次时，iptables会阻止来自该IP的所有连接。


[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本，Ubuntu请使用 sudo xxx." && exit 1


function secrity(){
# 设置要监控的登录失败次数，超过该次数则会被阻止
MAX_ATTEMPTS=5

# 获取所有登录失败的IP并计数
IP_COUNT=$(lastb | awk '{print $3}' | sort | uniq -c | awk '$1 >= '$MAX_ATTEMPTS' {print $2}')


# 遍历所有登录失败次数超过阈值的IP并将其阻止
for IP in ${IP_COUNT}
do
    # 检查IP是否已经在iptables策略中
    if ! iptables -C INPUT -s $IP -j DROP &> /dev/null; then
        echo "`date +"%F %H:%M:%S"`  Blocking $IP ..."
        iptables -A INPUT -s $IP -j DROP
    else
        echo "$IP is already blocked." > /dev/null 2>&1
    fi
done
}

