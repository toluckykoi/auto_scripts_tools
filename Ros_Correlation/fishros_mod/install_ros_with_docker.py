# -*- coding: utf-8 -*-

import os
import shutil
from base import BaseTool, CmdTask
from base import PrintUtils,FileUtils,AptUtils,ChooseTask
from base import run_tool_file

def getArch():
        result = CmdTask("dpkg --print-architecture",2).run()
        arc = result[1][0].strip("\n")
        if arc=='armhf': 
            arc = 'arm64'
        if result[0]==0: 
            return arc
        print("小鱼提示:自动获取系统架构失败...请手动选择")
        # @TODO 提供架构选项 amd64,i386,arm
        
        return None


class RosVersion:
    STATUS_EOL = 0
    STATUS_LTS = 1
    def __init__(self,name,version,status,images=[],arm_images=[]):
        self.name = name
        self.version = version
        self.status = status
        self.images = images
        self.arm_images = arm_images


class RosVersions:
    ros_version = [ 
        RosVersion('jazzy', 'ROS2', RosVersion.STATUS_LTS, ['osrf/ros:jazzy-desktop-full'],["ros:jazzy"]),
        RosVersion('noetic',  'ROS1', RosVersion.STATUS_LTS, ['fishros2/ros:noetic-desktop-full'],["ros:noetic"]),
        RosVersion('humble',  'ROS2', RosVersion.STATUS_LTS, ['fishros2/ros:humble-desktop-full'],["ros:humble"]),
        RosVersion('foxy',  'ROS2', RosVersion.STATUS_EOL, ['fishros2/ros:foxy-desktop'],["ros:foxy"]),
        RosVersion('galactic',  'ROS2', RosVersion.STATUS_LTS, ['osrf/ros:galactic-desktop'],["ros:galactic"]),
        RosVersion('iron',  'ROS2', RosVersion.STATUS_LTS, ['osrf/ros:iron-desktop-full'],["ros:iron"]),
        RosVersion('melodic', 'ROS1', RosVersion.STATUS_LTS, ['fishros2/ros:melodic-desktop-full'],["ros:melodic"]),
        RosVersion('rolling',  'ROS2', RosVersion.STATUS_LTS, ['osrf/ros:rolling-desktop-full'],["ros:rolling"]),
        RosVersion('kinetic', 'ROS1', RosVersion.STATUS_EOL, ['osrf/ros:kinetic-desktop-full'],["ros:kinetic"]),
        RosVersion('eloquent',  'ROS2', RosVersion.STATUS_EOL, ['osrf/ros:eloquent-desktop'],["ros:eloquent"]),
        RosVersion('dashing',  'ROS2', RosVersion.STATUS_EOL, ['osrf/ros:dashing-desktop'],["ros:dashing"]),
        RosVersion('crystal',  'ROS2', RosVersion.STATUS_EOL, ['osrf/ros:crystal-desktop'],["ros:crystal"]),
        RosVersion('bouncy',  'ROS2', RosVersion.STATUS_EOL, ['osrf/ros:bouncy-desktop'],["ros:bouncy"]),
        RosVersion('ardent',  'ROS2', RosVersion.STATUS_EOL, ['osrf/ros:ardent-desktop'],["ros:ardent"]),
        RosVersion('lunar', 'ROS2', RosVersion.STATUS_EOL, ['osrf/ros:lunar-desktop'],["ros:lunar"]),
        RosVersion('indigo', 'ROS1', RosVersion.STATUS_EOL, ['osrf/ros:indigo-desktop-full'],["ros:indigo"])
    ]

    @staticmethod
    def get_version_string(name):
        names = str(name).split(' ')
        if len(names)>=1:
            ros_version = names[0]
        else:
            return None,None
        for version in RosVersions.ros_version:
            if version.name == ros_version:
                if version.status==RosVersion.STATUS_EOL:
                    eol = "停止维护"
                else:
                    eol = "长期支持"
                return "{}({}),该版本目前状态:{}".format(version.name,version.version,eol), ros_version

    @staticmethod
    def get_image(name):
        osarch = getArch()
        for version in RosVersions.ros_version:
            if version.name == name:
                if osarch=="arm64":
                    return version.arm_images[0]
                return version.images[0]

    @staticmethod
    def get_ros_version(name):
        for version in RosVersions.ros_version:
            if version.name == name:
                return version

    @staticmethod
    def install_depend(name):
        depends = RosVersions.get_version(name).deps
        for dep in depends:
            AptUtils.install_pkg(dep)


    @staticmethod
    def tip_test_command(name):
        version = RosVersions.get_version(name).version
        if version=="ROS1":
            PrintUtils.print_warn("小鱼，黄黄的提示：您安装的是ROS1，可以打开一个新的终端输入roscore测试！")
        elif version=="ROS2":
            PrintUtils.print_warn("小鱼：黄黄的提示：您安装的是ROS2,ROS2是没有roscore的，请打开新终端输入ros2测试！小鱼制作了ROS2课程，关注公众号《鱼香ROS》即可获取~")

    @staticmethod
    def get_vesion_list():
        """获取可安装的ROS版本列表"""
        names = []
        for version in RosVersions.ros_version:
            names.append(f'{version.name} ({version.version})')
        return names


class Tool(BaseTool):
    def __init__(self):
        self.name = "欢迎使用一键安装ROS-Docker版,支持所有版本ROS"
        self.thanks = "express one's thanks：鱼香ROS一键安装脚本!"
        self.autor = '锦鲤'

    def nvidia_gpu_check(self):
        nvidia_smi_path = shutil.which("nvidia-smi")
        if nvidia_smi_path:
            print("检测到 NVIDIA GPU，启用 NVIDIA GPU 支持.")
            return True
        else:
            print("没有检测到 NVIDIA GPU.")
            return False

    def get_container_scripts(self, name, rosversion, delete_file):
        delete_command = "sudo rm -rf {}".format(delete_file)
        ros1 = """xhost +local: >> /dev/null
echo "请输入指令控制{}: 重启(r) 进入(e) 启动(s) 关闭(c) 删除(d) 测试(t):"
read choose
case $choose in
s) docker start {};;
r) docker restart {};;
e) docker exec -it {} /bin/bash;;
c) docker stop {};;
d) docker stop {} && docker rm {} && {};;
t) docker exec -it {}  /bin/bash -c "source /ros_entrypoint.sh && roscore";;
esac
newgrp docker
""".format(name,name,name,name,name,name,name,delete_command,name)
        ros2 = """xhost +local: >> /dev/null
echo "请输入指令控制{}: 重启(r) 进入(e) 启动(s) 关闭(c) 删除(d) 测试(t):"
read choose
case $choose in
s) docker start {};;
r) docker restart {};;
e) docker exec -it {} /bin/bash;;
c) docker stop {};;
d) docker stop {} && docker rm {} && {};;
t) docker exec -it {}  /bin/bash -c "source /ros_entrypoint.sh && ros2";;
esac
newgrp docker
""".format(name,name,name,name,name,name,name,delete_command,name)
        if rosversion=="ROS1":
            return ros1
        return ros2

    def choose_image_version(self):
        """获取要安装的ROS版本"""
        PrintUtils.print_success("================================1.版本选择======================================")
        code,result = ChooseTask(RosVersions.get_vesion_list(),"请选择你要安装的ROS版本名称(请注意ROS1和ROS2区别):",True).run()
        if code==0: 
            print("你选择退出。。。。")
            return 
        version_info,rosname = RosVersions.get_version_string(result)
        print("你选择了{}".format(version_info))
        return rosname

    def install_docker(self):
        """安装Docker"""
        PrintUtils.print_success("================================2.安装Docker======================================")
        result = CmdTask("sudo docker version").run()
        if(result[0]==0): 
            print("系统中已安装Docker，无需重复安装，跳过")
            return
        print("未安装Docker，自动安装Docker.")
        run_tool_file('install_docker')
        # TODO 检查是否安装成功

    def download_image(self,name):
        """"""
        PrintUtils.print_success("=================3.下载镜像（该步骤因网络原因会慢一些，若失败请重试）==================")
        CmdTask('sudo docker pull {} '.format(RosVersions.get_image(name)),os_command=True).run()
        CmdTask('sudo docker pull {} '.format(RosVersions.get_image(name)),os_command=True).run()
        CmdTask('sudo docker pull {} '.format(RosVersions.get_image(name)),os_command=True).run()


    def create_container(self,name):
        """创建容器"""
        PrintUtils.print_success("================================4.生成容器======================================")
        # get a name
        PrintUtils.print_warn("请为你的{}容器取个名字吧！".format(name))
        container_name = input(">>")
        PrintUtils.print_info("收到名字{}:".format(container_name))
        while not container_name:
            PrintUtils.print_warn("请为你的{}容器取个名字吧！".format(name))
            container_name = input(">>")

        # get home
        user =  FileUtils.getusers()[0]
        home = "/home/{}".format(user)

        use_dri = ""
        if FileUtils.exists("/dev/dri/renderD128"):
            use_dri = "--device=/dev/dri/renderD128"

        use_snd = ""
        if FileUtils.exists("/dev/snd"):
            use_snd = "--device=/dev/snd"

        is_installed = self.nvidia_gpu_check()
        if is_installed:
            if container_name:
                command_create_x11 = "sudo docker run -dit --gpus all -e NVIDIA_DRIVER_CAPABILITIES=all --name={} --privileged --net=host -v {}:{} -v /tmp/.X11-unix:/tmp/.X11-unix {} -v /dev:/dev -v /dev/dri:/dev/dri {} -e DISPLAY=unix$DISPLAY -w {}  {}".format(
                        container_name,home,home,use_dri,use_snd,home,RosVersions.get_image(name))
            else:
                command_create_x11 = "sudo docker run -dit --gpus all -e NVIDIA_DRIVER_CAPABILITIES=all --privileged --net=host  -v {}:{} -v /tmp/.X11-unix:/tmp/.X11-unix {}  -v /dev:/dev -v /dev/dri:/dev/dri {} -e DISPLAY=unix$DISPLAY -w {}  {}".format(
                        home,home,use_dri,use_snd,home,RosVersions.get_image(name))

            result = CmdTask(command_create_x11,os_command=True).run()
        
        else:
            if container_name:
                command_create_x11 = "sudo docker run -dit --name={} --privileged --net=host -v {}:{} -v /tmp/.X11-unix:/tmp/.X11-unix {} -v /dev:/dev -v /dev/dri:/dev/dri {} -e DISPLAY=unix$DISPLAY -w {}  {}".format(
                        container_name,home,home,use_dri,use_snd,home,RosVersions.get_image(name))
            else:
                command_create_x11 = "sudo docker run -dit --privileged --net=host  -v {}:{} -v /tmp/.X11-unix:/tmp/.X11-unix {}  -v /dev:/dev -v /dev/dri:/dev/dri {} -e DISPLAY=unix$DISPLAY -w {}  {}".format(
                        home,home,use_dri,use_snd,home,RosVersions.get_image(name))

            result = CmdTask(command_create_x11,os_command=True).run()
        return container_name


    def generte_command(self,container_name,rosname):
        """生成命令"""
        PrintUtils.print_success("================================5.生成命令======================================")
        rosversion = RosVersions.get_ros_version(rosname).version
        user =  FileUtils.getusers()[0]
        bin_path = "/root/.docker_ros/bin/"
        bashrc = '/root/.bashrc'
        if user!='root':
            bin_path = "/home/{}/.local/docker_ros/bin/".format(user)
            bashrc = '/home/{}/.bashrc'.format(user)
        home = "/home/{}".format(user)

        # create file
        FileUtils.new(bin_path,container_name,self.get_container_scripts(container_name,rosversion,bin_path+container_name))
        FileUtils.find_replace_sub(bashrc,"\n# >>> docker ros >>>","# <<< docker ros <<<", "")
        FileUtils.append(bashrc,'# >>> docker ros >>>\nexport PATH=$PATH:{} \n# <<< docker ros <<<\n\n'.format(bin_path))
        CmdTask('chmod 777 {}'.format(bin_path+container_name),os_command=True).run()


    def install_ros_with_docker(self):
        try:
            os.system('clear')
            print(self.name)
            osarch = getArch()
            print(f"当前系统架构：{osarch}")
            rosname = self.choose_image_version()
            if not rosname: return

            self.install_docker()
            self.download_image(rosname)
            container_name = self.create_container(rosname)
            self.generte_command(container_name,rosname)

            PrintUtils.print_info("后续可在任意终端输入 {} 来启动/停止/测试/删除容器".format(container_name))
            PrintUtils.print_info("你的主目录已经和容器的对应目录做了映射")
            PrintUtils.print_info("感谢鱼香ROS一键安装脚本")
        
        except KeyboardInterrupt:
            print()
            pass

    def run(self):
        self.install_ros_with_docker()


Tool().run()
