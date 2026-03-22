## vcan_manager 用法



```shell
CAN → main$ chmod +x vcan_manager.sh 
CAN → main$ ./vcan_manager.sh 
用法: ./vcan_manager.sh {create [接口名称] [MTU]|delete [接口名称]|status [接口名称]|send [接口名称] [CAN ID] [数据]|receive [接口名称]|cleanup|set-permissions}
示例:
  ./vcan_manager.sh create                                    # 创建默认的vcan0接口
  ./vcan_manager.sh create vcan1 128                          # 创建自定义的vcan1接口并设置MTU为128
  ./vcan_manager.sh delete                                    # 删除默认的vcan0接口
  ./vcan_manager.sh delete vcan1                              # 删除自定义的vcan1接口
  ./vcan_manager.sh status                                    # 检查默认的vcan0接口状态
  ./vcan_manager.sh status vcan1                              # 检查自定义的vcan1接口状态
  ./vcan_manager.sh send vcan0 123 DEADBEEF                   # 向vcan0发送CAN消息，ID=123, 数据=DEADBEEF
  ./vcan_manager.sh send vcan0 123 DEADBEEFDDFFAACCAAZZ       # 发送超过8字节的数据（支持CAN FD和分段发送）
  ./vcan_manager.sh receive vcan0                             # 从vcan0接收CAN消息
  ./vcan_manager.sh cleanup                                   # 删除所有虚拟CAN接口
  ./vcan_manager.sh set-permissions                           # 设置cansend和candump的权限
```
