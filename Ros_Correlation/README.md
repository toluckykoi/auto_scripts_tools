## Ros Correlation 介绍

这里存放的是与 ROS 相关的一键配置程序，包括安装，配置，初始化等。



## 目录说明

```bash
Ros_Correlation → main$ tree -L 2
├── docker_melodic_init.sh                      // 初始化 docker ros melodic （最完全初始化）
├── docker_ros_config                           // docker ros init config
│   ├── docker_root.bashrc
│   ├── docker_sshd_config
│   ├── docker_sudo.sudoers
│   └── docker_user.bashrc
├── fishros_mod                                 // 鱼香 ROS 一键脚本中提取出来相关 docker 配置 
│   ├── base.py
│   ├── install_docker.py                       // install docker（不能单独运行，作为lib方式调用）
│   └── install_ros_with_docker.py              // docker ros 环境一键安装，支持 ROS 全版本
├── install_add_pkgs.sh                         // 基础 ros 环境依赖安装脚本（目前只支持ROS1）
├── install_ros.sh                              // 一键安装 ROS 环境，支持 ROS1 ROS2
├── README.md
├── Ros2_GPG_key
│   └── ros.key
├── Ros_Distro
│   └── 20-default.list
└── rosdistro_init.sh                           // rosdistro 改为国内源加速
```



## 运行

首先给脚本程序赋予可执行权限，然后直接运行即可（有些需要用到root权限）

例如安装 ROS2 humble 环境：

```shell
chmod +x install_ros.sh
sudo ./install_ros.sh

# 终端输出（等自动初始化环境后根据提示输入指令即可）：
Ubuntu系统环境初始化完成.
正检查当前系统是否符合安装ROS，当前Linux发行版为：Ubuntu
该系统支持一键安装ROS，当前系统架构为：x86_64，当前系统版本为：Ubuntu 22.04.5 LTS，版本代号为：jammy
安装前环境检查：
当前 Ubuntu 版本为：22.04，支持安装 ROS2 humble 版本(请注意ROS1和ROS2区别)
————————————————————————————————————————————————————
         ROS_Install_Script
     ROS环境安装脚本执行中......
     请注意ROS1和ROS2区别！！！
————————————————————————————————————————————————————
1. ◎ 一键自动安装ROS1
2. ◎ 一键自动安装ROS2
3. ◎ 手动安装ROS
q. ◎ 退出安装
请输入序号并回车：
```



.py 的文件后缀是需要使用 python3 运行，如运行 docker ros 的安装：

```shell
cd fishros_mod/
chmod +x install_ros_with_docker.py
python3 ./install_ros_with_docker.py      # 运行后根据输出提示输入对应指令即可
```



## 其他说明

> 如果 docker ros 环境一键安装出现 docker 无法安装可以使用 auto_scripts_tools/Linux_auto_scripts/System_Init_Scripts/linux_init_script.sh 中的安装 docker 来进行安装，安装完 docker 后再进行 docker ros 的安装。

docker ros 所安装的 ros 环境是纯净的（就是只有系统和ros），使用过程中如果缺少依赖需要自己进行安装配置，目前的 docker ros 初始化环境只支持 melodic 版本，后续有需要再添加上其他版本。



