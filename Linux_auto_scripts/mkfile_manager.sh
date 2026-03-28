#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2026-03-28 20:47:01
# @version     : bash
# @Update time :
# @Description : 用于管理 auto_scripts_tools 文件的程序


usage() {
    cat <<EOF
用法：
  $(basename "$0") [选项] <文件名>

选项：
  -c <文件名>    创建新文件并写入文件头(支持 .sh / .py)
  -u <文件名>    更新文件头中的 @Update time 为当前时间
  -d <描述>      创建时附加 @Description 内容(配合 -c 使用)
  -h             显示帮助信息

示例：
  $(basename "$0") -c hello.sh                 # 创建 shell 脚本
  $(basename "$0") -c hello.py                 # 创建 python 脚本
  $(basename "$0") -c hello.py -d "主程序"      # 创建时附加描述
  $(basename "$0") -u hello.py                 # 更新 Update time
EOF
    exit 0
}

now() {
    date "+%Y-%m-%d %H:%M:%S"
}

write_sh_header() {
    local file="$1"
    local desc="$2"
    cat > "$file" <<EOF
#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : $(now)
# @version     : bash
# @Update time :
# @Description : ${desc}
EOF
}

write_py_header() {
    local file="$1"
    local desc="$2"
    cat > "$file" <<EOF
#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : $(now)
# @version     : python3
# @Update time :
# @Description : ${desc}
'''
EOF
}

create_file() {
    local file="$1"
    local desc="$2"
    local ext="${file##*.}"

    # 文件已存在则询问是否覆盖
    if [[ -e "$file" ]]; then
        read -r -p "文件 '$file' 已存在，是否覆盖？[y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || { echo "已取消。"; exit 0; }
    fi

    case "$ext" in
        sh)
            write_sh_header "$file" "$desc"
            chmod +x "$file"
            echo "已创建 Shell 脚本：$file"
            ;;
        py)
            write_py_header "$file" "$desc"
            echo "已创建 Python 脚本：$file"
            ;;
        *)
            echo "不支持的文件类型：.$ext(仅支持 .sh / .py)"
            exit 1
            ;;
    esac
}

update_time() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "文件不存在：$file"
        exit 1
    fi

    # 判断是否含有 @Update time 字段
    if ! grep -q "@Update time" "$file"; then
        echo "文件中未找到 '@Update time' 字段：$file"
        exit 1
    fi

    local timestamp
    timestamp=$(now)

    # 兼容 macOS (BSD sed) 和 Linux (GNU sed)
    if sed --version 2>/dev/null | grep -q GNU; then
        sed -i "s|# @Update time :.*|# @Update time : ${timestamp}|" "$file"
        # Python 文件头在注释块内，字段前无 #
        sed -i "s|# @Update time :.*|# @Update time : ${timestamp}|" "$file"
    else
        sed -i '' "s|# @Update time :.*|# @Update time : ${timestamp}|" "$file"
    fi

    echo "已更新 @Update time → ${timestamp}(文件：$file)"
}

ACTION=""
TARGET=""
DESC=""

[[ $# -eq 0 ]] && usage

while getopts ":c:u:d:h" opt; do
    case "$opt" in
        c)
            ACTION="create"
            TARGET="$OPTARG"
            ;;
        u)
            ACTION="update"
            TARGET="$OPTARG"
            ;;
        d)
            DESC="$OPTARG"
            ;;
        h)
            usage
            ;;
        :)
            echo "选项 -${OPTARG} 需要参数"
            exit 1
            ;;
        \?)
            echo "未知选项：-${OPTARG}"
            usage
            ;;
    esac
done

case "$ACTION" in
    create)
        create_file "$TARGET" "$DESC"
        ;;
    update)
        update_time "$TARGET"
        ;;
    *)
        echo "请指定操作：-c(创建)或 -u(更新)"
        usage
        ;;
esac
