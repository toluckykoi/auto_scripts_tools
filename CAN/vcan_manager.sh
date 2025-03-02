#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-02-24 23:57:14
# @version     : bash
# @Update time :
# @Description : 创建、管理和删除虚拟CAN接口，支持高级功能


DEFAULT_VCAN_NAME="vcan0"

# 函数: 加载vcan内核模块
load_vcan_module() {
  echo "加载vcan内核模块..."
  sudo modprobe vcan
  if [ $? -eq 0 ]; then
    echo "vcan内核模块加载成功"
  else
    echo "无法加载vcan内核模块"
    exit 1
  fi
}

# 函数: 创建虚拟CAN接口
create_vcan_interface() {
  local interface_name=$1
  local mtu=$2
  echo "创建虚拟CAN接口: $interface_name"
  sudo ip link add dev $interface_name type vcan
  if [ $? -eq 0 ]; then
    echo "虚拟CAN接口 $interface_name 创建成功"
    if [ -n "$mtu" ]; then
      echo "设置接口 $interface_name 的MTU为 $mtu"
      sudo ip link set $interface_name mtu $mtu
    fi
  else
    echo "无法创建虚拟CAN接口 $interface_name"
    exit 1
  fi
}

# 函数: 启动虚拟CAN接口
bring_up_interface() {
  local interface_name=$1
  echo "启动虚拟CAN接口: $interface_name"
  sudo ip link set up $interface_name
  if [ $? -eq 0 ]; then
    echo "虚拟CAN接口 $interface_name 已启动"
  else
    echo "无法启动虚拟CAN接口 $interface_name"
    exit 1
  fi
}

# 函数: 检查并安装can-utils工具包
install_can_utils_if_needed() {
  echo "检查can-utils是否已安装..."
  if ! command -v candump &> /dev/null; then
    echo "can-utils未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y can-utils
    if [ $? -eq 0 ]; then
      echo "can-utils工具包安装成功"
    else
      echo "无法安装can-utils工具包"
      exit 1
    fi
  else
    echo "can-utils已安装，跳过安装步骤"
  fi
}

# 函数: 删除虚拟CAN接口
delete_vcan_interface() {
  local interface_name=$1
  echo "删除虚拟CAN接口: $interface_name"
  sudo ip link del $interface_name
  if [ $? -eq 0 ]; then
    echo "虚拟CAN接口 $interface_name 已删除"
  else
    echo "无法删除虚拟CAN接口 $interface_name"
    exit 1
  fi
}

# 函数: 检查虚拟CAN接口状态
check_interface_status() {
  local interface_name=$1
  echo "检查虚拟CAN接口 $interface_name 的状态..."
  sudo ip -s link show $interface_name
  if [ $? -ne 0 ]; then
    echo "虚拟CAN接口 $interface_name 不存在或无法访问"
  fi
}

# 函数: 发送CAN消息（支持CAN FD和分段发送）
send_can_message() {
  local interface_name=$1
  local can_id=$2
  local data=$3
  echo "向接口 $interface_name 发送CAN消息: ID=$can_id, 数据=$data"

  # 检查数据长度
  data_length=${#data}
  if [ $data_length -le 16 ]; then
    # 标准CAN帧（最多8字节）
    formatted_data=$(echo $data | sed 's/\(..\)/\1./g' | sed 's/\.$//')
    cansend $interface_name "$can_id#$formatted_data"
  else
    # CAN FD帧（最多64字节）
    if [ $data_length -le 128 ]; then
      formatted_data=$(echo $data | sed 's/\(..\)/\1./g' | sed 's/\.$//')
      cansend $interface_name "$can_id##1$formatted_data"
    else
      # 分段发送（超过64字节）
      segment_size=16  # 每段8字节（16个字符）
      total_segments=$(( (data_length + segment_size - 1) / segment_size ))
      for (( i=0; i<total_segments; i++ )); do
        start=$(( i * segment_size ))
        end=$(( start + segment_size ))
        segment=${data:start:segment_size}
        formatted_data=$(echo $segment | sed 's/\(..\)/\1./g' | sed 's/\.$//')
        cansend $interface_name "$can_id#$formatted_data"
        if [ $? -ne 0 ]; then
          echo "分段发送失败"
          exit 1
        fi
        echo "分段 $((i+1))/$total_segments 发送成功: $segment"
      done
    fi
  fi

  if [ $? -eq 0 ]; then
    echo "CAN消息发送成功"
  else
    echo "无法发送CAN消息"
    exit 1
  fi
}

# 函数: 接收CAN消息
receive_can_message() {
  local interface_name=$1
  echo "从接口 $interface_name 接收CAN消息..."
  candump $interface_name
}

# 函数: 清理所有虚拟CAN接口
cleanup_all_vcan_interfaces() {
  echo "清理所有虚拟CAN接口..."
  for interface in $(ip link show | grep vcan | awk -F: '{print $2}'); do
    delete_vcan_interface $interface
  done
}

# 函数: 设置cansend和candump的权限
set_can_tools_permissions() {
  echo "设置cansend和candump的权限..."
  for tool in cansend candump; do
    if [ -f "$(which $tool)" ]; then
      sudo setcap 'cap_net_admin,cap_net_raw+ep' "$(which $tool)"
      if [ $? -eq 0 ]; then
        echo "$tool 权限设置成功"
      else
        echo "$tool 权限设置失败"
        exit 1
      fi
    else
      echo "$tool 未找到，请确保can-utils已安装"
      exit 1
    fi
  done
}

# 主程序
if [ "$1" == "create" ]; then
  # 获取接口名称，如果未指定则使用默认值
  VCAN_NAME=${2:-$DEFAULT_VCAN_NAME}
  MTU=$3
  load_vcan_module
  create_vcan_interface $VCAN_NAME $MTU
  bring_up_interface $VCAN_NAME
  install_can_utils_if_needed
elif [ "$1" == "delete" ]; then
  # 获取接口名称，如果未指定则使用默认值
  VCAN_NAME=${2:-$DEFAULT_VCAN_NAME}
  delete_vcan_interface $VCAN_NAME
elif [ "$1" == "status" ]; then
  # 获取接口名称，如果未指定则使用默认值
  VCAN_NAME=${2:-$DEFAULT_VCAN_NAME}
  check_interface_status $VCAN_NAME
elif [ "$1" == "send" ]; then
  # 发送CAN消息
  VCAN_NAME=${2:-$DEFAULT_VCAN_NAME}
  CAN_ID=$3
  DATA=$4
  if [ -z "$CAN_ID" ] || [ -z "$DATA" ]; then
    echo "错误: 发送CAN消息时需要提供CAN ID和数据"
    echo "示例: $0 send vcan0 123 DEADBEEF"
    exit 1
  fi
  send_can_message $VCAN_NAME $CAN_ID $DATA
elif [ "$1" == "receive" ]; then
  # 接收CAN消息
  VCAN_NAME=${2:-$DEFAULT_VCAN_NAME}
  receive_can_message $VCAN_NAME
elif [ "$1" == "cleanup" ]; then
  # 清理所有虚拟CAN接口
  cleanup_all_vcan_interfaces
elif [ "$1" == "set-permissions" ]; then
  # 设置cansend和candump的权限
  set_can_tools_permissions
else
  echo "用法: $0 {create [接口名称] [MTU]|delete [接口名称]|status [接口名称]|send [接口名称] [CAN ID] [数据]|receive [接口名称]|cleanup|set-permissions}"
  echo "示例:"
  echo "  $0 create           # 创建默认的vcan0接口"
  echo "  $0 create vcan1 128 # 创建自定义的vcan1接口并设置MTU为128"
  echo "  $0 delete           # 删除默认的vcan0接口"
  echo "  $0 delete vcan1     # 删除自定义的vcan1接口"
  echo "  $0 status           # 检查默认的vcan0接口状态"
  echo "  $0 status vcan1     # 检查自定义的vcan1接口状态"
  echo "  $0 send vcan0 123 DEADBEEF # 向vcan0发送CAN消息，ID=123, 数据=DEADBEEF"
  echo "  $0 send vcan0 123 DEADBEEFDDFFAACCAAZZ # 发送超过8字节的数据（支持CAN FD和分段发送）"
  echo "  $0 receive vcan0    # 从vcan0接收CAN消息"
  echo "  $0 cleanup          # 删除所有虚拟CAN接口"
  echo "  $0 set-permissions  # 设置cansend和candump的权限"
  exit 1
fi

exit 0
