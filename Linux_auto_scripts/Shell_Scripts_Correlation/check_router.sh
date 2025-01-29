#!/bin/bash
# @Author: 蓝陌
# @Date:   2023-09-29 00:46
# @Last Modified time:
# 用于监测路由器时候出现断开
# 例子运行命令：./check_router.sh 192.168.0.1

# 输入路由器IP地址和ping的超时时间（单位：秒）
router_ip=$1
timeout=3

# 检测命令输出的关键字，用于判断是否连接正常
key_cn="64 bytes from"
key_zh="64 字节"

# 日志文件路径
log_file=$HOME/Ping_log.log

while true; do
  # 执行ping命令并获取输出结果
  ping_result=$(ping -c 1 -W $timeout $router_ip)

  # 判断ping命令输出中是否包含关键字，表示连接正常
  if [[ $ping_result =~ $key_cn ]] || [[ $ping_result =~ $key_zh ]]; then
    log_message="$(date '+%Y-%m-%d %H:%M:%S') - Router is connected."
    echo "$log_message"
    echo " " >> $log_file
    echo "$log_message" >> $log_file
    echo "$ping_result" >> $log_file
  else
    log_message="$(date '+%Y-%m-%d %H:%M:%S') - Router is disconnected."
    echo "$log_message"
    echo $ping_result
    echo " " >> $log_file
    echo " " >> $log_file
    echo " " >> $log_file
    echo "$log_message" >> $log_file
    echo "$ping_result" >> $log_file
  fi

  sleep 1
done

