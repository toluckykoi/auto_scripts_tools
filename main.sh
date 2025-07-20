#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-03-23 17:40:06
# @version     : bash
# @Update time : 
# @Description : auto scripts tools 便捷主入口文件.


# [ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本，普通用户请使用 sudo ./main_root.sh." && exit 1
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

# system_info.sh
function linux_system_info(){
    cd $ROOT_PPATH/Linux_auto_scripts/Shell_Scripts_Correlation/
    ./system_info.sh
}

# linux_init_script.sh
function linux_init_script(){
    cd $ROOT_PPATH/Linux_auto_scripts/System_Init_Scripts/
    sudo ./linux_init_script.sh
}

# swap_set.sh
function linux_swap_set(){
    cd $ROOT_PPATH/Linux_auto_scripts/Shell_Scripts_Correlation/
    sudo ./swap_set.sh
}

# install_ros_with_docker.py
function install_ros_with_docker(){
    cd $ROOT_PPATH/Ros_Correlation/fishros_mod/
    python3 install_ros_with_docker.py
}

function Main(){
clear
echo -e "——————————————————————————————————————————————————————
   \033[1m                 Main_Root\033[0m
   \033[32mauto scripts tools 执行便捷主入口 —-主菜单v1.0.0\033[0m
   检测到当前环境为：$env
——————————————————————————————————————————————————————
1. ◎ 查看当前系统的各类信息
2. ◎ 执行一键系统初始化脚本
3. ◎ 执行虚拟内存设置
4. ◎ 执行docker ros 安装脚本
q. ◎ 退出安装"
sleep 0.2
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (linux_system_info);;
[2] ) (linux_init_script);;
[3] ) (linux_swap_set);;
[4] ) (install_ros_with_docker);;
[q] ) (exit);;
*) (Main);;
esac
}

Main
