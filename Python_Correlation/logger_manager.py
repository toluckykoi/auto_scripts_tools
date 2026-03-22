#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : 2025-01-30 22:37:24
# @version     : python3
# @Update time : 
# @Description : Log encapsulation library
'''

import os
import sys
import logging
import colorlog
from datetime import datetime
from logging.handlers import RotatingFileHandler


class CustomLogger:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self,
                log_folder = 'logs',
                log_level = logging.DEBUG,
                max_bytes = 20 * 1024 * 1024,
                backup_count = 3,
                enable_color = False,
                enable_save_log = True,
                enable_terminal_print = True,
                normal_log_name = 'normal.log',
                error_log_name = 'error.log'
                ):
        
        if not hasattr(self, '_initialized'):  # 避免重复初始化
            self.log_folder = log_folder
            self.log_level = log_level
            self.max_bytes = max_bytes
            self.backup_count = backup_count
            self.enable_color = enable_color
            self.enable_save_log = enable_save_log
            self.enable_terminal_print = enable_terminal_print
            self.normal_log_name = normal_log_name
            self.error_log_name = error_log_name
            self._setup_logging()
            self._initialized = True

    def _setup_logging(self):
        # 创建日志文件夹
        if not os.path.exists(self.log_folder):
            os.makedirs(self.log_folder)

        # 设置日志格式
        log_format = '[%(asctime)s] - %(caller_filename)s - %(caller_lineno)dline - %(levelname)s - %(message)s'
        formatter = logging.Formatter(log_format)

        # 设置控制台日志格式
        if self.enable_color:
            # 带颜色的控制台日志格式
            console_format = '[%(log_color)s%(asctime)s] - %(caller_filename)s - %(caller_lineno)dline - %(levelname)s - %(message)s'
            console_formatter = colorlog.ColoredFormatter(
                console_format,
                log_colors={
                    'DEBUG': 'white',
                    'INFO': 'white',
                    'WARNING': 'yellow',
                    'ERROR': 'red',
                    'CRITICAL': 'bold_red',
                }
            )
        else:
            # 不带颜色的控制台日志格式
            console_format = '[%(asctime)s] - %(caller_filename)s - %(caller_lineno)dline - %(levelname)s - %(message)s'
            console_formatter = logging.Formatter(console_format)

        # 设置普通日志（DEBUG、INFO、WARNING）
        self.normal_logger = logging.getLogger('normal_logger')
        self.normal_logger.setLevel(self.log_level)

        # 设置错误日志（ERROR、CRITICAL）
        self.error_logger = logging.getLogger('error_logger')
        self.error_logger.setLevel(logging.ERROR)

        # 移除所有现有的处理器，避免重复添加
        self.normal_logger.handlers.clear()
        self.error_logger.handlers.clear()

        # 添加文件日志处理器
        if self.enable_save_log:
            normal_handler = self._get_file_handler(self.normal_log_name, formatter)
            self.normal_logger.addHandler(normal_handler)

            error_handler = self._get_file_handler(self.error_log_name, formatter)
            self.error_logger.addHandler(error_handler)

        # 添加控制台日志处理器（同时添加到 normal_logger 和 error_logger）
        if self.enable_terminal_print:
            console_handler = logging.StreamHandler()
            console_handler.setFormatter(console_formatter)
            self.normal_logger.addHandler(console_handler)
            self.error_logger.addHandler(console_handler)

    def _get_file_handler(self, log_file, formatter):
        # 按天创建日志文件
        today = datetime.now().strftime('%Y%m%d')
        base_name, extension = os.path.splitext(log_file)
        daily_log_file = f"{base_name}_{today}{extension}"
        log_path = os.path.join(self.log_folder, daily_log_file)

        # 创建 RotatingFileHandler, 设置文件大小限制和备份数量
        handler = RotatingFileHandler(
            log_path,
            maxBytes=self.max_bytes,
            backupCount=self.backup_count,
            encoding='utf-8'
        )
        handler.setFormatter(formatter)
        return handler

    def _get_caller_info(self):
        """获取调用者的文件名和行号"""
        # 获取调用栈
        frame = sys._getframe(2)
        filename = os.path.basename(frame.f_code.co_filename)
        lineno = frame.f_lineno
        return filename, lineno

    def debug(self, message):
        filename, lineno = self._get_caller_info()
        self.normal_logger.debug(message, extra={'caller_filename': filename, 'caller_lineno': lineno})

    def info(self, message):
        filename, lineno = self._get_caller_info()
        self.normal_logger.info(message, extra={'caller_filename': filename, 'caller_lineno': lineno})

    def warning(self, message):
        filename, lineno = self._get_caller_info()
        self.normal_logger.warning(message, extra={'caller_filename': filename, 'caller_lineno': lineno})

    def error(self, message):
        filename, lineno = self._get_caller_info()
        self.error_logger.error(message, extra={'caller_filename': filename, 'caller_lineno': lineno})

    def critical(self, message):
        filename, lineno = self._get_caller_info()
        self.error_logger.critical(message, extra={'caller_filename': filename, 'caller_lineno': lineno})

logger = CustomLogger()
