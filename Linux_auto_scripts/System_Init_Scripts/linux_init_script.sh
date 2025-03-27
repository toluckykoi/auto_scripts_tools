#!/bin/bash
# @Author: 蓝陌
# @Date:   2024-06-29 23:49:06
# @Last Modified time: 2024-07-00 00:00:00
# 新服务器初始化脚本
# 需要使用 source 运行此脚本！！！
#####
# 该脚本功能:
# 用于初始化云服务或着初始化LINUX系统(暂时仅支持X86_64平台)
#####

# 定义变量
# 默认用户名、密码:
default_username="toluckykoi"
default_password="toluckykoi.123qwe"
FLAG_DOCKER=0
BT_PARAM=0

# 检查参数数量
if [ "$#" -eq 0 ]; then
    SHELL_USER="$default_username"
    SHELL_PASSWD="$default_password"
elif [ "$#" -eq 1 ] || [ "$#" -eq 2 ]; then
    # 获取参数
    SHELL_USER="$1"
    SHELL_PASSWD="$default_password"

    # 检查是否提供了新密码
    if [ "$#" -eq 2 ]; then
        SHELL_PASSWD="$2"
    else
        SHELL_PASSWD="$default_password"
    fi
else
    echo "用法： $0 [<用户名>] [<新密码>]"
    exit 1
fi

# 脚本运行依赖 curl 命令
function install_curl() {
    echo ""; echo ""
    echo "####################安装 curl ####################"
    if [ "$software_manager" == "apt" ]; then
        echo "apt: install base software"
        apt update
        apt install -y curl
        echo "已安装 curl"
    
    elif [ "$software_manager" == "yum" ]; then
        echo "yum: install base software"
        yum install -y curl
        echo "已安装 curl"
    else
        echo "版本不支持."
        exit 1
    fi
}

#  请使用root用户执行此脚本
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本，Ubuntu请使用 sudo xxx." && exit 1
export LANG=en_US

# 1、什么系统类型的服务器  2、服务器在哪里  3、桌面版还是服务器 4、是否中国时间 5、使用的软件管理器
ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')
VERSION_ID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F '=' '{print $2}' | awk -F '"' '{print $2}')
architecture=$(uname -m)
DIR_PATH=$( cd "$( dirname "$(dirname "$(pwd)")" )" >/dev/null 2>&1 && pwd )
random_char=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)

if command -v apt >/dev/null 2>&1; then
    software_manager=apt
elif command -v yum >/dev/null 2>&1; then
    software_manager=yum
else
    echo "未检测到apt、yum或dnf，请手动安装依赖"
    exit 1
fi

if [ -n "$DISPLAY" ] && xset q &> /dev/null; then
    display=true
else
    display=false
fi

echo "curl 命令检查..."
if command -v curl >/dev/null 2>&1; then
    echo "curl 命令存在，无需安装！"
else
    echo "未检测到 curl 命令，需要进行安装..."
    install_curl
fi

server_ip=$(curl -s https://ipinfo.io/ip)
server_country=$(curl -s https://ipinfo.io/$server_ip/country)
if [ "$server_country" = "CN" ]; then
    server_region=china
else
    server_region=foreign
fi

timezone=$(date +%Z)
if [ "$timezone" == "CST" ]; then
    time_zone=CST
else
    time_zone=UTC
fi

# 系统信息显示
echo $ID $VERSION_ID $architecture
current_script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
current_script_path1="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
current_script_path="$current_script_path/logs"
[ ! -d "$current_script_path" ] && mkdir -p "$current_script_path"
RESULTFILE="$current_script_path/Linux_Init_Log-`date +%Y%m%d`.txt"


function date_info() {
    echo ""; echo ""
    # 如果是国外服务器的话，需要将 UTC 时间转换为 CST 时间
    # rm -rf /etc/localtime
    # ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    if [ "$time_zone" == "UTC" ]; then
        echo "####################更换国内时间####################"
        sudo timedatectl set-timezone Asia/Shanghai
        timedatectl status
        date
        echo "UTC 时间转换为 CST 时间"
    else
        echo "CST 时间，无需更改！"
    fi
    
}


# 初始化：
function debian_sudo(){
    echo ""; echo ""
    if [ "$ID" == "debian" ]; then
        echo "####################sudo 安装配置####################"
        if command -v sudo >/dev/null 2>&1; then
            debian_sudo=sudo
            echo "sudo 无需配置"
        else
            echo "未检测到sudo，正在安装....."
            apt install sudo -y
            echo "sudo安装完成"
        fi
    else
        echo "不是 Debian 系统，不需要配置！"
    fi
}

# docker加速
function docker_speed(){
    echo ""; echo ""
    echo "####################docker pull加速设置####################"
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.xuanyuan.me",
    "https://docker.1ms.run",
    "https://hub.rat.dev",
    "https://doublezonline.cloud",
    "https://dislabaiot.xyz",
    "http://docker-mirror.aigc2d.com",
    "https://hub.xdark.top/"
    ]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
}

# 1、换源
function cn_yuan(){
    echo ""; echo ""
    if [ "$server_region" == "china" ]; then
        echo ""
        echo "在国内环境，需要更换镜像源！"

        echo "####################更换国内源镜像####################"
        if [ "$software_manager" == "apt" ] && [ "$ID" == "ubuntu" ]; then
            if [ "$VERSION_ID" == "18.04" ]; then
                echo "ubuntu 18.04"
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo cp $DIR_PATH/Linux_config/ubuntu/Ubuntu-18-sources.list /etc/apt/sources.list
                sudo apt update
                echo "已更换镜像源"

            elif [ "$VERSION_ID" == "20.04" ]; then
                echo "ubuntu 20.04"
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo cp $DIR_PATH/Linux_config/ubuntu/Ubuntu-20-sources.list /etc/apt/sources.list
                sudo apt update
                echo "已更换镜像源"

            elif [ "$VERSION_ID" == "22.04" ]; then
                echo "ubuntu 22.04"
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo cp $DIR_PATH/Linux_config/ubuntu/Ubuntu-22-sources.list /etc/apt/sources.list
                sudo apt update
                echo "已更换镜像源"

            elif [ "$VERSION_ID" == "24.04" ]; then
                echo "ubuntu 24.04"
                sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
                sudo cp $DIR_PATH/Linux_config/ubuntu/Ubuntu-24-sources.list /etc/apt/sources.list
                sudo apt update
                echo "已更换镜像源"

            else
                echo "版本不支持"
                exit 1
            fi

        elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
            if [ "$VERSION_ID" == "11" ]; then
                echo "debian 11"
                cp /etc/apt/sources.list /etc/apt/sources.list.bak
                cp $DIR_PATH/Linux_config/debian/Debian-11-sources.list /etc/apt/sources.list
                apt update
                echo "已更换镜像源"

            elif [ "$VERSION_ID" == "12" ]; then
                echo "debian 12"
                cp /etc/apt/sources.list /etc/apt/sources.list.bak
                cp $DIR_PATH/Linux_config/debian/Debian-12-sources.list /etc/apt/sources.list
                apt update
                echo "已更换镜像源"

            else
                echo "版本不支持"
                exit 1
            fi

        elif [ "$software_manager" == "yum" ] && [ $ID == '"centos"' ]; then
            if [ "$VERSION_ID" == "7" ]; then
                echo "centos 7"
                cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
                cp $DIR_PATH/Linux_config/centos/huawei-CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
                yum clean all
                yum makecache
                echo "已更换镜像源"

            else
                echo "版本不支持"
                exit 1
            fi
        else
            echo "版本不支持！"
        fi
    else
        echo "国外环境，无需配置镜像源！"

    fi
}

# 2、基础软件安装
function install_base_software() {
    echo ""; echo ""
    echo "####################安装基础软件####################"
    if [ "$software_manager" == "apt" ]; then
        echo "apt: install base software"
        apt update
        apt upgrade -y
        sleep 2
        apt -y install lsb-release net-tools curl wget vim htop git unzip expect acct tar build-essential cmake gdb dos2unix tmux openssh-server gnupg2
        apt -y install x11-xserver-utils bash-completion
        echo "已安装基础软件"
    
    elif [ "$software_manager" == "yum" ]; then
        echo "yum: install base software"
        yum update -y
        sleep 2
        yum -y install net-tools gcc gcc-c++ kernel-devel cmake make curl wget vim git unzip psacct expect epel-release tar dos2unix tmux
        yum install -y xset
        yum install -y htop
        yum install -y bash-completion bash-completion-extras
        echo "已安装基础软件"
    else
        echo "版本不支持"
        exit 1
    fi
}

# bashrc 配置
function config_bashrc() {
    echo ""; echo ""
    echo "####################更换 bashrc 配置####################"
    if [ "$software_manager" == "apt" ] && [ "$ID" == "ubuntu" ]; then
        echo "ubuntu cp bashrc"
        cp $DIR_PATH/Linux_config/ubuntu/Ubuntu_user_.bashrc /home/$SHELL_USER/.bashrc
        cp $DIR_PATH/Linux_config/ubuntu/Ubuntu_root_.bashrc /root/.bashrc

    elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
        echo "debian cp bashrc"
        cp $DIR_PATH/Linux_config/debian/Debian_user_.bashrc /home/$SHELL_USER/.bashrc
        cp $DIR_PATH/Linux_config/debian/Debian_root_.bashrc /root/.bashrc

    elif [ $software_manager == "yum" ] && [ $ID == '"centos"' ]; then
        if [ "$VERSION_ID" == "7" ]; then
            echo "centos cp bashrc"
            cp $DIR_PATH/Linux_config/centos/Centos_user_.bashrc /home/$SHELL_USER/.bashrc
            cp $DIR_PATH/Linux_config/centos/Centos_root_.bashrc /root/.bashrc
            
        else
            echo "版本不支持"
            exit 1
        fi

    else
        echo "版本不支持"
    
    fi
}
function config_bashrc_procedure() {
    echo ""; echo ""
    sleep 0.3
    read -ep "需要更换 bashrc 配置的用户：" BASHRC_USER
    echo "####################更换 bashrc 配置####################"
    if [ "$software_manager" == "apt" ] && [ "$ID" == "ubuntu" ]; then
        echo "ubuntu cp bashrc"
        cp $DIR_PATH/Linux_config/ubuntu/Ubuntu_user_.bashrc /home/$BASHRC_USER/.bashrc
        cp $DIR_PATH/Linux_config/ubuntu/Ubuntu_root_.bashrc /root/.bashrc

    elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
        echo "debian cp bashrc"
        cp $DIR_PATH/Linux_config/debian/Debian_user_.bashrc /home/$BASHRC_USER/.bashrc
        cp $DIR_PATH/Linux_config/debian/Debian_root_.bashrc /root/.bashrc

    elif [ "$software_manager" == "yum" ] && [ $ID == '"centos"' ]; then
        if [ $VERSION_ID == 7 ]; then
            echo "centos cp bashrc"
            cp $DIR_PATH/Linux_config/centos/Centos_user_.bashrc /home/$BASHRC_USER/.bashrc
            cp $DIR_PATH/Linux_config/centos/Centos_root_.bashrc /root/.bashrc
            
        else
            echo "版本不支持"
            exit 1
        fi

    else
        echo "版本不支持"
        echo $software_manager $ID $VERSION_ID
    
    fi
}

# 3、系统基础配置
function config_system() {
    echo ""; echo ""
    echo "####################对系统进行修改配置####################"
    if [ "$display" == 'true' ]; then
        echo "桌面系统环境，不需要太多配置..."

    else
        echo "服务器环境，需要进行以下配置："
        hostnamectl set-hostname "${ID}-${random_char}"
        echo "127.0.0.1 ${ID}-${random_char}" >> /etc/hosts

        cloud_file_path="/etc/cloud/cloud.cfg"
        if [ -f "$cloud_file_path" ]; then
            echo "文件 $cloud_file_path 存在，删除对应配置！"
            sudo rm /etc/cloud/cloud.cfg
            echo "指定的行已从配置文件中删除。"
        else
            echo "文件 $cloud_file_path 不存在不需要配置."
        fi

        if [ "$software_manager" == "apt" ]; then
            echo "debian 系特有配置"
            useradd -m $SHELL_USER -s /bin/bash
            echo $SHELL_USER:$SHELL_PASSWD | sudo chpasswd
            if [ $? -eq 0 ]; then
                echo "密码已成功更新。"
            else
                echo "密码更新失败。"
                exit
            fi

            # 管理员身份
            echo "$SHELL_USER  ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$SHELL_USER
            sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            sed -i "s/^Port 22/Port 32200/" /etc/ssh/sshd_config
            sed -i "s/^#Port 22/Port 32200/" /etc/ssh/sshd_config
            cat /etc/ssh/sshd_config | grep "Port\ "
            service sshd restart


        elif [ "$software_manager" == "yum" ]; then
            echo "centos 系特有配置"
            useradd $SHELL_USER
            echo $SHELL_USER:$SHELL_PASSWD | sudo chpasswd
            if [ $? -eq 0 ]; then
                echo "密码已成功更新。"
            else
                echo "密码更新失败。"
                exit
            fi

            # 管理员身份
            echo "$SHELL_USER  ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$SHELL_USER
            sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            awk "/Port\ /" /etc/ssh/sshd_config
            sed -i "17s/#Port 22/Port 22/g" /etc/ssh/sshd_config
            awk "/Port\ /" /etc/ssh/sshd_config
            sed -i "17s/Port 22/Port 32200/g" /etc/ssh/sshd_config
            cat /etc/ssh/sshd_config|grep "Port\ "
            service sshd restart
            #firewall-cmd --zone=public --add-port=32200/tcp --permanent

        else
            echo "版本不支持"
            exit 1
        fi
    fi

    # 初始化完用户后创建用户文件存放文件夹
    mkdir -p /home/$SHELL_USER/Documents
    mkdir -p /home/$SHELL_USER/Downloads
    mkdir -p /home/$SHELL_USER/Temp

    sudo chown -R $SHELL_USER:$SHELL_USER /home/$SHELL_USER/Documents
    sudo chown -R $SHELL_USER:$SHELL_USER /home/$SHELL_USER/Downloads
    sudo chown -R $SHELL_USER:$SHELL_USER /home/$SHELL_USER/Temp

    sudo chown -R $SHELL_USER:$SHELL_USER $current_script_path

}

# 4、docker安装
function install_docker() {
    echo ""; echo ""
    # 因国内限制了docker，国内安装docker的曲线救国方法，国外直接一键安装
    echo "####################安装docker容器####################"    
    # if command -v docker &> /dev/null; then
    #     echo "Docker 已安装，无需再安装！"
    # else
    #     echo "Docker 未安装，现在开始安装！"
    
    if [ "$server_region" = "china" ]; then
        echo "国内安装docker容器"
        if [ "$software_manager" == "apt" ]; then
            echo "debian系docker容器安装"
            sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            if [ "$ID" == "ubuntu" ]; then
                curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
                "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            elif [ "$ID" == "debian" ]; then
                curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian \
                "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            fi
            sudo apt-get -y update
            sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo service docker start
            sudo systemctl enable docker.service
            
            groupadd docker
            if [ $FLAG_DOCKER == 1 ]; then
                usermod -aG docker $SHELL_USER
            else
                echo "当前执行脚本的用户是：$USER"
                sleep 0.2
                read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
                sudo usermod -aG docker $docker_user
            fi
            
            # newgrp docker
            sudo apt install -y bash-completion

            docker_speed
            echo "docker 容器安装完成，请重启终端(桌面版系统需要重启系统才能普通用户使用docker命令!)"

        elif [ "$software_manager" == "yum" ]; then
            echo "centos系docker容器安装"
            yum install -y yum-utils device-mapper-persistent-data lvm2
            yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
            yum makecache --timer
            yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            service docker start
            systemctl enable docker.service
            
            groupadd docker
            if [ $FLAG_DOCKER == 1 ]; then
                usermod -aG docker $SHELL_USER
            else
                echo "当前执行脚本的用户是：$USER"
                sleep 0.2
                read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
                usermod -aG docker $docker_user
            fi

            # newgrp docker
            yum install -y bash-completion

            docker_speed
            echo "docker 容器安装完成，请重启终端(桌面版系统需要重启系统才能普通用户使用docker命令!)"

        else
            echo "版本不支持"
            exit 1
        fi

    elif [ "$server_region" = "foreign" ]; then
        echo "一键安装docker容器"
        curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh
        sudo service docker start
        sudo systemctl enable docker.service

        groupadd docker
        if [ $FLAG_DOCKER == 1 ]; then
            usermod -aG docker $SHELL_USER
        else
            echo "当前执行脚本的用户是：$USER"
            sleep 0.2
            read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
            usermod -aG docker $docker_user
        fi
        # sudo newgrp docker
        echo "docker容器安装完成"
    fi
    # fi

    # 如果上述安装失败，则尝试离线安装docker容器（待定）
    if [ $? -eq 0 ]; then
      echo "docker容器在线安装完成，无需下载离线安装包进行安装"
    else
      echo "在线docker容器安装失败，将尝试离线安装docker容器"
    fi

}

# 5、宝塔面板安装
function install_bt() {
    BT_PARAM=1
    echo ""; echo ""
    echo "####################安装宝塔面板####################"
    # 宝塔降级?
    #  mkdir -p /root/server_init/bt && cd /root/server_init/bt
    #  wget http://download.bt.cn/install/update/LinuxPanel-7.7.0.zip
    #  unzip LinuxPanel-7.7.0.zip
    if [ "$software_manager" == "apt" ]; then
        echo "Debian系列宝塔安装脚本执行中..."
        wget -O install.sh https://download.bt.cn/install/install_lts.sh && sudo bash install.sh ed8484bec <<EOF
y
EOF
        if [ $? -eq 0 ]; then echo "宝塔安装成功"; else echo "宝塔安装失败"; fi

    elif [ "$software_manager" == "yum" ]; then
        echo "CentOS系列宝塔安装脚本执行中..."
        yum install -y wget && wget -O install.sh https://download.bt.cn/install/install_lts.sh && bash install.sh ed8484bec <<EOF
y
EOF
        if [ $? -eq 0 ]; then echo "宝塔安装成功"; else echo "宝塔安装失败"; fi

    else
        echo "万能安装脚本执行中..."
        url=https://download.bt.cn/install/install_lts.sh;if [ -f /usr/bin/curl ];then curl -sSO $url;else wget -O install_lts.sh $url;fi;bash install_lts.sh ed8484bec <<EOF
y
EOF
        if [ $? -eq 0 ]; then echo "宝塔安装成功"; else echo "宝塔安装失败"; fi
        
    fi
}

# 5、虚拟内存设置
function virtual_memory() {
    echo ""; echo ""
    swap_info=$(free -m | grep Swap)
    total_swap=$(echo "$swap_info" | awk '{print $2}')
    # 检查交换空间是否大于0
    if [ "$total_swap" -gt 0 ]; then
        echo "Virtual memory (swap) is enabled with total size: $total_swap MB"
        swap_info=$(swapon -s)
        echo "Current swap partitions and files:"
        echo "$swap_info"
    else
        echo "Virtual memory (swap) is not enabled."
        echo "####################设置虚拟内存####################"
        dd if=/dev/zero of=/swapfile bs=256M count=16
        # count的大小就是增加的swap空间的大小，256M是块大小，所以空间大小是bs*count=1024MB
        mkswap /swapfile
        chmod 0600 /swapfile
        swapon /swapfile
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        free -h
        sleep 2
    fi
}

# 6、neofetch
function neofetch_install() {
    echo ""; echo ""
    echo "####################neofetch安装####################"
    # 如何在Linux或类unix系统上安装neofetch
    # wget -c https://github.com/dylanaraps/neofetch/archive/master.zip
    # unzip master.zip
    cd $current_script_path1/neofetch
    pwd
    sudo make install
    neofetch
}

# 7、防火墙
function firewall_install() {
    echo ""; echo ""
    echo "####################防火墙配置####################"
    if [ $BT_PARAM == 1 ]; then
        echo "已安装宝塔面板，不进行防火墙设置，以防止出现冲突！"

    else
        if [ "$software_manager" == "apt" ]; then
        echo "Debian系列防火墙安装脚本执行中..."
        sudo apt install -y ufw
        sudo ufw enable <<EOF
y
EOF
        sudo ufw allow 32200
        sudo ufw reload
        sudo ufw status verbose
        echo "防火墙配置完成！！！"

    elif [ "$software_manager" == "yum" ]; then
        echo "CentOS系列防火墙安装脚本执行中..."
        sudo yum -y install iptables
        sudo yum -y install iptables-services
        sudo systemctl start iptables.service
        sudo systemctl enable iptables.service
        sudo systemctl status iptables.service

        sudo iptables -F
        sudo iptables -A INPUT -p tcp --dport 32200 -j ACCEPT
        
        # 保存iptables规则
        sudo service iptables save

        # 重启iptables服务
        sudo service iptables stop
        sudo service iptables start

        sudo iptables -L
        echo "防火墙配置完成！！！"

        # iptables 比较复杂，后期得改进

    else
        echo "适配中..."

    fi
fi 
}


function python3_install(){
    echo ""; echo ""
    echo "一般 Linux 中已经自带有 Python2 和 Python3，不建议再自行安装其他版本的 Python；可以安装 Anaconda3 或者 Miniconda3 和使用 Python 的虚拟环境！"
    echo "以下安装 Python 是编译的方式安装，安装时间比较长！"
    read -ep  "特殊使用非要安装 Python(yes/no)：" option
    if [ "$option" == "yes" ]; then
        echo "####################Python3.8.8安装####################"
        if [ "$software_manager" == "apt" ]; then
            sudo apt install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libsqlite3-dev libreadline-dev libffi-dev llvm curl libbz2-dev python-dev
            sudo apt install -y gcc make tar
        elif [ "$software_manager" == "yum" ]; then
            sudo yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel xz-devel libffi-devel gcc make
        else
            echo "适配中..."
            exit 1
        fi
        if [ $? -eq 0 ]; then
            mkdir -p /tmp/python3.x && cd /tmp/python3.x
            wget -c https://www.python.org/ftp/python/3.8.8/Python-3.8.8.tgz
            tar -zxvf Python-3.8.8.tgz
            cd Python-3.8.8
            ./configure --prefix=/usr/local/python388
            make && make install
            ln -s /usr/local/python388/bin/python3.8 /usr/bin/python38
            ln -s /usr/local/python388/bin/pip3 /usr/bin/pip38
        fi
    else
        echo "不进行 Python3 安装！"
        exit 1
    fi
}


function centos7_yuan(){
    echo "Centos 7 停服手动更换源！"
    cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    cp $DIR_PATH/Linux_config/centos/huawei-CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
    yum clean all
    yum makecache
    echo "已更换镜像源"
}

# 禁 ping 设置
function enjoin_ping() {
    echo ""; echo ""
    echo "####################禁 ping 设置####################"
    if [ "$display" == 'true' ]; then
        echo "桌面端环境，不设置禁 ping！"
    else
        if [ $BT_PARAM == 1 ]; then
                echo "已安装宝塔面板，不进行设置禁 ping，以防止出现冲突！"
            else
                echo -e "\nnet.ipv4.icmp_echo_ignore_all=1\n" >>  /etc/sysctl.conf
                sysctl -p
                echo "设置禁 ping，成功！"
        fi
    fi
}

function init_script_start() {
    echo "In execution init script..."
}


function procedure() {
clear
echo -e "————————————————————————————————————————————————————
  \033[1m       Linux_Init_Script\033[0m
  \033[32m 分步骤初始化进行中，请选择需要初始化的选项......\033[0m
————————————————————————————————————————————————————
1. ◎ 修改时间将 UTC 时间转换为 CST 时间
2. ◎ debian sudo 初始化
3. ◎ docker pull 加速
4. ◎ 更换为国内镜像源
5. ◎ 系统基础软件安装
6. ◎ 替换 bashrc 文件
7. ◎ 修改系统级配置(服务器专用)
8. ◎ 安装 docker 
9. ◎ 安装宝塔面板
10. ◎ 设置虚拟内存(4G)
11. ◎ neofetch 安装
12. ◎ 配置防火墙
13. ◎ Centos 7 停服手动更换源
14. ◎ 服务器设置禁 ping
q. ◎ 退出安装"
sleep 0.2
read -ep  "请输入序号并回车：" num
case $num in
1 ) (date_info);;
2 ) (debian_sudo);;
3 ) (docker_speed);;
4 ) (cn_yuan);;
5 ) (install_base_software);;
6 ) (config_bashrc_procedure);;
7 ) (config_system);;
8 ) (install_docker);;
9 ) (install_bt);;
10 ) (virtual_memory);;
11 ) (neofetch_install);;
12 ) (firewall_install);;
13 ) (centos7_yuan);;
14 ) (enjoin_ping);;
q ) (exit);;
*) (procedure);;
esac
}


function init_all() {
clear
echo -e "————————————————————————————————————————————————————
  \033[1m       Linux_Init_Script\033[0m
  \033[32m   初始化程序正在运行中......\033[0m
————————————————————————————————————————————————————"
date_info
debian_sudo
cn_yuan
install_base_software
config_system
config_bashrc
virtual_memory
sleep 0.2
read -ep  "是否进行安装宝塔面板？(如果安装了宝塔将不会自动安装 docker，会有冲突！) (yes/no): " letter
if [ "$letter" == "yes" ]; then
    install_bt
else
    sleep 0.2
    read -ep  "是否进行安装 Docker？(yes/no): " letter2
    if [ "$letter2" == "yes" ]; then
        FLAG_DOCKER=1
        install_docker
    else
        echo "跳过安装 Docker！"
    fi
fi
firewall_install
enjoin_ping
neofetch_install
}


function system_config() {
clear
echo -e "————————————————————————————————————————————————————
  \033[1m       Linux_Init_Script\033[0m
  \033[32m   初始化程序正在运行中......\033[0m
————————————————————————————————————————————————————"
date_info
debian_sudo
cn_yuan
install_base_software
config_system
config_bashrc
virtual_memory
firewall_install
enjoin_ping
neofetch_install
}

function third_party(){
clear
echo -e "————————————————————————————————————————————————————
  \033[1m       Linux_Init_Script\033[0m
  \033[32m   第三方工具箱使用中......\033[0m
————————————————————————————————————————————————————
1. ◎ 007idc Linux 工具箱
2. ◎ 鱼香 Ros 一键脚本
q. ◎ 退出安装"
sleep 0.2
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (curl -O http://linux.007idc.cn/linux.sh && chmod +x linux.sh && ./linux.sh);;
[2] ) (wget http://fishros.com/install -O fishros && . fishros);;
[q] ) (exit);;
*) (third_party);;
esac
}



function Init(){
clear
export LANG=en_US
if [ "$display" == 'true' ]; then
    env="桌面环境；请谨慎使用一键脚本！"
else
    env="服务器环境！"
fi
echo -e "————————————————————————————————————————————————————
	\033[1m        Linux_Init_Script\033[0m
	\033[32mLinux 一键初始化脚本 ——主菜单-version:test_0.0.5\033[0m
	说明：请使用 root 权限运行此脚本！！！
    检测到当前环境为：$env
————————————————————————————————————————————————————
1. ◎ 完整初始化 Linux (服务器专用)
2. ◎ 只修改系统配置 (服务器专用)
3. ◎ 安装 Docker
4. ◎ 安装宝塔面板 (BT面板)
5. ◎ 分步骤初始化
6. ◎ 安装 Python3.8.8
a. ◎ 第三方在线工具箱
q. ◎ 退出安装"
sleep 0.2
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (init_all);;
[2] ) (system_config);;
[3] ) (install_docker);;
[4] ) (install_bt);;
[5] ) (procedure);;
[6] ) (python3_install);;
[a] ) (third_party);;
[q] ) (exit);;
*) (Init);;
esac
}


Init | tee $RESULTFILE
echo ""
source ~/.bashrc
# sudo chown -R ubuntu:ubuntu $current_script_path


