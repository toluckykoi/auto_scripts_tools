#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-01-04 21:55:33
# @version     : bash
# @Update time :
# @Description : Linux系统初始化脚本程序(系统开荒)


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
        echo "apt: install curl software"
        sudo apt update
        sudo apt install -y curl
        echo "已安装 curl"
    
    elif [ "$software_manager" == "yum" ]; then
        echo "yum: install curl software"
        sudo yum install -y curl
        echo "已安装 curl"
    else
        echo "版本不支持."
        exit 1
    fi
}

#  执行权限确认,避免因权限不足设置失败
[ $(id -u) -gt 0 ] && echo "权限不足,请用root用户执行此脚本,不是root用户请使用 sudo xxx.sh 执行" && exit 1
export LANG=en_US

# 1、什么系统类型的服务器  2、服务器在哪里  3、桌面版还是服务器 4、是否中国时间 5、使用的软件管理器
ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')
VERSION_ID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F '=' '{print $2}' | awk -F '"' '{print $2}')
architecture=$(uname -m)
DIR_PATH=$( cd "$( dirname "$(dirname "$(pwd)")" )" >/dev/null 2>&1 && pwd )
random_char=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)

ORIGINAL_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
USER_HOME_DIR=$(eval echo "~$ORIGINAL_USER")

# 检查架构
case "$(uname -m)" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "暂时不支持的 CPU 架构: $(uname -m)"
        echo "仅支持 x86_64 (AMD64) 和 aarch64 (ARM64)"
        return 1
        ;;
esac

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
[ ! -d "$current_script_path" ] && sudo -u "$(logname)" mkdir -p "$current_script_path"
RESULTFILE="$current_script_path/Linux_Init_Log-`date +%Y%m%d`.txt"
Linux_auto_scripts_path=$(dirname "$(cd "$(dirname "$0")" && pwd)")

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


# sudo初始化：
function debian_sudo(){
    echo ""; echo ""
    if [ "$ID" == "debian" ]; then
        echo "####################sudo 相关配置####################"
        if command -v sudo >/dev/null 2>&1; then
            debian_sudo=sudo
            echo "sudo 已安装."
        else
            echo "未检测到sudo，正在安装....."
            apt install -y sudo
            echo "sudo 安装完成."
        fi

        if [ "$display" == 'true' ]; then
            NORMAL_USER=$(awk -F: '$3 >= 1000 && $1 != "nobody" && $3 < 65534 {print $1; exit}' /etc/passwd)
            if [ -z "$NORMAL_USER" ]; then
                echo "未找到普通用户, 无需配置 sudo."
                exit 1
            fi
            
            su - $NORMAL_USER -c 'sudo -v'
            if [ $? -eq 0 ]; then
                echo "普通用户已有sudo 权限, 无需配置 sudo."
            else
                echo "正在配置普通用户 sudo 权限..."
                # 创建 sudoers 规则文件（Debian/Ubuntu 使用 'sudo' 组，RHEL/CentOS 用 'wheel'）
                # 这里以 Debian/Ubuntu 为例：允许用户执行所有命令，需输密码
                RULE_FILE="/etc/sudoers.d/$NORMAL_USER"

                # 写入规则（使用 here-document + chmod 保证安全）
                cat > "$RULE_FILE" <<EOF
# Grant sudo access to user $NORMAL_USER
$NORMAL_USER ALL=(ALL:ALL) ALL
EOF
                # 必须设置权限为 0440（sudo 要求）
                chmod 440 "$RULE_FILE"

                echo "已授予用户 '$NORMAL_USER' sudo 权限（需输入密码）"
                echo "规则文件: $RULE_FILE"
            fi
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
    sudo cp $DIR_PATH/ConfigFiles/docker/daemon.json /etc/docker/
    echo "加载加速配置文件成功."

    sudo systemctl daemon-reload
    sudo systemctl restart docker
    if [ $? -eq 0 ]; then
        echo "配置 docker 加速源成功."
    else
        echo "异常配置失败."
        exit
    fi
}

# 1、换源
function cn_yuan(){
    echo ""; echo ""
    $Linux_auto_scripts_path/Shell_Scripts_Correlation/change_source_mirror.sh "$server_region"
}

# 2、基础软件安装
function install_base_software() {
    echo ""; echo ""
    echo "####################安装基础软件####################"
    if [ "$software_manager" == "apt" ]; then
        echo "apt: install base software"
        sudo apt update
        sudo DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
        sleep 2
        sudo apt -y install lsb-release net-tools curl wget vim htop git unzip expect acct tar build-essential cmake gdb dos2unix tmux openssh-server gnupg2 ffmpeg
        sudo apt -y install libssl-dev libxcb-xinerama0 libglew-dev libxcb-cursor0 libxcb-cursor-dev ninja-build network-manager
        sudo apt -y install x11-xserver-utils bash-completion
        sudo apt -y install portaudio19-dev python3-pyaudio
        echo "已安装基础软件"
    
    elif [ "$software_manager" == "yum" ]; then
        echo "yum: install base software"
        sudo yum update -y
        sleep 2
        sudo yum -y install net-tools gcc gcc-c++ kernel-devel cmake make curl wget vim git htop unzip psacct expect epel-release tar dos2unix tmux ffmpeg
        sudo yum install -y xset
        sudo yum install -y bash-completion bash-completion-extras
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
        cp $DIR_PATH/ConfigFiles/linux/ubuntu/Ubuntu_user_.bashrc /home/$SHELL_USER/.bashrc
        cp $DIR_PATH/ConfigFiles/linux/ubuntu/Ubuntu_root_.bashrc /root/.bashrc

    elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
        echo "debian cp bashrc"
        cp $DIR_PATH/ConfigFiles/linux/debian/Debian_user_.bashrc /home/$SHELL_USER/.bashrc
        cp $DIR_PATH/ConfigFiles/linux/debian/Debian_root_.bashrc /root/.bashrc

    elif [ $software_manager == "yum" ] && [ $ID == '"centos"' ]; then
        if [ "$VERSION_ID" == "7" ]; then
            echo "centos cp bashrc"
            cp $DIR_PATH/ConfigFiles/linux/centos/Centos_user_.bashrc /home/$SHELL_USER/.bashrc
            cp $DIR_PATH/ConfigFiles/linux/centos/Centos_root_.bashrc /root/.bashrc
            
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
        cp $DIR_PATH/ConfigFiles/linux/ubuntu/Ubuntu_user_.bashrc /home/$BASHRC_USER/.bashrc
        cp $DIR_PATH/ConfigFiles/linux/ubuntu/Ubuntu_root_.bashrc /root/.bashrc

    elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
        echo "debian cp bashrc"
        cp $DIR_PATH/ConfigFiles/linux/debian/Debian_user_.bashrc /home/$BASHRC_USER/.bashrc
        cp $DIR_PATH/ConfigFiles/linux/debian/Debian_root_.bashrc /root/.bashrc

    elif [ "$software_manager" == "yum" ] && [ $ID == '"centos"' ]; then
        if [ $VERSION_ID == 7 ]; then
            echo "centos cp bashrc"
            cp $DIR_PATH/ConfigFiles/linux/centos/Centos_user_.bashrc /home/$BASHRC_USER/.bashrc
            cp $DIR_PATH/ConfigFiles/linux/centos/Centos_root_.bashrc /root/.bashrc
            
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
        echo "桌面系统环境，将为桌面环境进行配置..."

    else
        echo "服务器环境，需要进行以下配置："
        hostnamectl set-hostname "${ID}-${random_char}"
        echo "127.0.0.1 ${ID}-${random_char}" >> /etc/hosts

        # cloud_file_path="/etc/cloud/cloud.cfg"
        # if [ -f "$cloud_file_path" ]; then
        #     echo "文件 $cloud_file_path 存在，删除对应配置！"
        #     sudo rm /etc/cloud/cloud.cfg
        #     echo "指定的行已从配置文件中删除。"
        # else
        #     echo "文件 $cloud_file_path 不存在不需要配置."
        # fi

        if [ "$software_manager" == "apt" ]; then
            echo "debian 系特有配置"
            sudo useradd -m $SHELL_USER -s /bin/bash
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
            sudo useradd $SHELL_USER
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

        # 初始化完用户后创建用户文件存放文件夹
        mkdir -p /home/$SHELL_USER/Documents
        mkdir -p /home/$SHELL_USER/Downloads
        mkdir -p /home/$SHELL_USER/Temp

        sudo chown -R $SHELL_USER:$SHELL_USER /home/$SHELL_USER/Documents
        sudo chown -R $SHELL_USER:$SHELL_USER /home/$SHELL_USER/Downloads
        sudo chown -R $SHELL_USER:$SHELL_USER /home/$SHELL_USER/Temp

        sudo chown -R $SHELL_USER:$SHELL_USER $current_script_path
    fi
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
            sudo yum install -y yum-utils device-mapper-persistent-data lvm2
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
            sudo yum makecache --timer
            sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo service docker start
            sudo systemctl enable docker.service
            
            groupadd docker
            if [ $FLAG_DOCKER == 1 ]; then
                sudo usermod -aG docker $SHELL_USER
            else
                echo "当前执行脚本的用户是：$USER"
                sleep 0.2
                read -ep  "需要输入普通用户用于操作 docker 命令的用户名: " docker_user
                sudo usermod -aG docker $docker_user
            fi

            # newgrp docker
            sudo yum install -y bash-completion

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
    echo ""

    while true; do
        # 版本选择菜单
        echo "========================================"
        echo "         宝塔面板版本选择菜单"
        echo "========================================"
        echo "1) 正式版：11.5.0"
        echo "2) 稳定版：10.0.0"
        echo "--- 历史版本 ---"
        echo "3) 9.6.0（正式版）"
        echo "4) 9.5.0（正式版）"
        echo "5) 9.0.0（稳定版）"
        echo "0) 退出"
        echo "========================================"
        echo -n "请选择版本 [0-5]: "
        read -r choice

        # 根据选择执行对应命令
        case "$choice" in
            1)
                version="11.5.0"
                echo ">>> 正在安装正式版 ${version} ..."
                if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec <<EOF
y
EOF
                break
                ;;
            2)
                version="10.0.0"
                echo ">>> 正在安装稳定版 ${version} ..."
                url=https://download.bt.cn/install/installStable.sh;if [ -f /usr/bin/curl ];then curl -sSO $url;else wget -O installStable.sh $url;fi;bash installStable.sh ed8484bec <<EOF
y
EOF
                break
                ;;
            3)
                version="9.6.0"
                echo ">>> 正在安装正式版 ${version} ..."
                if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_nearest.sh;else wget -O install_nearest.sh https://download.bt.cn/install/install_nearest.sh;fi;bash install_nearest.sh latest960 <<EOF
y
EOF
                break
                ;;
            4)
                version="9.5.0"
                echo ">>> 正在安装正式版 ${version} ..."
                if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_second_nearest.sh;else wget -O install_second_nearest.sh https://download.bt.cn/install/install_second_nearest.sh;fi;bash install_second_nearest.sh latest950 <<EOF
y
EOF
                break
                ;;
            5)
                version="9.0.0"
                echo ">>> 正在安装稳定版 ${version} ..."
                if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_second_nearest.sh;else wget -O install_second_nearest.sh https://download.bt.cn/install/install_second_nearest.sh;fi;bash install_second_nearest.sh latest950 <<EOF
y
EOF
                break
                ;;
            0)
                echo "已退出"
                exit 0
                ;;
            *)
                echo "错误：无效选择，请输入 0-5 之间的数字"
                echo ""
                ;;
        esac
    done

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
        sudo dd if=/dev/zero of=/swapfile bs=256M count=16
        # count的大小就是增加的swap空间的大小，256M是块大小，所以空间大小是bs*count=1024MB
        sudo mkswap /swapfile
        sudo chmod 0600 /swapfile
        sudo swapon /swapfile
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
    sudo cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    sudo cp $DIR_PATH/ConfigFiles/linux/centos/huawei-CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
    sudo yum clean all
    sudo yum makecache
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

function user_dirs_update() {
    if ! command -v xdg-user-dirs-gtk-update &> /dev/null; then
        echo "xdg-user-dirs-gtk-update 未安装，正在安装..."
        
        # 检查发行版类型（主要支持 Debian/Ubuntu 系）
        if [ -f /etc/debian_version ]; then
            sudo apt update
            sudo apt install -y xdg-user-dirs-gtk
        elif [ -f /etc/redhat-release ] || [ -f /etc/fedora-release ] || command -v dnf &> /dev/null; then
            # RHEL / CentOS / Fedora
            if command -v dnf &> /dev/null; then
                sudo dnf install -y xdg-user-dirs-gtk
            else
                sudo yum install -y xdg-user-dirs-gtk
            fi
        elif [ -f /etc/arch-release ]; then
            sudo pacman -Sy --noconfirm xdg-user-dirs-gtk
        else
            echo "未知发行版，请手动安装 'xdg-user-dirs-gtk' 包。"
            exit 1
        fi        
    fi
    
    original_user=$(logname 2>/dev/null || echo "$SUDO_USER")
    home_dir=$(eval echo "~$original_user")

    CONFIG_FILE="$home_dir/.config/user-dirs.dirs"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$CONFIG_FILE 不存在，正在生成默认配置..."
        sudo -u "$original_user" HOME="$home_dir" xdg-user-dirs-update
    fi

    if [ -d "$home_dir/下载" ] || [ -d "$home_dir/文档" ]; then
        echo "用户目录存在中文路径，将修改为英文路径！"
        sudo -u "$original_user" HOME="$home_dir" xdg-user-dirs-gtk-update
        echo "用户目录更新完成."
    else
        echo "用户目录不存在中文路径，无需修改."
    fi
}

function desktop_software_install() {
    echo ""; echo ""
    echo "####################桌面软件安装####################"
    cd /tmp
    if [ "$software_manager" == "apt" ]; then
        echo "使用 apt 包管理器安装桌面软件（架构: $ARCH）..."

        # apt 方式安装
        sudo apt update
        sudo apt install -y gedit

        # deb 包方式安装（vscode/conda）
        if [ "$ARCH" == "amd64" ]; then
            VSCODE_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/code_1.109.4-1771257466_amd64.deb"
            CONDA_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/Miniconda3-latest-Linux-x86_64.sh"
        elif [ "$ARCH" == "arm64" ]; then
            VSCODE_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/code_1.109.4-1771257672_arm64.deb"
            CONDA_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/Miniconda3-latest-Linux-aarch64.sh"
        fi

        echo "正在下载 VSCode ($ARCH)..."
        if wget -q -O vscode.deb "$VSCODE_URL"; then
            echo "VSCode 下载成功，正在安装..."
            sudo DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends ./vscode.deb
            rm -f ./vscode.deb
            echo "VSCode 安装完成！"

            sleep 2
            echo "正在安装 VSCode 常用插件..."

            # 获取原始用户
            original_user=$(logname 2>/dev/null || echo "$SUDO_USER")
            home_dir=$(eval echo "~$original_user")
            USER_DATA_DIR="$home_dir/.vscode"

            # 插件列表
            extensions=(
                "MS-CEINTL.vscode-language-pack-zh-hans"
                "ms-python.python"
                "ms-python.vscode-pylance"
                "ms-python.debugpy"
                "ms-python.vscode-python-envs"
                "ms-vscode.cpptools"
                "franneck94.c-cpp-runner"
                "twxs.cmake"
                "ms-vscode.cmake-tools"
                "Alibaba-Cloud.tongyi-lingma"
                "mhutchie.git-graph"
                "techer.open-in-browser"
                "redhat.vscode-xml"
                "redhat.vscode-yaml"
                "formulahendry.code-runner"
            )

            for ext in "${extensions[@]}"; do
                echo "→ 安装插件: $ext"
                sudo -u "$original_user" HOME="$home_dir" \
                    XDG_CONFIG_HOME="$home_dir/.config" \
                    code --user-data-dir="$USER_DATA_DIR" --install-extension "$ext" --force
            done
        else
            echo "VSCode 下载失败，请检查网络或 URL。"
        fi

        echo "正在下载 conda..."
        wget -q -O conda.sh "$CONDA_URL"
        echo "conda 下载成功，正在安装..."
        chmod +x ./conda.sh
        sudo -u "$original_user" HOME="$home_dir" ./conda.sh -b -p "$home_dir/miniconda3"
        rm -f ./conda.sh

        # conda 配置
        echo "正在配置 conda..."
        BASHRC="$USER_HOME_DIR/.bashrc"
        CONDA_PATH="${USER_HOME_DIR}/miniconda3"

        if grep -q "conda initialize" "$BASHRC"; then
            echo "✓ .bashrc 已包含 conda initialize"
        
        else
            echo "✗ .bashrc 未检测到 conda initialize，正在添加..."

            CONDA_INIT_CODE=$(cat <<'EOF'
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$CONDA_PATH/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]; then
        . "$CONDA_PATH/etc/profile.d/conda.sh"
    else
        export PATH="$CONDA_PATH/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
EOF
)
            CONDA_INIT_CODE="${CONDA_INIT_CODE//\$CONDA_PATH/$CONDA_PATH}"

            # 添加到.bashrc末尾
            echo "" >> "$BASHRC"
            echo "$CONDA_INIT_CODE" >> "$BASHRC"
            echo "" >> "$BASHRC"
            echo "" >> "$BASHRC"

            echo "✓ conda initialize 已添加到 $BASHRC"
        fi

    elif [ "$software_manager" == "yum" ]; then
        echo "使用 yum 安装桌面软件（架构: $ARCH）..."

        # yum 方式安装
        sudo yum update
        sudo yum install -y gedit

        # rpm 包方式安装
         if [ "$ARCH" == "amd64" ]; then
            VSCODE_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/code-1.109.4-1771257509.el8.x86_64.rpm"
            CONDA_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/Miniconda3-latest-Linux-x86_64.sh"
        elif [ "$ARCH" == "arm64" ]; then
            VSCODE_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/code-1.109.4-1771257718.el8.aarch64.rpm"
            CONDA_URL="http://web.808066.xyz:200/d/Linux_software/%E7%BC%96%E7%A8%8B_%E5%BC%80%E5%8F%91%E8%BD%AF%E4%BB%B6/Miniconda3-latest-Linux-aarch64.sh"
        fi

        echo "正在下载 VSCode ($ARCH)..."
        if wget -q -O vscode.rpm "$VSCODE_URL"; then
            echo "VSCode 下载成功，正在安装..."
            sudo yum localinstall -y ./vscode.rpm
            rm -f ./vscode.rpm
            echo "VSCode 安装完成！"

            sleep 2
            echo "正在安装 VSCode 常用插件..."

            # 获取原始用户
            original_user=$(logname 2>/dev/null || echo "$SUDO_USER")
            home_dir=$(eval echo "~$original_user")
            USER_DATA_DIR="$home_dir/.vscode"

            # 插件列表
            extensions=(
                "MS-CEINTL.vscode-language-pack-zh-hans"
                "ms-python.python"
                "ms-python.vscode-pylance"
                "ms-python.debugpy"
                "ms-python.vscode-python-envs"
                "ms-vscode.cpptools"
                "franneck94.c-cpp-runner"
                "twxs.cmake"
                "ms-vscode.cmake-tools"
                "Alibaba-Cloud.tongyi-lingma"
                "mhutchie.git-graph"
                "techer.open-in-browser"
                "redhat.vscode-xml"
                "redhat.vscode-yaml"
                "formulahendry.code-runner"
            )

            for ext in "${extensions[@]}"; do
                echo "→ 安装插件: $ext"
                sudo -u "$original_user" HOME="$home_dir" \
                    XDG_CONFIG_HOME="$home_dir/.config" \
                    code --user-data-dir="$USER_DATA_DIR" --install-extension "$ext" --force
            done
        else
            echo "VSCode 下载失败，请检查网络或 URL。"
        fi

        echo "正在下载 conda..."
        wget -q -O conda.sh "$CONDA_URL"
        echo "conda 下载成功，正在安装..."
        chmod +x ./conda.sh
        sudo -u "$original_user" HOME="$home_dir" ./conda.sh -b -p "$home_dir/miniconda3"
        rm -f ./conda.sh

        # conda 配置
        echo "正在配置 conda..."
        BASHRC="$USER_HOME_DIR/.bashrc"
        CONDA_PATH="${USER_HOME_DIR}/miniconda3"

        if grep -q "conda initialize" "$BASHRC"; then
            echo "✓ .bashrc 已包含 conda initialize"
        
        else
            echo "✗ .bashrc 未检测到 conda initialize，正在添加..."

            CONDA_INIT_CODE=$(cat <<'EOF'
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$CONDA_PATH/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$CONDA_PATH/etc/profile.d/conda.sh" ]; then
        . "$CONDA_PATH/etc/profile.d/conda.sh"
    else
        export PATH="$CONDA_PATH/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
EOF
)
            CONDA_INIT_CODE="${CONDA_INIT_CODE//\$CONDA_PATH/$CONDA_PATH}"

            # 添加到.bashrc末尾
            echo "" >> "$BASHRC"
            echo "$CONDA_INIT_CODE" >> "$BASHRC"
            echo "" >> "$BASHRC"
            echo "" >> "$BASHRC"

            echo "✓ conda initialize 已添加到 $BASHRC"
        fi

        echo "桌面端软件安装完成."

    else
        echo "该 Linux 系统软件安装方式适配中..."
    fi
}


function procedure() {
    while true; do
        clear
        echo -e "————————————————————————————————————————————————————"
        echo -e "  \033[1m       Linux_Init_Script\033[0m"
        echo -e "  \033[32m 分步骤初始化进行中，请选择需要初始化的选项......\033[0m"
        echo -e "————————————————————————————————————————————————————"
        echo " 1. ◎ 修改时间：UTC → CST"
        echo " 2. ◎ Debian sudo 初始化"
        echo " 3. ◎ Docker pull 加速配置"
        echo " 4. ◎ 更换系统镜像源（国内/国外自动判断）"
        echo " 5. ◎ 安装基础软件包"
        echo " 6. ◎ 替换指定用户的 .bashrc 配置"
        echo " 7. ◎ 修改系统级配置（仅服务器）"
        echo " 8. ◎ 安装 Docker 容器"
        echo " 9. ◎ 安装宝塔面板（BT）"
        echo "10. ◎ 设置 4GB 虚拟内存（swap）"
        echo "11. ◎ 安装 neofetch（系统信息展示）"
        echo "12. ◎ 配置防火墙（开放 32200 端口）"
        echo "13. ◎ CentOS 7 停服后手动换源"
        echo "14. ◎ 服务器启用禁 ping"
        echo " q. ◎ 返回主菜单 / 退出"
        echo -e "————————————————————————————————————————————————————"
        
        sleep 0.5
        read -ep "请选择操作编号 [1-14 或 q]: " num

        case "$num" in
            1)  date_info ;;
            2)  debian_sudo ;;
            3)  docker_speed ;;
            4)  cn_yuan ;;
            5)  install_base_software ;;
            6)  config_bashrc_procedure ;;
            7)  config_system ;;
            8)  install_docker ;;
            9)  install_bt ;;
            10) virtual_memory ;;
            11) neofetch_install ;;
            12) firewall_install ;;
            13) centos7_yuan ;;
            14) enjoin_ping ;;
            q|Q) 
                echo "已退出分步初始化模式。"
                return 0
                ;;
            *)
                echo "无效选项：'$num'，请重新选择。"
                sleep 1
                ;;
        esac

        break
    done
}

function init_all() {
    clear
    echo -e "————————————————————————————————————————————————————"
    echo -e "  \033[1m       Linux_Init_Script\033[0m"
    echo -e "  \033[32m   完整初始化（服务器专用）即将执行以下操作：\033[0m"
    echo -e "————————————————————————————————————————————————————"
    echo "  1. 将系统时间设为 CST（如需）"
    echo "  2. 初始化 Debian 系统的 sudo 配置（如适用）"
    echo "  3. 更换软件源为国内镜像（根据 IP 自动判断）"
    echo "  4. 安装基础软件包（vim/git/tmux/openssh-server 等）"
    echo "  5. 创建新用户并配置 SSH（禁用 root 登录，改用 32200 端口）"
    echo "  6. 替换 .bashrc 配置文件"
    echo "  7. 设置 4GB 虚拟内存（若未启用 swap）"
    echo "  8. 询问是否安装宝塔面板或 Docker"
    echo "  9. 配置防火墙（安装了宝塔不自动配置）"
    echo " 10. 启用禁 ping（提升安全性）"
    echo " 11. 安装 neofetch 展示系统信息"
    echo -e "————————————————————————————————————————————————————"

    sleep 0.5
    while true; do
        echo -n "是否确认执行完整服务器初始化？(yes/no): "
        read confirm
        case "${confirm,,}" in
            yes|y)
                break
                ;;
            no|n)
                echo "已取消完整初始化。"
                return 0
                ;;
            "")
                echo "输入不能为空，请输入 yes 或 no。"
                ;;
            *)
                echo "无效输入，请输入 yes 或 no。"
                ;;
        esac
    done

    # ========== 正式开始执行 ==========
    date_info
    debian_sudo
    cn_yuan
    install_base_software
    config_system
    config_bashrc
    virtual_memory

    sleep 0.2
    read -ep "是否进行安装宝塔面板？(如果安装了宝塔将不会自动安装 docker，会有冲突！) (yes/no): " letter
    if [ "$letter" == "yes" ]; then
        install_bt
    else
        sleep 0.2
        read -ep "是否进行安装 Docker？(yes/no): " letter2
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

function desktop_init(){
    clear
    echo -e "————————————————————————————————————————————————————"
    echo -e "  \033[1m       Linux_Init_Script\033[0m"
    echo -e "  \033[32m   桌面初始化程序即将执行以下操作：\033[0m"
    echo -e "————————————————————————————————————————————————————"
    echo "  1. 更新用户目录（如将“下载”改为“Downloads”等）"
    echo "  2. 更换系统软件源为国内镜像（自动判断是否需要进行更换）"
    echo "  3. 安装基础软件包（如 vim\git\unzip\wget 等）"
    echo "  4. 更新 .bashrc 配置（需手动输入目标用户名）"
    echo "  5. 安装常用桌面软件（如 gedit\vscode\conda 等）"
    echo "  6. 安装 neofetch（系统信息最后展示）"
    echo -e "————————————————————————————————————————————————————"

    sleep 0.5
    while true; do
        echo -n "是否确认执行以上桌面初始化操作？(yes/no): "
        read confirm
        case "${confirm,,}" in
            yes|y)
                break
                ;;
            no|n)
                echo "已取消桌面初始化。"
                return 0
                ;;
            "")
                echo "输入不能为空，请输入 yes 或 no。"
                ;;
            *)
                echo "无效输入，请输入 yes 或 no。"
                ;;
        esac
    done

    export LANG=en_US
    user_dirs_update
    cn_yuan
    install_base_software
    config_bashrc_procedure
    desktop_software_install
    neofetch_install
}

function system_config() {
    clear
    echo -e "————————————————————————————————————————————————————"
    echo -e "  \033[1m       Linux_Init_Script\033[0m"
    echo -e "  \033[32m   仅系统配置（服务器专用）即将执行以下操作：\033[0m"
    echo -e "————————————————————————————————————————————————————"
    echo "  1. 设置系统时区为 CST（如需）"
    echo "  2. 初始化 Debian 的 sudo 配置（如适用）"
    echo "  3. 更换软件源为国内镜像"
    echo "  4. 安装基础软件包"
    echo "  5. 创建新用户并加固 SSH（禁用 root 登录，端口改为 32200）"
    echo "  6. 替换 .bashrc 配置"
    echo "  7. 设置 4GB 虚拟内存（若未启用 swap）"
    echo "  8. 配置防火墙（开放 32200 端口）"
    echo "  9. 启用禁 ping"
    echo " 10. 安装 neofetch"
    echo -e "————————————————————————————————————————————————————"

    sleep 0.5
    while true; do
        echo -n "是否确认执行上述系统配置？(yes/no): "
        read confirm
        case "${confirm,,}" in
            yes|y)
                break
                ;;
            no|n)
                echo "已取消系统配置。"
                return 0
                ;;
            "")
                echo "输入不能为空，请输入 yes 或 no。"
                ;;
            *)
                echo "无效输入，请输入 yes 或 no。"
                ;;
        esac
    done

    # ========== 正式执行 ==========
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

function third_party() {
    while true; do
        clear
        echo -e "————————————————————————————————————————————————————"
        echo -e "  \033[1m       Linux_Init_Script\033[0m"
        echo -e "  \033[32m         第三方工具箱\033[0m"
        echo -e "————————————————————————————————————————————————————"
        echo " 1. ◎ 007idc Linux 工具箱"
        echo " 2. ◎ 鱼香 ROS 一键安装脚本"
        echo " q. ◎ 返回主菜单"
        echo -e "————————————————————————————————————————————————————"

        sleep 0.5
        read -ep "请选择工具编号 [1-2 或 q]: " num
        case "$num" in
            1)
                echo "正在下载并运行 007idc Linux 工具箱..."
                if curl -O http://linux.007idc.cn/linux.sh && chmod +x linux.sh; then
                    ./linux.sh
                else
                    echo "❌ 下载 007idc 工具箱失败，请检查网络或 URL。"
                fi
                ;;
            2)
                echo "正在下载并运行 鱼香 ROS 一键脚本..."
                if wget -q -O fishros http://fishros.com/install; then
                    chmod +x fishros
                    . ./fishros
                else
                    echo "❌ 下载 鱼香 ROS 脚本失败，请检查网络或 URL。"
                fi
                ;;
            q|Q)
                echo "已退出第三方工具箱。"
                return 0
                ;;
            *)
                echo "无效选项：'$num'，请重新选择。"
                sleep 1
                continue
                ;;
        esac

        break
    done
}


function Init() {
    while true; do
        clear
        export LANG=en_US

        if [ "$display" == 'true' ]; then
            env="桌面环境；请谨慎使用一键脚本！"
        else
            env="服务器环境！"
        fi

        echo -e "————————————————————————————————————————————————————"
        echo -e "        \033[1mLinux_Init_Script\033[0m"
        echo -e "  \033[32mLinux 一键初始化脚本 —— 主菜单 (v0.0.5)\033[0m"
        echo -e "  说明：请使用 root 权限运行此脚本！！！"
        echo -e "  检测到当前环境为：$env"
        echo -e "————————————————————————————————————————————————————"
        echo " 1. ◎ 完整初始化 Linux（服务器专用）"
        echo " 2. ◎ 仅修改系统配置（服务器专用）"
        echo " 3. ◎ 初始化 Linux 桌面版（带 GUI 系统）"
        echo " 4. ◎ 安装 Docker 容器"
        echo " 5. ◎ 安装宝塔面板（BT）"
        echo " 6. ◎ 分步骤执行初始化"
        echo " 7. ◎ 安装 Python 3.8.8（编译安装）"
        echo " a. ◎ 第三方在线工具箱"
        echo " q. ◎ 退出脚本"
        echo -e "————————————————————————————————————————————————————"

        sleep 0.5
        read -ep "请选择操作编号 [1-7, a 或 q]: " num

        case "$num" in
            1) init_all; break ;; 
            2) system_config; break ;;
            3) desktop_init; break ;;
            4) install_docker; break ;;
            5) install_bt; break ;;
            6) procedure; break ;;
            7) python3_install; break ;;
            a|A) third_party; break ;;
            q|Q)
                echo "感谢使用 Linux 一键初始化脚本，再见！"
                exit 0
                ;;
            *)
                echo "无效选项：'$num'，请重新选择。"
                sleep 1
                ;;
        esac

        echo ""
    done
}


Init | sudo -u "$(logname)" tee $RESULTFILE
echo ""
source ~/.bashrc
echo "系统配置完成，如修改过太多配置建议重启一次系统使配置更好生效！"
# sudo chown -R ubuntu:ubuntu $current_script_path
