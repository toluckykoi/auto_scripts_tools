# !/usr/bin/env python
# -*-coding:utf-8 -*-

"""
# File       : target_following.py
# Time       ：2023/3/25 下午 4:37
# Modify     ：sityliu
# Author     ：蓝陌
# version    ：python 3.8
# Description：目标跟踪
"""


import cv2

# 创建CSRT跟踪器
tracker = cv2.TrackerCSRT_create()

# 打开摄像头
cap = cv2.VideoCapture(0)

# 获取第一帧图像
ret, frame = cap.read()

# 选择要跟踪的初始位置
bbox = cv2.selectROI(frame, False)

# 初始化跟踪器
tracker.init(frame, bbox)

while True:
    # 读取新帧
    ret, frame = cap.read()

    # 更新跟踪器
    success, bbox = tracker.update(frame)

    # 如果跟踪成功，则绘制跟踪框
    if success:
        x, y, w, h = [int(i) for i in bbox]
        cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)

    # 显示当前帧
    cv2.imshow('Tracking', frame)

    # 按下ESC键退出
    if cv2.waitKey(1) == 27:
        break

# 释放资源
cap.release()
cv2.destroyAllWindows()
