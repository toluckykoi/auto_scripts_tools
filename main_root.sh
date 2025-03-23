#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-03-23 17:40:06
# @version     : bash
# @Update time : 
# @Description : auto scripts tools root 权限执行便捷主入口.


[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本，普通用户请使用 sudo ./main_root.sh." && exit 1

export LANG=en_US
ROOT_PPATH=$(cd "$(dirname "")"; pwd)

if [ -n "$DISPLAY" ] && xset q &> /dev/null; then
    display=true
else
    display=false
fi

if [ "$display" == 'true' ]; then
    env="桌面环境，请谨慎使用一键脚本！"
else
    env="服务器环境！"
fi

# linux_init_script.sh
function linux_init_script(){
    $ROOT_PPATH/Linux_auto_scripts/System_Init_Scripts/linux_init_script.sh
}


function Main(){
clear
echo -e "——————————————————————————————————————————————————————
   \033[1m                 Main_Root\033[0m
   \033[32mauto scripts tools 执行便捷主入口 —-主菜单v1.0.0\033[0m
   检测到当前环境为：$env
——————————————————————————————————————————————————————
1. ◎ 执行 linux_init_script.sh
q. ◎ 退出安装"
sleep 0.2
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (linux_init_script);;
[q] ) (exit);;
*) (Main);;
esac
}

Main
