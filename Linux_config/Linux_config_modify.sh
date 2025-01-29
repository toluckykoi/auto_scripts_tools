#!/bin/bash
# @Author: 蓝陌
# @Date:   2023-01-01 11:42:00
# @Last Modified time:
# 常用配置文件自动修改
# 需要使用 source 运行此脚本！！！
# 每运行完一个停止3秒
#####
# 该脚本功能:
# 1、修改镜像文件
# 2、修改登录欢迎语
# 3、修改 .bashrc 文件
# 4、在修改前，会进行备份文件
# git clone https://github.com/sityliu/Linux_Config_File.git
#####

# 请使用root用户执行此脚本
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！！！" && exit 1



function Centos_7.x(){
    echo "####################Centos_7.x 配置文件修改中####################"
    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    cp CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
    sleeo 3
    yum makecache

    echo "已完成......"
    
}


function Debian_11(){
    echo "####################Debian_11 配置文件修改中####################"
    cp /etc/apt/sources.list /etc/apt/sources.list.baskup
    cp Debian-11_sources.list /etc/apt/sources.list
    sleep 3
    apt update

    echo "已完成......"
}


function Ubuntu_18(){
    echo "####################Ubuntu_18 配置文件修改中####################"
    cp /etc/apt/sources.list /etc/apt/sources.list.baskup
    cp Ubuntu-18-sources.list /etc/apt/sources.list
    sleep 3
    apt update

    echo "已完成......"
}


function Ubuntu_20(){
    echo "####################Ubuntu_20 配置文件修改中####################"
    cp /etc/apt/sources.list /etc/apt/sources.list.baskup
    cp Ubuntu-20-sources.list /etc/apt/sources.list
    sleep 3
    apt update

    echo "已完成......"
}


function Init(){
clear
echo -e "————————————————————————————————————————————————————
	\033[1m        Linux_config_file\033[0m
	\033[32m个性化配置文件修改——系统选择-version:1.3\033[0m
	说明：请使用 source 命令运行此脚本！！！
————————————————————————————————————————————————————
1. ◎ Centos 7.x
2. ◎ Debian 11
3. ◎ Ubuntu 18
4. ◎ Ubuntu 20 (含server)
0. ◎ 退出"
read -p "请输入序号并回车：" num
case "$num" in
[1] ) (Centos_7.x);;
[2] ) (Debian_11);;
[3] ) (Ubuntu_18);;
[4] ) (Ubuntu_20);;
[0] ) (exit);;
*) (Init);;
esac
}

Init