#!/bin/bash
# @Author: 蓝陌
# @Date:   2023-07-25 10:30:35
# @Last Modified time:
# 安装 ROS 脚本

function install_ros_noetic() {
    ########################## noetic 安装 #########################
    echo "1.使用国内源"
    echo "2.国外源"
    read -p "请选择安装的版本：" ros_source
    if [ $ros_source -eq 1 ]; then
      # 国内源
      gpg --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
      gpg --export C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 | sudo tee /usr/share/keyrings/ros.gpg > /dev/null
      sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/ros.gpg] https://mirrors.ustc.edu.cn/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    elif [ $ros_source -eq 2 ]; then
      # 国外源
      # 设置源列表
      sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
      # 设置密钥
      sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
    fi

    if [ $? -eq 0 ]; then
      echo "上一条命令执行成功"

    else
      echo "上一条命令执行失败,将重新执行"
      curl -s http://git.lanmo.link:38000/https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
    fi

    # 安装
    sudo apt update

    echo "1.桌面完整安装（推荐）"
    echo "2.桌面版安装"
    echo "3.最小安装"
    read -p "请选择安装的版本：" install_ros
    if [ $install_ros -eq 1 ]; then
      # 桌面完整安装：（推荐）：桌面中的所有内容以及 2D/3D 模拟器和 2D/3D 感知包
      sudo apt -y install ros-noetic-desktop-full
    elif [ $install_ros -eq 2 ]; then
      # 桌面安装： ROS-Base 中的所有内容以及 rqt 和 rviz 等工具。
      sudo apt -y install ros-noetic-desktop
    elif [ $install_ros -eq 3 ]; then
      # ROS底座：（裸骨）ROS 打包、构建和通信库。没有图形用户界面工具。
      sudo apt -y install ros-noetic-ros-base
    fi

    # 环境设置
    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc


    read -p "是否初始化(yes/no)：" init_ros
    if [ "$init_ros" == "yes" ]; then
      # 用于生成包的依赖项
      sudo apt install python3-rosdep python3-rosinstall python3-rosinstall-generator python3-wstool build-essential
      # 初始化 rosdep
      sudo apt install python3-rosdep
      sudo rosdep init

      if [ $? -eq 0 ]; then
        echo "上一条命令执行成功"
        rosdep update
      else
        echo "上一条命令执行失败,将重新执行"
        sudo apt install python3-pip
        sudo pip install rosdepc
        sudo rosdepc init
        sudo rosdepc update
      fi
    fi
    ################################################################
}

function install_ros_Melodic() {
    ########################## Melodic 安装 #########################
    echo "1.使用国内源"
    echo "2.国外源"
    read -p "请选择安装的版本：" ros_source
    if [ $ros_source -eq 1 ]; then
      # 国内源
      gpg --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
      gpg --export C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 | sudo tee /usr/share/keyrings/ros.gpg > /dev/null
      sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/ros.gpg] https://mirrors.ustc.edu.cn/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    elif [ $ros_source -eq 2 ]; then
      # 国外源
      # 设置源列表
      sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
      # 设置密钥
      sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
    fi

    if [ $? -eq 0 ]; then
      echo "上一条命令执行成功"

    else
      echo "上一条命令执行失败,将重新执行"
      sudo apt install curl
      curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | sudo apt-key add -
    fi

    # 安装
    sudo apt update

    echo "1.桌面完整安装（推荐）"
    echo "2.桌面版安装"
    echo "3.最小安装"
    read -p "请选择安装的版本：" install_ros_Melodic
    if [ $install_ros_Melodic -eq 1 ]; then
      # 桌面完整安装：（推荐）：桌面中的所有内容以及 2D/3D 模拟器和 2D/3D 感知包
      sudo apt -y install ros-melodic-desktop-full
    elif [ $install_ros_Melodic -eq 2 ]; then
      # 桌面安装： ROS-Base 中的所有内容以及 rqt 和 rviz 等工具。
      sudo apt -y install ros-melodic-desktop
    elif [ $install_ros_Melodic -eq 3 ]; then
      # ROS底座：（裸骨）ROS 打包、构建和通信库。没有图形用户界面工具。
      sudo apt -y install ros-melodic-ros-base
    fi

    # 环境设置
    echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc


    read -p "是否初始化(yes/no)：" init_ros_Melodic
    if [ "$init_ros_Melodic" == "yes" ]; then
      # 用于生成包的依赖项
      sudo apt-get install python-rosinstall python-rosinstall-generator python-wstool build-essential
      sudo apt install python3-rosdep
      sudo rosdep init

      if [ $? -eq 0 ]; then
        echo "上一条命令执行成功"
        rosdep update

      else
        echo "上一条命令执行失败,将重新执行"
        sudo apt install python3-pip
        pip3 install rosdepc
        sudo rosdepc init
        rosdepc update
      fi
    fi
    ################################################################
}


function install_ros_Kinetic () {
    ########################## Kinetic  安装 #########################
    # 设置源列表
    sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    # 设置密钥
    sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654


    if [ $? -eq 0 ]; then
      echo "上一条命令执行成功"

    else
      echo "上一条命令执行失败,将重新执行"
      sudo apt install curl
      curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | sudo apt-key add -
    fi

    # 安装
    sudo apt update

    echo "1.桌面完整安装（推荐）"
    echo "2.桌面版安装"
    echo "3.最小安装"
    read -p "请选择安装的版本：" install_ros_Kinetic
    if [ $install_ros_Kinetic -eq 1 ]; then
      # 桌面完整版: (推荐) : 包含ROS、rqt、rviz、机器人通用库、2D/3D 模拟器、导航以及2D/3D感知
      sudo apt-get -y install ros-kinetic-desktop-full
    elif [ $install_ros_Kinetic -eq 2 ]; then
      # 桌面版安装: 包含ROS、rqt、rviz以及通用机器人函数库。
      sudo apt-get -y install ros-kinetic-desktop
    elif [ $install_ros_Kinetic -eq 3 ]; then
      # 基础版安装: (简版) 包含ROS核心软件包、构建工具以及通信相关的程序库，无GUI工具。
      sudo apt-get -y install ros-kinetic-ros-base
    fi

    # 环境设置
    echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc

    # 初始化 rosdep
    echo "因国外源限制，暂时无法进行初始化。。。。。"
#    read -p "是否初始化(yes/no)：" init_ros_Kinetic
#    if [ "$init_ros_Kinetic" == "yes" ]; then
#      # 用于生成包的依赖项
#      sudo apt-get -y install python-rosinstall python-rosinstall-generator python-wstool build-essential
#      sudo rosdep init
#
#      if [ $? -eq 0 ]; then
#        echo "上一条命令执行成功"
#        rosdep update
#
#      else
#        echo "上一条命令执行失败,将重新执行"
#        sudo apt install python3-pip
#        sudo apt install python3-rosdep
#        pip install rosdepc
#        sudo rosdepc init
#        rosdepc update
#      fi
#    fi
    ################################################################
}


function install_ros_humble () {
    ########################## humble  安装 #########################
    # 确保启用了 Ubuntu Universe 存储库
    sudo apt install software-properties-common
    sudo add-apt-repository universe

    # 添加带有 apt 的 ROS 2 GPG 密钥
    sudo apt update && sudo apt install curl -y
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    if [ $? -eq 0 ]; then
      echo "上一条命令执行成功"
    else
      echo "上一条命令执行失败,将重新执行"
      sudo curl -sSL http://git.lanmo.link:38000/https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    fi

    # 将存储库添加到源列表中
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    sudo apt update
    sudo apt upgrade

    echo "1.桌面完整安装（推荐）"
    echo "2.ROS 基本安装"
    read -p "请选择安装的版本：" install_ros_humble
    if [ $install_ros_humble -eq 1 ]; then
      # 桌面安装（推荐）：ROS，RViz，演示，教程。
      sudo apt -y install ros-humble-desktop
    elif [ $install_ros_humble -eq 2 ]; then
      # ROS 基本安装（裸骨）：通信库、消息包、命令行工具。 没有图形用户界面工具。
      sudo apt -y install ros-humble-ros-base
    fi

    # 开发工具：用于构建 ROS 包的编译器和其他工具
    sudo apt install ros-dev-tools

    # 环境设置
    echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

    # 初始化 rosdep
    echo "因国外源限制，暂时无法进行初始化。。。。。"
#    read -p "是否初始化(yes/no)：" init_ros_Kinetic
#    if [ "$init_ros_Kinetic" == "yes" ]; then
#      # 用于生成包的依赖项
#      sudo apt-get -y install python-rosinstall python-rosinstall-generator python-wstool build-essential
#      sudo rosdep init
#
#      if [ $? -eq 0 ]; then
#        echo "上一条命令执行成功"
#        rosdep update
#
#      else
#        echo "上一条命令执行失败,将重新执行"
#        sudo apt install python3-pip
#        sudo apt install python3-rosdep
#        pip install rosdepc
#        sudo rosdepc init
#        rosdepc update
#      fi
#    fi
    ################################################################
}


function Install_Ros(){
clear
echo -e "————————————————————————————————————————————————————
	\033[1m        ROS_Install\033[0m
	安装ROS脚本
————————————————————————————————————————————————————
1. ◎ 安装 ROS1 noetic 版本（Ubuntu 20 安装）
2. ◎ 安装 ROS1 Melodic 版本（Ubuntu 18 安装）
3. ◎ 安装 ROS1 Kinetic 版本（Ubuntu 16 安装）
4. ◎ ROS2 humble 安装 （Ubuntu 22 安装）
0. ◎ 退出安装"
read -p "请输入序号并回车：" num
case "$num" in
[1] ) (install_ros_noetic);;
[2] ) (install_ros_Melodic);;
[3] ) (install_ros_Kinetic);;
[4] ) (install_ros_humble);;
[0] ) (exit);;
*) (Install_Ros);;
esac
}

Install_Ros
