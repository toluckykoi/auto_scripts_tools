#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-18 10:24:38
# @version     : bash
# @Update time :
# @Description : jupyter install and uninstall


# 配置
SYSTEM_VENV_DIR="$HOME/.pyenvs/jupyter_env"
CONFIG_DIR="$HOME/.config/jupyter_conf"
JUPYTER_PROJECT_DIR="$HOME"
SET_PIP_SPEED="pip3 config set global.index-url https://mirrors.huaweicloud.com/repository/pypi/simple"

# 检查系统类型并设置包管理器
if [ -f /etc/os-release ]; then
  . /etc/os-release
  SYSTEM_INFO="🚀 当前系统为：$ID $VERSION_ID"
  case "$ID" in
    ubuntu|debian)
      UPDATE="sudo apt update"
      INSTALLER_PY_PKGS="sudo apt install -y python3-pip python3-venv"
      UPDATE_PIP="python3 -m pip install --upgrade pip"
      ;;
    arch|manjaro)
      UPDATE="sudo pacman -Sy"
      INSTALLER_PY_PKGS="sudo pacman -S --noconfirm python3-pip python3-venv"
      UPDATE_PIP="python3 -m pip install --upgrade pip"
      ;;
    fedora)
      UPDATE="sudo dnf check-update || true"
      INSTALLER_PY_PKGS="sudo dnf install -y python3-pip python3-venv"
      UPDATE_PIP="python3 -m pip install --upgrade pip"
      ;;
    centos|rhel)
      UPDATE="sudo yum check-update || true"
      INSTALLER_PY_PKGS="sudo yum install -y python3-pip python3-venv"
      UPDATE_PIP="python3 -m pip install --upgrade pip"
      ;;
    opensuse*)
      UPDATE="sudo zypper refresh"
      INSTALLER_PY_PKGS="sudo zypper install -y python3-pip python3-venv"
      UPDATE_PIP="python3 -m pip install --upgrade pip"
      ;;
    alpine)
      UPDATE="sudo apk update"
      INSTALLER_PY_PKGS="sudo apk add python3-pip python3-venv"
      UPDATE_PIP="python3 -m pip install --upgrade pip"
      ;;
    *)
      echo "❌ 不支持的发行版（$ID），请手动安装 Python3、pip 和 venv"
      exit 1
      ;;
  esac
else
  echo "❌ 无法识别系统类型，缺少 /etc/os-release"
  exit 1
fi


# 检查是否安装了 Python 3
if ! command -v python3 &> /dev/null; then
    echo "❌ 错误：未找到 Python3"
    exit 1
fi

# 获取 Python 3 的版本号
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
MAJOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d '.' -f 1)
MINOR_VERSION=$(echo "$PYTHON_VERSION" | cut -d '.' -f 2)

# 检查版本是否大于等于 3.8
if [ "$MAJOR_VERSION" -gt 3 ]; then
    PYTHON_VERSION_INFO="🔍 当前系统 Python3 版本为 $PYTHON_VERSION，满足要求（>= 3.8）"
    virtual="system"

elif [ "$MAJOR_VERSION" -eq 3 ] && [ "$MINOR_VERSION" -ge 8 ]; then
    PYTHON_VERSION_INFO="🔍 当前系统 Python3 版本为 $PYTHON_VERSION，满足要求（>= 3.8）"
    virtual="system"

else
    # Python 虚拟环境检查
    if command -v conda &> /dev/null; then
        virtual="conda"

    elif command -v virtualenv &> /dev/null; then
        virtual="virtualenv"

    else
        virtual="null"
        echo "🔍 当前系统 Python3 版本为 $PYTHON_VERSION，不满足要求（需要 >= 3.8）也未检测到虚拟环境"
        echo "📦 请升级 Python 版本或者安装虚拟环境！"
        echo "exit."
        exit 1
    fi

    PYTHON_VERSION_INFO="🔍 当前系统 Python 版本为 $PYTHON_VERSION，不满足要求，检查是否有虚拟环境，虚拟环境为 $virtual"
fi

function install_depend(){
    # 更新并安装依赖
    echo "🔧 检查并安装缺失依赖..."
    $UPDATE
    $INSTALLER_PY_PKGS
    $SET_PIP_SPEED
    $UPDATE_PIP
    echo "✅ 所有依赖已安装。"
}

function jupyter_install(){
    # jupyter 安装
    pip3 install jupyterlab notebook
    pip3 install jupyterlab-language-pack-zh-CN
    pip3 install python-lsp-server
    pip3 install lckr-jupyterlab-variableinspector
    pip3 install jupyterlab-git
    pip3 install jupyterlab-system-monitor

    jupyter kernelspec list
    if [ $? -ne 0 ]; then
        pip3 install "ipython>=8.0,<8.13"
    fi

    if [ $? -eq 0 ]; then
        echo "✅ 完成安装."
    fi
}

function config_env(){
    # 配置环境(优先使用系统python的虚拟环境)
    echo "🔧 检查并配置环境..."
    local env_type=$1
    if [ "$env_type" = "auto" ]; then
        if [ "$virtual" = "system" ]; then
            echo "检测到系统 python 满足要求，默认使用 system python 虚拟环境"
            if [ ! -d "$SYSTEM_VENV_DIR" ]; then
                mkdir -p "$SYSTEM_VENV_DIR"
            fi
            python3 -m venv $SYSTEM_VENV_DIR
            source $SYSTEM_VENV_DIR/bin/activate
            if [ $? -eq 0 ]; then
                jupyter_install
            else
                echo "创建虚拟环境失败！请重试."
                exit 1
            fi

        elif [ "$virtual" = "conda" ]; then
            echo "检测到 conda 环境，使用 conda 虚拟环境"
            conda create -n jupyter_env python=3.8 -y
            source $(conda info --base)/etc/profile.d/conda.sh
            conda activate jupyter_env
            if [ $? -eq 0 ]; then
                jupyter_install
            else
                echo "创建虚拟环境失败！请重试."
                exit 1
            fi

        elif [ "$virtual" = "virtualenv" ]; then
            echo "检测到 virtualenv 环境，使用 virtualenv 虚拟环境"
            source $HOME/.local/bin/virtualenvwrapper.sh
            mkvirtualenv -p python3.8 jupyter_env
            source $WORKON_HOME/jupyter_env/bin/activate
            if [ $? -eq 0 ]; then
                jupyter_install
            else
                echo "创建虚拟环境失败！请重试."
                exit 1
            fi
        fi
    
    elif [ "$env_type" = "virtual" ]; then
        if command -v conda &> /dev/null; then
            virtual="conda"
        elif command -v virtualenv &> /dev/null; then
            virtual="virtualenv"
        else
            virtual="null"
        fi 
        
        if [ "$virtual" = "conda" ]; then
            echo "检测到 conda 环境，使用 conda 虚拟环境"
            conda create -n jupyter_env python=3.8 -y
            source $(conda info --base)/etc/profile.d/conda.sh
            conda activate jupyter_env
            if [ $? -eq 0 ]; then
                jupyter_install
            else
                echo "创建虚拟环境失败！请重试."
                exit 1
            fi

        elif [ "$virtual" = "virtualenv" ]; then
            echo "检测到 virtualenv 环境，使用 virtualenv 虚拟环境"
            source $HOME/.local/bin/virtualenvwrapper.sh
            mkvirtualenv -p python3.8 jupyter_env
            source $WORKON_HOME/jupyter_env/bin/activate
            if [ $? -eq 0 ]; then
                jupyter_install
            else
                echo "创建虚拟环境失败！请重试."
                exit 1
            fi
        fi
    fi
}

function conf_write(){
    # 永久配置文件写入
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    if [ ! -d "$JUPYTER_PROJECT_DIR" ]; then
        mkdir -p "$JUPYTER_PROJECT_DIR"
    fi
    touch $CONFIG_DIR/jupyter.conf

    cat <<EOF > "$CONFIG_DIR/jupyter.conf"
# jupyter config
JUPYTER_INSTALL_TYPE="$virtual"
JUPYTER_JUPYTER_PROJECT_DIR="$JUPYTER_PROJECT_DIR"
JUPYTER_PORT="38888"
EOF
    echo "永久配置写入到: $CONFIG_DIR/jupyter.conf"
}

function add_start_config(){
    # 启动脚本配置
    touch $CONFIG_DIR/jupyter_lab_start.sh $CONFIG_DIR/jupyter_notebook_start.sh
    chmod +x $CONFIG_DIR/jupyter_lab_start.sh $CONFIG_DIR/jupyter_notebook_start.sh
    cat <<'EOF' > "$CONFIG_DIR/jupyter_lab_start.sh"
#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-18 10:30:38
# @version     : bash
# @Update time :
# @Description : jupyter lab start

CONFIG_FILE="$HOME/.config/jupyter_conf/jupyter.conf"

# 检查配置文件
if [ -f "$CONFIG_FILE" ]; then
    echo "加载配置文件：$CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "错误：配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

if [ "$JUPYTER_INSTALL_TYPE" = "system" ]; then
    source "$HOME/.pyenvs/jupyter_env/bin/activate"
    echo "🚀 启动 Jupyter lab..."
    if command -v jupyter-notebook &>/dev/null; then
        jupyter lab --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --ServerApp.root_dir="$JUPYTER_JUPYTER_PROJECT_DIR"
    else
        echo "⚠️ jupyter 未安装！"
    fi

elif [ "$JUPYTER_INSTALL_TYPE" = "conda" ]; then
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate jupyter_env
    echo "🚀 启动 Jupyter lab..."
    if command -v jupyter-notebook &>/dev/null; then
        jupyter lab --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --ServerApp.root_dir="$JUPYTER_JUPYTER_PROJECT_DIR"
    else
        echo "⚠️ jupyter 未安装！"
    fi

elif [ "$JUPYTER_INSTALL_TYPE" = "virtualenv" ]; then
    source $HOME/.local/bin/virtualenvwrapper.sh
    source $WORKON_HOME/jupyter_env/bin/activate
    echo "🚀 启动 Jupyter lab..."
    if command -v jupyter-notebook &>/dev/null; then
        jupyter lab --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --ServerApp.root_dir="$JUPYTER_JUPYTER_PROJECT_DIR"
    else
        echo "⚠️ jupyter 未安装！"
    fi
fi
EOF
    cat <<'EOF' > "$CONFIG_DIR/jupyter_notebook_start.sh"
#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-18 10:30:38
# @version     : bash
# @Update time :
# @Description : jupyter notebook start

CONFIG_FILE="$HOME/.config/jupyter_conf/jupyter.conf"

# 检查配置文件
if [ -f "$CONFIG_FILE" ]; then
    echo "加载配置文件：$CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "错误：配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

if [ "$JUPYTER_INSTALL_TYPE" = "system" ]; then
    source "$HOME/.pyenvs/jupyter_env/bin/activate"
    echo "🚀 启动 Jupyter Notebook..."
    if command -v jupyter-notebook &>/dev/null; then
        jupyter notebook --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --NotebookApp.notebook_dir="$JUPYTER_JUPYTER_PROJECT_DIR"
    else
        echo "⚠️ jupyter 未安装！" 
    fi   

elif [ "$JUPYTER_INSTALL_TYPE" = "conda" ]; then
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate jupyter_env
    echo "🚀 启动 Jupyter Notebook..."
    if command -v jupyter-notebook &>/dev/null; then
        jupyter notebook --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --NotebookApp.notebook_dir="$JUPYTER_JUPYTER_PROJECT_DIR"
    else
        echo "⚠️ jupyter 未安装！"
    fi

elif [ "$JUPYTER_INSTALL_TYPE" = "virtualenv" ]; then
    source $HOME/.local/bin/virtualenvwrapper.sh
    source $WORKON_HOME/jupyter_env/bin/activate
    echo "🚀 启动 Jupyter Notebook..."
    if command -v jupyter-notebook &>/dev/null; then
        jupyter notebook --ip=0.0.0.0 --port=$JUPYTER_PORT --no-browser --allow-root --NotebookApp.notebook_dir="$JUPYTER_JUPYTER_PROJECT_DIR"
    else
        echo "⚠️ jupyter 未安装！"
    fi
fi
EOF
    sudo cp $CONFIG_DIR/jupyter_lab_start.sh /usr/bin/jupyter_lab_start
    sudo cp $CONFIG_DIR/jupyter_notebook_start.sh /usr/bin/jupyter_notebook_start
    echo "生成一键启动脚本."
    echo "启动方式："
    echo "终端中直接输入启动命令: jupyter_lab_start 或 jupyter_notebook_start"
    echo "开机启动 jupyter 可以使用 systemctl 或者 pm2 进行管理."
    echo "注意: 第一次启动 jupyter 时是需要终端中临时生成的 token ; 可以使用此 token 在登陆界面中生成永久的密码！"
}

function auto_install(){
    # 自动安装 jupyter（jupyterlab和notebook）
    echo "开始安装 jupyter..."
    install_depend
    config_env "auto"
    conf_write
    add_start_config
}

function virtual_install(){
    # 自动选择虚拟环境安装 jupyter（jupyterlab和notebook）
    echo "自动选择虚拟环境开始安装 jupyter..."
    install_depend
    config_env "virtual"
    conf_write
    add_start_config
}

function uninstall(){
    # 卸载 jupyter
    echo "开始卸载 jupyter..."
    echo "删除 jupyter 虚拟环境."
    source "$HOME/.config/jupyter_conf/jupyter.conf"
    if [ "$JUPYTER_INSTALL_TYPE" = "system" ]; then
        rm -rf "$HOME/.pyenvs"

    elif [ "$JUPYTER_INSTALL_TYPE" = "conda" ]; then
        source $(conda info --base)/etc/profile.d/conda.sh
        conda env remove --name jupyter_env

    elif [ "$JUPYTER_INSTALL_TYPE" = "virtualenv" ]; then
        source $HOME/.local/bin/virtualenvwrapper.sh
        rmvirtualenv jupyter_env
    fi

    echo "正在删除配置文件..."
    sudo rm -rf $HOME/.jupyter $CONFIG_DIR
    sudo rm /usr/bin/jupyter_lab_start /usr/bin/jupyter_notebook_start
    echo "✅ 卸载完成！"
}


function Main(){
echo -e "——————————————————————————————————————————————————————
   \033[1m               jupyter_install\033[0m
   \033[32mjupyter install —-主菜单 v1.0.0\033[0m
   $SYSTEM_INFO
   $PYTHON_VERSION_INFO
——————————————————————————————————————————————————————
1. ◎ 自动安装 jupyter
2. ◎ conda or virtualenv 安装 jupyter
3. ◎ 卸载 jupyter
q. ◎ 退出安装"
sleep 0.2
read -ep  "请输入序号并回车：" num
case "$num" in
[1] ) (auto_install);;
[2] ) (virtual_install);;
[3] ) (uninstall);;
[q] ) (exit);;
*) (Main);;
esac
}

Main
