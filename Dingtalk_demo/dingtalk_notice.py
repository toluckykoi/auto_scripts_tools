import requests
import time
import urllib
import hmac
import hashlib
import base64
import json
from envparse import env
import os
env.read_envfile()


WEBHOOK = os.environ.get('WEBHOOK')
SECRET=os.environ.get('SECRET')

class DingTalkPushUtil:
    def __init__(self):
        self.headers = {'Content-Type': 'application/json'}

    def getDingUrl(self):
        timestamp = round(time.time()*1000)
        secret_enc = SECRET.encode("utf-8")
        string_to_sign = '{}\n{}'.format(timestamp, SECRET)
        string_to_sign_enc = string_to_sign.encode('utf-8')
        hmac_code = hmac.new(secret_enc, string_to_sign_enc, digestmod=hashlib.sha256).digest()
        sign = urllib.parse.quote_plus(base64.b64encode(hmac_code))
        dingUrl ="{}{}{}{}{}".format(WEBHOOK,"&timestamp=",timestamp,"&sign=",sign)
        return dingUrl

    def send_text(self,content:str):
        """
        发送文本
        @param content:str
        """
        data = {"msgtype":"text","text":{"content":content}}
        return requests.post(
            url=self.getDingUrl(),
            data=json.dumps(data),
            headers=self.headers
        )

    def send_md(self,title,content):
        """
        发送Markdown文本
        @param title: str, 标题
        @param content: str, 文本内容
        """
        data = {"msgtype": "markdown", "markdown": {"title": title, "text": content}}
        return requests.post(
            url=self.getDingUrl(),
            data=json.dumps(data),
            headers=self.headers
        )

# 测试:
# if __name__ == "__main__":
#     ding = DingTalkPushUtil()

#     # 发送文本消息
#     response = ding.send_text("这是一条测试消息")
#     print(response.json())

#     # 发送 Markdown 消息
#     response = ding.send_md("测试标题", "### 这是一条 Markdown 消息\n- 项目1\n- 项目2")
#     print(response.json())