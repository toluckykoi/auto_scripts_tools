# !/usr/bin/env python
# -*-coding:utf-8 -*-

"""
# File       : reboot_wifi.py
# Time       ：2022/9/26 上午 1:31
# Modify     ：sityliu
# Author     ：蓝陌
# version    ：python 3.8
# Description：重启手机wifi
"""

import uiautomator2 as u2
import requests
import json
import time


d = u2.connect()

def key():
    # 打开手机
    d.screen_off()
    d.screen_on()

    time.sleep(20)

    d.screen_off()
    d.screen_on()

    # 解锁手机
    d.swipe_ext("up", 1)
    d.xpath('//*[@resource-id="com.android.systemui:id/keyguard_password_view"]/android.widget.FrameLayout[1]/android.widget.FrameLayout[1]').click()
    d.send_keys("meizu.5580")

# 消息通知
def send_msg():
    token = '78c69156f9914cf5b73dc35480d7d1fc'
    title = 'WiFi重启通知'
    content = 'wifi_重启成功。'
    url = 'http://www.pushplus.plus/send'
    data = {
        "token": token,
        "title": title,
        "content": content
    }
    body = json.dumps(data).encode(encoding='utf-8')
    headers = {'Content-Type': 'application/json'}
    requests.post(url, data=body, headers=headers)

key()

# 停止所有应用
d.app_stop_all(['com.meizu.pps', 'com.flyme.systemuitools', 'com.meizu.flymelab', 'com.meizu.facerecognition', 'com.android.systemui', 'com.android.incallui', 'com.meizu.connectivitysettings', 'com.meizu.suggestion', 'com.meizu.net.pedometer', 'com.meizu.netcontactservice', 'com.meizu.net.nativelockscreen', 'com.meizu.account', 'com.meizu.sceneinfo', 'com.meizu.flyme.launcher', 'com.qualcomm.qti.telephonyservice', 'com.android.calendar', 'com.meizu.dataservice', 'com.meizu.safe', 'com.meizu.cloud', 'com.meizu.alphame', 'com.meizu.mstore', 'com.meizu.location', 'com.google.android.gms', 'com.meizu.assistant', 'com.meizu.experiencedatasync', 'com.tencent.mm', 'com.android.providers.calendar', 'com.meizu.privacy', 'com.github.uiautomator', 'com.meizu.wifiadmin', 'com.meizu.media.music', 'com.android.phone'])
# print(d.app_list_running())

time.sleep(3)
d.app_stop("com.android.settings")
time.sleep(1)
d.app_start("com.android.settings")

time.sleep(3)

d(text="无线网络").click()
time.sleep(2)

connect = d(text="已连接")
if connect.exists():
    print("WIFI 已连接。")
    time.sleep(3)
    d.app_stop("com.android.settings")
    d.screen_off()
    send_msg()
else:
    # 这里防止WIFI打开关闭错误
    Error_Prevention = d(text="SDPT")
    if Error_Prevention.exists():
        # 未检测到WIFI连接的，先关闭WIFI然后再开启WIFI，使重新搜索WIFI以方便连接。
        print("已检测到WIFI开启，正在重启WIFI，以至于进行连接......")
        time.sleep(4)
        d(resourceId="com.meizu.wifiadmin:id/wifi_switch_layout").click()
        time.sleep(4)
        d(resourceId="com.meizu.wifiadmin:id/wifi_switch_layout").click()
        time.sleep(10)
        d(text="OpenWrt").click()
        time.sleep(2)

        print("wifi_重启成功。")
        time.sleep(3)
        d.app_stop("com.android.settings")
        d.screen_off()
        send_msg()
    else:
        print("未检测到WIFI开启状态，正在打开WIFI中......")
        time.sleep(4)
        d(resourceId="com.meizu.wifiadmin:id/wifi_switch_layout").click()
        time.sleep(10)
        d(text="OpenWrt").click()
        time.sleep(2)

        print("wifi_重启成功。")
        time.sleep(3)
        d.app_stop("com.android.settings")
        d.screen_off()
        send_msg()
