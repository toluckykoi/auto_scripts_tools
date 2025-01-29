#!/bin/bash


wget https://download.yunsuo.qianxin.com/v3/yunsuo_agent_64bit.tar.gz && tar xvzf yunsuo_agent_64bit.tar.gz && chmod +x yunsuo_install/install && yunsuo_install/install

sleep 3

/usr/local/yunsuo_agent/agent_smart_tool.sh -u phone_num -p pasword

