#!/bin/bash
# @Author: 幸运的锦鲤
# @Date:   2024-10-26 16:44:06
# @Last Modified time: 
# ROS 合集安装脚本(目前仅处理Ubuntu系统安装ROS，包含ROS1、ROS2的安装)


[ $(id -u) -gt 0 ] && echo "Ubuntu 请使用 sudo ./install_ros.sh 执行此脚本！" && exit 1
export LANG=en_US


# 1.系统环境初始化
init_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
init_script_dir="$(dirname "$init_script_dir")"
echo "The Init Script Dir is: $init_script_dir"

source "$init_script_dir/Linux_auto_scripts/System_Init_Scripts/linux_init_script.sh" > /dev/null <<EOF
q
EOF
init_script_start
cn_yuan
install_base_software
if [ $? -eq 0 ];then
    clear
    echo "Ubuntu系统环境初始化完成."
else
    echo "系统环境初始化过程出现问题，请手动检查！！！"
    exit 1
fi

# 2.Ubuntu 系统环境检查
sys_machine=$(uname -m)
sys_id=$(lsb_release -i | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')
sys_version=$(lsb_release -d | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')
sys_release=$(lsb_release -r | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')
sys_codename=$(lsb_release -c | awk -F ':' '{print $2}' | sed 's/^[[:space:]]*//')

echo "正检查当前系统是否符合安装ROS，当前Linux发行版为：$sys_id"
if [ "$sys_id" == "Ubuntu" ]; then
    echo "该系统支持一键安装ROS，当前系统架构为：$sys_machine，当前系统版本为：$sys_version，版本代号为：$sys_codename"
else
    echo "该系统暂不支持一键脚本安装ROS！！！"
    echo "退出."
    exit 1
fi

echo "安装前环境检查："
if [ "$sys_release" == "16.04" ]; then
    echo "当前 $sys_id 版本为：$sys_release，支持安装 ROS1 kinetic 版本(请注意ROS1和ROS2区别)"
    rosversion="kinetic"
elif [ "$sys_release" == "18.04" ]; then
    echo "当前 $sys_id 版本为：$sys_release，支持安装 ROS1 melodic 版本(请注意ROS1和ROS2区别)"
    rosversion="melodic"
elif [ "$sys_release" == "20.04" ]; then
    echo "当前 $sys_id 版本为：$sys_release，支持安装 ROS1 noetic 和 ROS2 foxy/galactic 版本(请注意ROS1和ROS2区别)"
    rosversion="noetic"
    ros2version="galactic"
elif [ "$sys_release" == "22.04" ]; then
    echo "当前 $sys_id 版本为：$sys_release，支持安装 ROS2 humble 版本(请注意ROS1和ROS2区别)"
    ros2version="humble"
elif [ "$sys_release" == "24.04" ]; then
    echo "当前 $sys_id 版本为：$sys_release，支持安装 ROS2 noetic 版本(请注意ROS1和ROS2区别)"

fi

# 指定要检查的目录（检查当前系统用户文件夹数量）
sys_home_dir=$(find "/home" -maxdepth 1 -type d ! -name '.' ! -name '..')
count=$(echo "$sys_home_dir" | wc -l)
home_dir_count=$((count - 1))
home_directory=$(echo "$sys_home_dir" | head -n 2 | tail -n 1)
home_dir=$(echo "$sys_home_dir" | tail -n $home_dir_count)


# 3.ROS 环境初始化 4.安装 ROS
function ros1_install(){
    echo "ROS1安装中..."
    echo "deb https://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ $sys_codename main" | sudo tee /etc/apt/sources.list.d/ros-latest.list
    sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
    sudo apt update
    if [ ! -d "/opt/ros/$rosversion" ]; then
        echo "Not found /opt/ros/$rosversion"
        sudo apt install -y ros-$rosversion-desktop-full

        if [ $? -eq 0 ]; then echo "ROS安装完成."; else echo "ROS 安装过程出现问题，请手动检查！！！" && exit 1; fi
        echo "ROS 环境需要加入 bashrc."
        add_bashrc $rosversion

    else
        echo "已经存在ROS环境，不重复安装."
        exit 1
    fi

    # 5.ROS 预设环境
    ros_env_create $rosversion
    
}

function ros2_install(){
    ros2version=$1
    echo "ROS2版本：$ros2version"
    echo "ROS2安装中..."
    sudo cp $init_script_dir/Ros_Correlation/Ros2_GPG_key/ros.key /usr/share/keyrings/ros-archive-keyring.gpg
    if [ $? -eq 0 ];then
        echo "添加 ROS 2 GPG 密钥成功"
    else
        echo "添加 ROS 2 GPG 密钥失败，更换密钥文件！"
        sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key  -o /usr/share/keyrings/ros-archive-keyring.gpg
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/ros2/ubuntu $sys_codename main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null
    sudo apt update
    if [ $? -eq 0 ]; then echo "sudo apt update."; else echo "添加 ROS 2 GPG 密钥失败，请手动检查！！！" && exit 1; fi
    if [ ! -d "/opt/ros/$ros2version" ]; then
        echo "Not found /opt/ros/$ros2version"
        sudo apt install -y ros-$ros2version-desktop-full
        sudo apt install -y ros-dev-tools

        if [ $? -eq 0 ]; then echo "ROS安装完成."; else echo "ROS 安装过程出现问题，请手动检查！！！" && exit 1; fi
        echo "ROS 环境需要加入 bashrc."
        add_bashrc $ros2version

    else
        echo "已经存在ROS环境，不重复安装."
        exit 1
    fi

    ros_env_create $ros2version

}


function one_install(){
    echo "一键自动安装ROS"
    ROS_VERSION=$1
    if [ "$ROS_VERSION" == "ROS1" ] && [ $(echo "$sys_release <= 20.04" | bc) -eq 1 ]; then
        ros1_install
    elif [ "$ROS_VERSION" == "ROS2" ] && [ $(echo "$sys_release >= 20.04" | bc) -eq 1 ]; then
        ros2_install $ros2version
    else
        echo "参数错误."
        exit 1
    fi

    echo "一键自动安装ROS完成！"
    echo "当前系统架构为：$sys_machine，系统版本为：$sys_version，版本代号为：$sys_codename，安装的ROS版本：$rosversion"
    echo "请重启终端，以生效."
    sudo rm -rf $sys_user_dir/.ros
}

function install_manually(){
echo "手动安装ROS"
echo "
1. ◎ 安装ROS2 Foxy 版本
q. ◎ 退出安装"
sleep 0.1
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (ros2_install "foxy");;
[q] ) (exit);;
*) (clear; start_install);;
esac
}

function add_bashrc(){
    echo "添加bashrc"
    ros_version=$1

    if [ "$home_dir_count" -ge "2" ]; then
        echo "检测到当前系统存在多个用户，当前用户数量：$home_dir_count"
        echo "$home_dir"
        read -ep  "请输入当前使用的用户目录(例如:/home/ubuntu)：" ros_bashrc
        sys_user_dir=$ros_bashrc
        echo "" >> "$sys_user_dir/.bashrc"
        echo "" >> "$sys_user_dir/.bashrc"
        echo "# ROS Env" >> "$sys_user_dir/.bashrc"
        echo "source /opt/ros/$ros_version/setup.bash" >> "$sys_user_dir/.bashrc"
        echo "" >> "$sys_user_dir/.bashrc"
    else
        echo "ROS环境写入默认用户中..."
        sys_user_dir=$home_directory
        echo "" >> "$sys_user_dir/.bashrc"
        echo "" >> "$sys_user_dir/.bashrc"
        echo "# ROS Env" >> "$sys_user_dir/.bashrc"
        echo "source /opt/ros/$ros_version/setup.bash" >> "$sys_user_dir/.bashrc"
        echo "" >> "$sys_user_dir/.bashrc"
    fi
}

function ros_env_create(){
    echo "ROS 预设环境"
    ros_version=$1

    if [ "$ros_version" == "kinetic" ] || [ "$ros_version" == "melodic" ]; then
        echo "ROS version is either kinetic or melodic."
        sudo apt install -y python-rosdep python-rosinstall python-rosinstall-generator python-wstool
    else
        sudo apt install -y python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool python3-vcstool python3-setuptools python3-pytest-cov 
    fi

    # ROS Distro
    # 手动模拟 rosdep init
    sudo mkdir -p /etc/ros/rosdep/sources.list.d/
    sudo cp $init_script_dir/Ros_Correlation/Ros_Distro/20-default.list /etc/ros/rosdep/sources.list.d/

    # 为 rosdep update 换源
    echo "" >> "$sys_user_dir/.bashrc"
    echo "# ROS Distro" >> "$sys_user_dir/.bashrc"
    echo "export ROSDISTRO_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/rosdistro/index-v4.yaml" >> "$sys_user_dir/.bashrc"
    echo "" >> "$sys_user_dir/.bashrc"
    echo "" >> "$sys_user_dir/.bashrc"

    echo "rosdep init done!"
    if [ $? -eq 0 ]; then echo "ROS Distro初始化完成."; else echo "ROS Distro初始化过程出现问题，请手动检查！！！" && exit 1; fi

    # 常用依赖包
    read -ep  "是否安装ROS基础依赖？(yes/no): " letter
    if [ "$letter" == "yes" ]; then
        echo "ROS基础依赖安装中..."
        source /opt/ros/$ros_version/setup.bash
        $init_script_dir/Ros_Correlation/install_add_pkgs.sh
    else
        echo "跳过安装ROS基础依赖."
    fi

}


function start_install(){
echo -e "————————————————————————————————————————————————————
  \033[1m       ROS_Install_Script\033[0m
  \033[32m   ROS环境安装脚本执行中......\033[0m
  \033[31m   请注意ROS1和ROS2区别！！！\033[0m
————————————————————————————————————————————————————
1. ◎ 一键自动安装ROS1
2. ◎ 一键自动安装ROS2
3. ◎ 手动安装ROS
q. ◎ 退出安装"
sleep 0.1
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (one_install "ROS1");;
[2] ) (one_install "ROS2");;
[3] ) (install_manually);;
[q] ) (exit);;
*) (clear; start_install);;
esac
}


start_install

