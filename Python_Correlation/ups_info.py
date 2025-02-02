#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : 2025-02-02 16:09:53
# @version     : python3
# @Update time :
# @Description : UPS信息获取，用于后期处理
'''

from pynut2 import nut2 as PyNUT
import json


class UPSInfo:
    def __init__(self, nut_server='127.0.0.1', nut_port=3493, ups_name='my_ups_name'):
        """初始化UPSInfo实例"""
        self.nut_server = nut_server
        self.nut_port = nut_port
        self.ups_name = ups_name

    def build_nested_dict(self, d, keys, value):
        """辅助函数，用于递归构建嵌套字典"""
        if len(keys) == 1:
            d[keys[0]] = value
        else:
            if keys[0] not in d:
                d[keys[0]] = {}
            self.build_nested_dict(d[keys[0]], keys[1:], value)

    def get_ups_data(self):
        """获取UPS数据并返回JSON格式"""
        try:
            client = PyNUT.PyNUTClient(host=self.nut_server, port=self.nut_port)
            ups_vars = client.list_vars(self.ups_name)
            
            # 组织数据为字典形式
            ups_data = {}
            for key, value in ups_vars.items():
                parts = key.split(':')
                self.build_nested_dict(ups_data, parts, value)
            
            # 返回JSON格式字符串
            return json.dumps(ups_data, indent=4)
        except Exception as e:
            # 返回错误信息的JSON
            error_response = {
                "error": "Failed to retrieve UPS data",
                "details": str(e)
            }
            return json.dumps(error_response, indent=4)

    def get_ups_data_as_dict(self):
        """获取UPS数据并返回字典格式"""
        try:
            client = PyNUT.PyNUTClient(host=self.nut_server, port=self.nut_port)
            ups_vars = client.list_vars(self.ups_name)
            
            # 组织数据为字典形式
            ups_data = {}
            for key, value in ups_vars.items():
                parts = key.split(':')
                self.build_nested_dict(ups_data, parts, value)
            
            # 返回字典
            return ups_data
        except Exception as e:
            # 返回错误信息的字典
            return {
                "error": "Failed to retrieve UPS data",
                "details": str(e)
            }

if __name__ == '__main__':
    # 示例调用，方便测试
    ups_info = UPSInfo(nut_server="192.168.100.220", nut_port=3493, ups_name="ups")
    print(ups_info.get_ups_data())
