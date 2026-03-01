# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

### Security

## [1.0.1] - 2026-03-02

### Added

- 安装 Docker 时同时安装 docker-compose
- pip 初始化脚本
- debian 最小系统 sudo 初始化
- 自动挂载磁盘脚本
- Linux 一键初始化脚本桌面版本
- boot-repair 安装脚本
- ubuntu 22 ch340X 修复脚本
- rustdesk 一键安装和网络优先级设置
- mqtt 话题活跃度检查功能
- Python 封装库使用说明文档
- Linux 虚拟串口脚本
- 快捷一键脚本执行功能
- gnome 桌面壁纸自动切换（随机/顺序）
- ubuntu 源镜像 arm 架构支持
- docker 加速源、fedora 源支持
- mapviz 依赖安装脚本
- 一键编译安装 opencv
- rosdep 加速源
- crontab 定时任务管理
- python 虚拟环境部署脚本
- 内网穿透软件部署整合
- opencv3.4.5 编译脚本
- Docker Ros 环境
- 虚拟 CAN（支持 CAN FD 和分段发送）
- 虚拟内存管理
- 一键更换系统源脚本
- Docker NVIDIA 调用支持
- chrome 和 edge 直接下载安装包安装方式

### Changed

- 优化新增更新修复逻辑
- 优化 conda 安装配置
- 优化 Linux 桌面软件安装
- 优化一键初始化脚本用户交互
- 更新宝塔安装命令
- 更新 debian sudo 配置
- 更新 ROS 依赖
- 配置文件统一管理

### Fixed

- 修复 upgrade 交互界面选择问题
- 修复 ext4 磁盘挂载和普通用户写入权限问题
- 修复 boot-repair 依赖安装顺序问题
- 替换失效的 ROS 清华源
- 修复 ROS 安装路径处理问题
- 修复 sudo 权限问题
- 修复 emqx 安装提示信息
- 修复快捷脚本 git 命令检测
- 修复 virtualenv 安装问题
- 修复初始化脚本异常问题
- 修复终端英文状态字体安装失败问题
- 修复 chrome 和 edge 下载安装方式问题

### Removed

- 移除 conda 加速源（因网络问题）

## [1.0.0] - 2025-01-30

### Added

- 首个版本发布
