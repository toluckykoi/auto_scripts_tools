#!/bin/bash
# @Author: 幸运的锦鲤
# @Date:   2024-11-08 22:31:06
# @Last Modified time: 
# anaconda3/miniconda3 环境初始化
##################################
#1.关闭默认base环境
#2.更换为清华源镜像
#3.安装补全插件
##################################


[ $(id -u) -eq 0 ] && echo "请不要使用 sudo 或 root 来执行此脚本！" && exit 1

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# /auto_scripts_tools/xxxx
script_dir="$(dirname "$script_dir")"

CONDA_ROOT='$CONDA_ROOT'

# 检查 conda 环境
if ! command -v conda &> /dev/null; then
    echo "Conda is not installed."
    echo "Install conda and try again."
    exit 1
fi

cp ./conda_conf/condarc ~/.condarc

conda clean -i <<EOF
y
EOF

conda install -c conda-forge conda-bash-completion <<EOF
y
EOF

if [ $? -eq 0 ]; then echo "补全插件安装完成."; else echo "安装过程出现问题，请手动处理！！！" && exit 1; fi

conda_dir=$(conda info | grep "base environment")
conda_path=$(echo $conda_dir | awk '{print $4}')

echo '' >> ~/.bashrc
echo '# <- set to your Anaconda/Miniconda installation directory' >> ~/.bashrc
cat >> ~/.bashrc <<EOF
CONDA_ROOT=$conda_path
if [[ -r $CONDA_ROOT/etc/profile.d/bash_completion.sh ]]; then
    source $CONDA_ROOT/etc/profile.d/bash_completion.sh
else
    echo "WARNING: could not find conda-bash-completion setup script"
fi
EOF
echo '' >> ~/.bashrc

echo "conda_init.sh 执行完毕，请重启终端!"
