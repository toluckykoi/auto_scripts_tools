#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : 2025-02-01 19:51:09
# @version     : python3
# @Update time :
# @Description : MQTT客户端封装
'''

import paho.mqtt.client as mqtt
import uuid
import time
import threading
import queue
import json
import ssl
from typing import Any, Optional, Dict, Callable
from queue import Queue
from concurrent.futures import ThreadPoolExecutor


class MQTTError(Exception):
    """MQTT基础异常"""

class ConnectionFailedError(MQTTError):
    """连接失败异常"""

class PublishFailedError(MQTTError):
    """发布失败异常"""

class SubscribeFailedError(MQTTError):
    """订阅失败异常"""

class EnhancedMQTTClient:
    def __init__(
        self,
        host: str,
        port: int = None,
        username: str = None,
        password: str = None,
        client_id: str = None,
        websocket_path: str = "/mqtt",
        auto_reconnect: bool = True,
        reconnect_attempts: int = 5,
        reconnect_delay: int = 5,
        auto_json: bool = True,
        max_workers: int = 5,
        scheme: str = "tcp",
        mqtt_logger: bool = False,
    ):
        """
        增强型MQTT客户端
        
        :param host: 服务器地址
        :param port: 端口号
        :param username: 用户名
        :param password: 密码
        :param client_id: 客户端ID
        :param websocket_path: WebSocket路径
        :param auto_reconnect: 自动重连
        :param reconnect_attempts: 最大重连次数
        :param reconnect_delay: 重连延迟基准时间
        :param auto_json: 自动JSON编解码
        :param max_workers: 异步处理线程数
        :param scheme: 协议模式，可选'mqtt', 'mqtts', 'ws', 或 'wss'
        :param mqtt_logger: 是否启用MQTT日志
        """
        # 连接配置
        self._host = host
        self._port = port
        self._username = username
        self._password = password
        self.websocket_path = websocket_path
        self.scheme = scheme
        self.mqtt_logger = mqtt_logger
        
        # 客户端配置
        self.client_id = client_id or f"mqttlib_{uuid.uuid4().hex[:6]}"
        self.auto_json = auto_json
        self.keepalive = 60
        
        # 重连配置
        self.auto_reconnect = auto_reconnect
        self.reconnect_attempts = reconnect_attempts
        self.reconnect_delay = reconnect_delay
        self._reconnect_count = 0
        self._manual_disconnect = False
        
        # 异步处理
        self.executor = ThreadPoolExecutor(max_workers=max_workers)
        self.offline_queue = Queue()
        
        # 主题路由
        self.topic_handlers = {}
        
        # 状态管理
        self._connect_event = threading.Event()
        self._connection_error = None
        self._stop_event = threading.Event()
        self._connect_status = queue.Queue()
        
        # 初始化客户端
        if self.scheme == "mqtt":
            self._port = port or 1883
            transport = "tcp"
        elif self.scheme == "mqtts":
            self._port = port or 8883
            transport = "tcp"
        elif self.scheme == "ws":
            self._port = port or 8083
            transport = "websockets"
        elif self.scheme == "wss":
            self._port = port or 8084
            transport = "websockets"
        else:
            raise ValueError("不支持的协议模式，请选择'mqtt', 'mqtts', 'ws', 或 'wss'")

        self.client = mqtt.Client(
            client_id=self.client_id,
            transport=transport
        )
        self._configure_client()

    def _configure_client(self):
        """配置客户端参数"""
        # WebSocket配置
        self.client.ws_set_options(path=self.websocket_path)
        
        # 认证配置
        if self._username and self._password:
            self.client.username_pw_set(self._username, self._password)
        
        # 回调绑定
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect
        self.client.on_message = self._on_message
        if self.mqtt_logger:
            self.client.on_log = self._on_log
        
        # TLS配置
        self.tls_enabled = False

    def enable_tls(
        self,
        ca_certs: str = None,
        certfile: str = None,
        keyfile: str = None,
        tls_version: int = ssl.PROTOCOL_TLS,
        ciphers: str = None
    ):
        """启用TLS加密"""
        if self.scheme in ["mqtts", "wss"]:
            self.client.tls_set(
                ca_certs=ca_certs,        # CA证书路径
                certfile=certfile,        # 客户端证书路径（可选）
                keyfile=keyfile,          # 客户端密钥路径（可选）
                tls_version=tls_version,  # 指定使用的 TLS 版本
                ciphers=ciphers           # 指定使用的加密算法
            )
            self.client.tls_insecure_set(False)
            self.tls_enabled = True
        else:
            raise ValueError("当前协议不需要TLS加密!")

    def _on_connect(self, client, userdata, flags, rc):
        """连接回调"""
        if rc == 0:
            self._connect_event.set()
            self._reconnect_count = 0
            self._connect_status.put(True)
            print(f"[INFO] 成功连接到 {self._host}:{self._port}")
            
            # 连接成功后订阅所有已注册的主题
            for topic, (qos, _) in self.topic_handlers.items():
                result, mid = self.client.subscribe(topic, qos)
                if result == mqtt.MQTT_ERR_SUCCESS:
                    print(f"[INFO] 已恢复订阅: {topic} (QoS {qos})")
                else:
                    print(f"[ERROR] 订阅恢复失败: {topic} - {mqtt.error_string(result)}")
        else:
            error_msg = mqtt.connack_string(rc)
            self._connection_error = error_msg
            self._connect_event.set()
            self._connect_status.put(False)
            print(f"[ERROR] 连接失败: {error_msg}")

    def _on_disconnect(self, client, userdata, rc):
        """断开连接回调"""
        print(f"[WARNING] 连接断开，代码: {rc}")
        self._connect_event.clear()
        if not self._manual_disconnect and self.auto_reconnect:
            self._start_reconnect()

    def _on_message(self, client, userdata, msg):
        """异步消息处理"""
        self.executor.submit(self._process_message, msg)

    def _process_message(self, msg):
        """消息处理流水线"""
        try:
            # 解码消息
            payload = self._decode_payload(msg.payload)
            
            # 路由消息
            for pattern, (_, handler) in self.topic_handlers.items():
                if mqtt.topic_matches_sub(pattern, msg.topic):
                    handler(msg.topic, payload)
                    break
            else:
                print(f"[WARNING] 未注册的话题: {msg.topic}")
        except Exception as e:
            print(f"[ERROR] 消息处理失败: {str(e)}")

    def _decode_payload(self, payload):
        """解码消息内容"""
        try:
            decoded = payload.decode('utf-8')
            if self.auto_json:
                try:
                    return json.loads(decoded)
                except json.JSONDecodeError:
                    return decoded
            return decoded
        except UnicodeDecodeError:
            return payload

    def _on_log(self, client, userdata, level, buf):
        """日志回调"""
        log_levels = {
            mqtt.MQTT_LOG_DEBUG: "[DEBUG]",
            mqtt.MQTT_LOG_INFO: "[INFO]",
            mqtt.MQTT_LOG_WARNING: "[WARNING]",
            mqtt.MQTT_LOG_ERR: "[ERROR]",
        }

        prefix = log_levels.get(level, "[UNKNOWN]")
        print(f"{prefix} MQTT 日志: {buf}")

    def connect(self, timeout: int = 10):
        """建立连接"""
        try:
            self._stop_event.clear()
            self._manual_disconnect = False
            self.client.connect(
                self._host,
                self._port,
                keepalive=self.keepalive
            )
            self.client.loop_start()
            
            if not self._connect_event.wait(timeout):
                raise ConnectionFailedError("连接超时")
            
            if self._connection_error:
                raise ConnectionFailedError(self._connection_error)
                
        except Exception as e:
            print(f"[ERROR] 连接失败: {str(e)}")
            raise ConnectionFailedError(str(e))

    def disconnect(self):
        """断开连接"""
        self._manual_disconnect = True
        self._stop_event.set()
        
        # 清理客户端资源
        self.client.loop_stop()
        self.client.disconnect()
        print("[INFO] 结束.")

    def _start_reconnect(self):
        """启动自动重连"""
        if self._stop_event.is_set():
            return

        if self.reconnect_attempts > 0 and self._reconnect_count >= self.reconnect_attempts:
            print("[ERROR] 达到最大重连次数")
            return

        self._reconnect_count += 1
        delay = min(self.reconnect_delay * 2 ** self._reconnect_count, 300)
        print(f"[INFO] {delay}秒后尝试第{self._reconnect_count}次重连...")
        
        # 使用可中断的等待
        if not self._stop_event.wait(delay):
            try:
                self.connect()
            except ConnectionFailedError:
                self._start_reconnect()

    def add_handler(self, topic: str, callback: Callable, qos: int = 0):
        """注册话题预处理"""
        self.topic_handlers[topic] = (qos, callback)
        if self.is_connected:
            # 如果已连接，立即订阅
            result, mid = self.client.subscribe(topic, qos)
            if result != mqtt.MQTT_ERR_SUCCESS:
                raise SubscribeFailedError(f"订阅失败: {mqtt.error_string(result)}")
            print(f"[INFO] 成功订阅: {topic} (QoS {qos})")
        else:
            print(f"[INFO] 注册话题预处理，将在连接成功后订阅: {topic}")

    def publish(self, topic: str, payload: Any, qos: int = 0, retain: bool = False) -> mqtt.MQTTMessageInfo:
        """发布消息"""
        if not self.is_connected:
            if self.auto_reconnect:
                self.offline_queue.put((topic, payload))
                print("[WARNING] 当前未连接，消息已加入离线队列")
                return
            raise PublishFailedError("未连接到MQTT服务器")

        # JSON序列化
        if self.auto_json and isinstance(payload, (dict, list)):
            try:
                payload = json.dumps(payload, ensure_ascii=False)
            except TypeError as e:
                raise ValueError(f"JSON序列化失败: {str(e)}")

        try:
            info = self.client.publish(topic, payload, qos=qos, retain=retain)
            if qos > 0:
                info.wait_for_publish(timeout=5)
                if not info.is_published():
                    raise PublishFailedError("消息确认超时")
            return info
        except Exception as e:
            raise PublishFailedError(str(e))

    def publish_batch(self, messages: list):
        """批量发布消息"""
        results = []
        for topic, payload in messages:
            try:
                results.append(self.publish(topic, payload))
            except PublishFailedError as e:
                print(f"[ERROR] 消息发布失败: {topic} - {str(e)}")
        return results

    def process_offline_queue(self):
        """处理离线消息队列"""
        while not self.offline_queue.empty():
            topic, payload = self.offline_queue.get()
            try:
                self.publish(topic, payload)
                print(f"[INFO] 成功发送离线消息: {topic}")
            except PublishFailedError:
                self.offline_queue.put((topic, payload))
                break

    @property
    def is_connected(self) -> bool:
        """连接状态"""
        return self._connect_event.is_set()


# 示例
if __name__ == "__main__":
    def temperature_handler(topic: str, data: dict):
        print(f"温度数据更新: {data['value']}℃")

    def status_handler(topic: str, message: str):
        print(f"系统状态: {message}")
    
    def device_handler(topic: str, message: str):
        print(f"设备状态: {message}")

    # 初始化客户端
    client = EnhancedMQTTClient(
        host="broker.emqx.io",
        port=8083,
        scheme="ws",
        # username="admin",
        # password="admin",
        auto_reconnect=True,
        reconnect_attempts=3
    )

    # 先注册处理器（此时未连接，不会立即订阅，不推荐此方法）
    # client.add_handler("sensors/temperature", temperature_handler, qos=1)
    
    try:
        # 启用TLS
        # client.enable_tls(ca_certs="broker.emqx.io-ca.crt")

        # 建立连接（连接成功后会自动订阅已注册的主题）
        client.connect()
        print(f"[INFO] MQTT连接状态: {client._connect_status.get()}")

        # 订阅消息
        client.add_handler("device/status", device_handler, qos=0)
        client.add_handler("sensors/temperature", temperature_handler, qos=1)
        client.add_handler("system/status", status_handler, qos=0)
        
        # 模拟程序耗时
        time.sleep(2)

        # 发布测试消息
        client.publish("sensors/temperature", {"value": 25.6, "unit": "℃"})
        client.publish("system/status", "operational")
        client.publish("device/status", "online")
        
        # 保持连接并处理消息
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        client.disconnect()
    except Exception as e:
        print(f"[ERROR] 发生错误: {str(e)}")
        client.disconnect()
