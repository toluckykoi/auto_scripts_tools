#!/bin/bash

# @Author      ：幸运锦鲤
# @Time        : 2025-04-22 11:21:36
# @version     : bash
# @Update time :
# @Description : cJSON 编译安装


git clone https://git.toluckykoi.com/library/cJSON.git
cd cJSON
mkdir build
cd build
cmake ..
make
sudo make install

sudo find /usr -name "cJSON.h"
