## 📁 项目介绍

> auto_scripts_tools 为一键应用脚本，我在这里分享很多常用关于 Linux、Python 等一键脚本，对于经常繁琐的搭建和重复配置可以直接使用这里的脚本来完成！



### 📦 仓库内容

本仓库包含以下几类实用脚本：

#### 通知类脚本

- 钉钉机器人：封装了钉钉机器人通知(webhook)
- 邮件：封装了 163/126 邮箱(邮件及附件发送)

#### 巡检类脚本(Server_Patrol_Script)

- 服务器巡检脚本： 用于日常 Linux 服务器定时自动巡检，支持 Centos/Debian/Ubuntu 系统，可邮件通知（需要mail支持）

#### Git 配置文件(Git_config)

- 个性化配置文件： 一些常用的 Git 相关的配置文件保存

#### Linux 配置文件(Linux_config)

- 个性化配置文件：可以配置个性化的设置，常用设置，包括更换国内镜像源，加快软件下载速度

#### Linux 自动化脚本(Linux_auto_scripts)

nvidia-container-toolkit-install：NVIDIA Container Toolkit 国内镜像源安装

Linux_auto_scripts 中包含： **Linux 系统初始化脚本、Linux 软件一键安装脚本、Linux 常用的 Shell 脚本**

- Linux 系统初始化脚本：用于新服务器初始化，新装系统初始化，安装软件等
- Linux 软件一键安装脚本： 用于 Linux 下常用软件及复杂软件安装等
- Linux 常用的 Shell 脚本：包含于常用的 Linux 一键配置（系统及软件）

#### ROS 相关(Ros_Correlation)

- docker_ros_config：docker 安装 ros 中所修改的配置文件
- fishros_mod：鱼香 ros 一键安装脚本中所提取的一键安装 docker ros
- rosdistro： 换源，在国内环境内可以使用 rosdistro (rosdep update)
- docker ros： 安装 docker ros 版，并且可以初始化 docker ros
- install ros: 一键安装 ros，支持安装 ROS1 kinetic/melodic/noetic，ROS2 foxy/galactic/humble 版本
- env init: ros 依赖环境初始化和常用依赖功能包安装

#### 数据库相关(Mysql)

+ mysql 8.0 安装，支持 Debian/Ubuntu 系统
+ mysql 数据库备份，支持备份多个数据库

#### Python 自动化脚本(Python_Correlation)

- file_renamer.py：批量重命名工具
- logger.py：封装的 Python logging 库
- mqtt_client.py：封装的 MQTT 发布和订阅库
- ups_info.py：UPS 信息获取封装
- 努力更新中......

#### CAN(CAN通信相关)

+ vcan_manager.sh：Linux 虚拟 CAN 功能简单封装，集成创建、删除、检查、发送、接受



## 目录说明

```bash
auto_scripts_tools → main$ tree -L 1
.
├── Adb_script                           // adb 脚本
├── CAN                                  // CAN通信相关
├── Dingtalk_demo                        // 关于钉钉通知的代码
├── Env                                  // 环境依赖相关
├── Git_config                           // git 配置文件
├── Linux_auto_scripts                   // Linux 自动化脚本
├── Linux_config                         // Linux 配置文件
├── Mail_notice                          // 邮件通知相关代码
├── Mysql                                // MySQL数据库相关
├── Python_Correlation                   // Python 相关源码
├── README.md
├── Ros_Correlation                      // Ros 相关
└── Server_Patrol_Script                 // 服务器巡检脚本

11 directories, 1 file
```



## 使用说明

1. **使用 git clone 进行拉取：**

   ```shell
   # 说明：如Github链接无法拉取可以使用Gitee链接进行拉取，两个仓库同步更新
   # Github
   git clone https://github.com/toluckykoi/auto_scripts_tools.git
   
   # Gitee
   git clone https://gitee.com/toluckykoi/auto_scripts_tools.git
   
   ```

2. **环境依赖安装：(只有在运行 Python 写的工具时需要安装)**

   ```shell
   cd Env/python_pip_config/
   pip install -r dev_requirements.txt		# 全部依赖
   ```

3. **进入对应的功能目录下，然后运行对应脚本即可：**

   例如运行服务器巡检脚本：

   ```shell
   cd Server_Patrol_Script/
   chmod +x server_patrol.sh
   sudo ./server_patrol.sh
   ```

   

## 其他说明

> 该仓库内的所有工具都是一次性的运行，如果需要一直循环运行需要将脚本加入系统的定时任务中即可，使用“宝塔面板”或其他管理面板的自行在面板中找计划任务功能去添加！（后续应该会支持一键添加定时任务）



#### linux_init_script.sh：

**`linux_init_script.sh` Linux 系统初始化工具使用注意事项：**

默认初始化的 Linux 系统账号为：`toluckykoi`，密码：`toluckykoi.123qwe`；在运行`linux_init_script.sh`一键脚本时**注意修改账号密码**，修改方式如下：

**1、临时修改方式(使用传参方式)：**

临时修改账号密码是使用传参的方式，在运行脚本时在后面传入账号密码即可，例如：

```shell
sudo ./linux_init_script.sh 你的账号 你的密码
# 命令示例
sudo ./linux_init_script.sh user password
```

**2、修改默认账号密码方式：**

1、打开`vim linux_init_script.sh`脚本文件

2、更改`default_username=toluckykoi`为自己的用户名，和更改`default_password="toluckykoi.123qwe"`为自己的密码

3、:wq 保存退出



#### db_manager.py：

db_manager.py 为 mysql 数据库的备份以及恢复工具，可以直接运行或者作为 lib 的方式进行调用，使用这个，需要准备好你的`.env`文件！

命令行调用方式：

```shell
# 执行备份
python db_manager.py backup --dbs you_database --user you_database_user

# 执行恢复
python db_manager.py restore /path/to/database_file.sql --db you_recover_database --user you_database_user
```

Python 调用：

```python
# 备份数据库
from db_manager import SecureDatabaseManager

# 初始化数据库管理器
manager = SecureDatabaseManager(
    db_name="my_database",
    user="my_user",
    password="my_password",  # 可选，若已在.env文件中设置则可省略
    host="localhost",
    port=3306
)

# 执行备份
backup_path = manager.backup()
print(f"Backup saved to: {backup_path}")


# 执行恢复
from db_manager import SecureDatabaseManager

# 初始化数据库管理器
manager = SecureDatabaseManager(
    db_name="my_database",
    user="my_user",
    password="my_password",  # 可选，若已在.env文件中设置则可省略
    host="localhost",
    port=3306
)

# 执行恢复
manager.restore("/path/to/your/backup_file.sql")
print("Database restored successfully.")
```



## 更新

+ 2025-01-30 Initializing
