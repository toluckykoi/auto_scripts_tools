#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-09-10 18:03:50
# @version     : bash
# @Update time :
# @Description : 更换系统源镜像（国内加速）

# echo "子脚本接收到的参数个数: $#"
# echo "子脚本第一个参数: $1"
# echo "子脚本第二个参数: $2"
# echo "子脚本所有参数: $*"

ID=$(cat /etc/os-release | grep "^ID=" | awk -F '=' '{print $2}')
VERSION_ID=$(cat /etc/os-release | grep "^VERSION_ID=" | awk -F '=' '{print $2}' | awk -F '"' '{print $2}')
DIR_PATH=$(dirname "$(dirname "$(cd "$(dirname "$0")" && pwd)")")

case "$ID" in
    ubuntu|debian|fedora|centos)
        echo "当前系统 ($ID) 受支持。"
        ;;
    *)
        echo "错误：暂不支持的系统类型 '$ID'。仅支持 Ubuntu、Debian、Fedora 或 CentOS。"
        exit 1
        ;;
esac

if command -v apt >/dev/null 2>&1; then
    software_manager=apt
elif command -v yum >/dev/null 2>&1; then
    software_manager=yum
else
    echo "未检测到apt, yum或dnf软件包安装工具"
    exit 1
fi

if [ $# == 0 ]; then
    server_region="china"
    printf "%-65s %s\n" \
    "大学软件镜像站:" "企业软件镜像站:" \
    "1.清华大学镜像站: https://mirrors.tuna.tsinghua.edu.cn" "6.阿里云镜像站: https://mirrors.aliyun.com" \
    "2.中科大学镜像站: https://mirrors.ustc.edu.cn" "7.腾讯云镜像站: https://mirrors.tencent.com" \
    "3.南京大学镜像站: https://mirror.nju.edu.cn" "8.华为云镜像站: https://mirrors.huaweicloud.com" \
    "4.北京大学镜像站: https://mirrors.pku.edu.cn" "9.网易云镜像站: https://mirrors.163.com" \
    "5.浙江大学镜像站: https://mirrors.zju.edu.cn"  "10.移动云镜像站: https://mirrors.cmecloud.cn" \
    "系统官方镜像站:" \  \
    "a.Ubuntu官方: http://archive.ubuntu.com" \  \
    "b.Debian官方: http://deb.debian.org" \  \
    "c.Fedora官方: https://mirrors.fedoraproject.org"

    read -ep "即将更新系统软件源，请选择合适的加速源地址：" choice
    case $choice in
        1) MIRROR_URL="https://mirrors.tuna.tsinghua.edu.cn";;
        2) MIRROR_URL="https://mirrors.ustc.edu.cn";;
        3) MIRROR_URL="https://mirror.nju.edu.cn";;
        4) MIRROR_URL="https://mirrors.pku.edu.cn";;
        5) MIRROR_URL="https://mirrors.zju.edu.cn";;
        6) MIRROR_URL="https://mirrors.aliyun.com";;
        7) MIRROR_URL="https://mirrors.tencent.com";;
        8) MIRROR_URL="https://mirrors.huaweicloud.com";;
        9) MIRROR_URL="https://mirrors.163.com";;
        10) MIRROR_URL="https://mirrors.cmecloud.cn";;
        a) MIRROR_URL="http://archive.ubuntu.com";;
        b) MIRROR_URL="http://deb.debian.org";;
        c) MIRROR_URL="https://mirrors.fedoraproject.org";;
        *)
        echo -e "无效选择."
        ;;
    esac

    echo "已选择镜像源: $MIRROR_URL"
else
    server_region=$1
    MIRROR_URL="https://mirrors.huaweicloud.com"
fi


if [ "$server_region" == "china" ]; then
    echo ""
    echo "在国内环境，需要更换镜像源！"

    echo "####################更换国内源镜像####################"
    if [ "$software_manager" == "apt" ] && [ "$ID" == "ubuntu" ]; then
        if [ "$VERSION_ID" == "16.04" ]; then
            echo "ubuntu 16.04"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            if [ "$SYSTEM_ARCH" = "x86" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu/ubuntu16_sources.list /etc/apt/sources.list
            elif [ "$SYSTEM_ARCH" = "ARM" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu-ports/ubuntu16_sources.list /etc/apt/sources.list
            fi
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/ubuntu[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(ubuntu|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"
        
        elif [ "$VERSION_ID" == "18.04" ]; then
            echo "ubuntu 18.04"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            if [ "$SYSTEM_ARCH" = "x86" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu/ubuntu18_sources.list /etc/apt/sources.list
            elif [ "$SYSTEM_ARCH" = "ARM" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu-ports/ubuntu18_sources.list /etc/apt/sources.list
            fi
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/ubuntu[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(ubuntu|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        elif [ "$VERSION_ID" == "20.04" ]; then
            echo "ubuntu 20.04"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            if [ "$SYSTEM_ARCH" = "x86" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu/ubuntu20_sources.list /etc/apt/sources.list
            elif [ "$SYSTEM_ARCH" = "ARM" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu-ports/ubuntu20_sources.list /etc/apt/sources.list
            fi
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/ubuntu[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(ubuntu|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        elif [ "$VERSION_ID" == "22.04" ]; then
            echo "ubuntu 22.04"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            if [ "$SYSTEM_ARCH" = "x86" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu/ubuntu22_sources.list /etc/apt/sources.list
            elif [ "$SYSTEM_ARCH" = "ARM" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu-ports/ubuntu22_sources.list /etc/apt/sources.list
            fi
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/ubuntu[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(ubuntu|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        elif [ "$VERSION_ID" == "24.04" ]; then
            echo "ubuntu 24.04"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            if [ "$SYSTEM_ARCH" = "x86" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu/ubuntu24_sources.list /etc/apt/sources.list
            elif [ "$SYSTEM_ARCH" = "ARM" ]; then
                sudo cp $DIR_PATH/ConfigFiles/linux/ubuntu-ports/ubuntu24_sources.list /etc/apt/sources.list
            fi
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/ubuntu[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(ubuntu|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        else
            echo "版本不支持"
            exit 1
        fi

    elif [ "$software_manager" == "apt" ] && [ "$ID" == "debian" ]; then
        if [ "$VERSION_ID" == "10" ]; then
            echo "debian 10"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            sudo cp $DIR_PATH/ConfigFiles/linux/debian/debian10_sources.list /etc/apt/sources.list
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/debian[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(debian|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        elif [ "$VERSION_ID" == "11" ]; then
            echo "debian 11"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            sudo cp $DIR_PATH/ConfigFiles/linux/debian/debian11_sources.list /etc/apt/sources.list
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/debian[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(debian|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        elif [ "$VERSION_ID" == "12" ]; then
            echo "debian 12"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            sudo cp $DIR_PATH/ConfigFiles/linux/debian/debian12_sources.list /etc/apt/sources.list
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/debian[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(debian|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"
        
        elif [ "$VERSION_ID" == "13" ]; then
            echo "debian 13"
            sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
            sudo cp $DIR_PATH/ConfigFiles/linux/debian/debian13_sources.list /etc/apt/sources.list
            sudo sed -i "/^[^#]/ s|https\?://[^/]*\(/debian[-/][^ ]*\)|$MIRROR_URL\1|g" "/etc/apt/sources.list"
            grep -v "^#" "/etc/apt/sources.list" | grep -E "(debian|security)"
            echo ""
            sudo apt update
            echo "已更换镜像源"

        else
            echo "版本不支持"
            exit 1
        fi

    elif [ "$software_manager" == "yum" ] && [ $ID == '"centos"' ]; then
        if [ "$VERSION_ID" == "7" ]; then
            echo "centos 7"
            sudo cp -a /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
            sudo cp $DIR_PATH/ConfigFiles/linux/centos/huawei-CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
            sudo yum clean all
            sudo yum makecache
            echo "已更换镜像源"
        
        else
            echo "版本不支持"
            exit 1
        fi

    elif [ "$software_manager" == "yum" ] && [ $ID == '"fedora"' ]; then
        echo "fedora"
        sudo cp -a /etc/yum.repos.d/fedora-updates.repo /etc/yum.repos.d/fedora-updates.repo.bak
        sudo cp -a /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora.repo.bak

        sudo cp $DIR_PATH/ConfigFiles/linux/fedora/fedora-updates.repo /etc/yum.repos.d/fedora-updates.repo
        sudo cp $DIR_PATH/ConfigFiles/linux/fedora/fedora.repo /etc/yum.repos.d/fedora.repo
        sudo sed -i "s|^\(baseurl=\s*\)https\?://[^/]*\(/fedora/[^\s]*\)|\1$MIRROR_URL\2|g" /etc/yum.repos.d/fedora-updates.repo
        sudo sed -i "s|^\(baseurl=\s*\)https\?://[^/]*\(/fedora/[^\s]*\)|\1$MIRROR_URL\2|g" /etc/yum.repos.d/fedora.repo
        grep -E "^\s*baseurl=.*fedora" /etc/yum.repos.d/fedora-updates.repo
        echo ""
        grep -E "^\s*baseurl=.*fedora" /etc/yum.repos.d/fedora.repo
        echo ""
        sudo yum clean all
        sudo dnf makecache
        echo "已更换镜像源"

    else
        echo "版本不支持！"
    fi
else
    echo "国外环境，无需配置镜像源！"
fi
