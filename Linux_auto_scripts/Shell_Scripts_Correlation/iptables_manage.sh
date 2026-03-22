#!/bin/bash
# @Author: 幸运的锦鲤
# @Date:   2024-11-13 22:14:06
# @Last Modified time: 
# 管理iptables防火墙基础规则的shell脚本
# 主要功能：
# 1. 查看当前iptables的规则。
# 2. 清空所有iptables的规则。
# 3. 放行指定IP访问。
# 4. 封堵常见端口。
# 5. 自定义规则。
# 6. 删除单条iptables规则。
# 7. 关闭selinux。


[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本，Ubuntu请使用 sudo xxx." && exit 1


tables(){
while true
do
echo "
(1) 查看iptables
(2) 清空所有规则
(3) 放行指定IP访问
(4) 封堵常见端口
(5) 自定义规则
(6) 删除单条规则
(7) 关闭selinux
(0) 退出"
read -p "选择要执行的项:  " put
case $put in

1)
echo "************************************************************************"
iptables -nvL
echo "************************************************************************"
echo "*************************************NAT********************************"
iptables -nL -t nat
echo "*************************************NAT********************************"
;;
2)
iptables -F
iptables -t nat -F
;;
3)
read -p "请输入要放行的IP: " a 
#ipadd=$(ifconfig |grep "broadcast"|awk '{print $2}')
iptables -I INPUT -s $a   -j ACCEPT
[ $? -eq 0 ]
    echo "已放行$a"
    sleep 2
;;
4)
read -p "请务必先放行IP再执行此操作，否则会导致ssh无法登录设备yes/exit：" waring
if [ "$waring" = "yes" ];then
    iptables -A INPUT -p tcp -m multiport  --dport 22,23 -j DROP
[ $? -eq 0 ]
    echo "ssh,telnet端口已禁止所有IP连接"
    sleep 2       
    iptables -A INPUT -p tcp --dport 3306 -j DROP
[ $? -eq 0 ]   
    echo "mysql端口已禁止所有IP连接"
    sleep 2
    iptables -A INPUT -p tcp -m multiport  --dport 21,20 -j DROP #-m multiport  同时封堵多个端口
[ $? -eq 0 ] 
    echo "ftp端口已禁用所有IP连接"
    sleep 2     
    iptables -A INPUT -p tcp -m multiport  --dport 445,139,135,137,138,1434  -j DROP
  [ $? -eq 0 ]
    echo "共享服务端口已禁用所有IP连接"
    iptables -A INPUT -p tcp -m multiport --dport 25,53
[ $? -eq 0 ]
    echo "邮件传输协议端口已禁用所有IP连接"
elif [ "waring" = "exit" ];then
    exit 0
fi
;;
5)
#IP=$(ifconfig |grep "broadcast"|awk '{print $2}')
echo "输入1禁止访问所有端口，输入2指定端口禁止访问,exit退出"
read -p "输入策略写入方式：" A
if [ "$A" = 1 ];then
    read -p "请输入要放行的IP：" IP
    iptables -A INPUT -j DROP
    echo "已禁止所有连接"
    iptables -I INPUT -s $IP -j ACCEPT
    echo "允许$IP访问"
elif [ "$A" = 2 ];then
    read -p "请输入放行的IP：" IPADD
    read -p "请输入端口协议(tcp/udp): " TCP
    #read -p "请输入允许访问的端口：" PORT
    read -p "请输入禁止访问的端口：" DRPORT
    iptables -A INPUT -p $TCP -m multiport  --dport $DRPORT -j DROP       
    echo "$DRPORT已禁止所有连接"
    iptables -I INPUT -s $IPADD   -j ACCEPT   
    echo "允许$IPADD访问"
elif [ "$A" = "exit" ];then
    continue    
fi
;;
6)
iptables -L -n --line-number              
read -p "请输入要删除的规则序号：" A
iptables -D INPUT $A
;;
7)
echo -e "\033[34m 输入1临时关闭firewalld和selinux，输入2永久关闭 \033[0m"
read -p "请输入要操作的功能：" PUT
if [ "$PUT" = 1 ];then
    systemctl stop firewalld.service
    setenforce 0
    echo -e "\033[31m 已临时关闭firewalld和selinux \033[0m"
elif [ "$PUT" = 2 ];then
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config    
    echo -e "\033[31m 已永久关闭firewalld和selinux,需重启系统生效 \033[0m"
fi
sleep 3
echo -e "\033[34m 重新启用firewalld输入1/启用selinux输入2/查看状态请输入"status" \033[0m"
read -p "请输入你的选择:  " input

if [ "$input" = 1 ];then
    systemctl start firewalld.service
    systemctl enable firewalld.service
    echo "已启用firewalld"

elif [ "$input" = 2 ];then
    setenforce 1
    sed -i "s/SELINUX=disabled/SELINUX=enforcing/" /etc/selinux/config
    echo "已启用selinux"

elif [ "$input" = "status" ];then
    echo -e "\033[34m 查看firewalld状态: \033[0m"
    echo ""
    firewall-cmd --state
    echo ""
    echo -e "\033[34m 查看selinux状态: \033[0m"
    echo ""
    /usr/sbin/sestatus -v
fi
;;
0)
break
exit 0
;;
*)
echo -e "\033[31m 您的输入有误,请重新输入[0~7]的数字 \033[0m"
;;
esac
done
}

tables
