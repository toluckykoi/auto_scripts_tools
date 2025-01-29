#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : 2025-01-28 15:32:37
# @version     : python3
# @Update time :
# @Description : 邮件通知Lib
'''

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from dotenv import load_dotenv
import os


class Mail:
    def __init__(self):
        # 加载 .env 文件
        load_dotenv()
        self.username = os.getenv('EMAIL_USERNAME')
        self.password = os.getenv('EMAIL_PASSWORD')
        self.mail_type = os.getenv('EMAIL_TYPE', '163').lower()
        self.smtp_port = int(os.getenv('SMTP_PORT', 25))
        self.smtp_server = self._get_smtp_server()

        # 检查是否成功加载配置
        if not self.username or not self.password:
            raise ValueError("请检查 .env 文件是否正确配置了 EMAIL_USERNAME 和 EMAIL_PASSWORD")

    def _get_smtp_server(self):
        """根据邮箱类型返回SMTP服务器地址"""
        if self.mail_type == '163':
            return 'smtp.163.com'
        elif self.mail_type == '126':
            return 'smtp.126.com'
        else:
            raise ValueError("不支持的邮箱类型，目前仅支持 '163' 和 '126'")

    def send_mail(self, to_email, subject, content, attachments=None):
        msg = MIMEMultipart()
        msg['From'] = self.username
        msg['To'] = to_email
        msg['Subject'] = subject

        # 添加邮件正文
        msg.attach(MIMEText(content, 'plain', 'utf-8'))

        # 添加附件
        if attachments:
            for attachment in attachments:
                try:
                    if not os.path.exists(attachment):
                        print(f"附件 {attachment} 不存在，跳过")
                        continue

                    filename = os.path.basename(attachment)
                    with open(attachment, 'rb') as file:
                        part = MIMEBase('application', 'octet-stream')
                        part.set_payload(file.read())
                    encoders.encode_base64(part)
                    part.add_header(
                        'Content-Disposition',
                        f'attachment; filename={filename}'
                    )
                    msg.attach(part)
                    print(f"附件 {filename} 添加成功")
                except Exception as e:
                    print(f"无法添加附件 {attachment}: {e}")

        # 连接SMTP服务器并发送邮件
        try:
            if self.smtp_port == 465:
                server = smtplib.SMTP_SSL(self.smtp_server, self.smtp_port)
            else:
                server = smtplib.SMTP(self.smtp_server, self.smtp_port)
                server.starttls()

            server.login(self.username, self.password)
            server.sendmail(self.username, to_email, msg.as_string())
            server.quit()
            print("邮件发送成功！")
        except Exception as e:
            print(f"邮件发送失败: {e}")


# 使用示例
# if __name__ == "__main__":
#     try:
#         mail = Mail()

#         mail.send_mail(
#             to_email='test@126.com',
#             subject='测试邮件',
#             content='这是一封测试邮件，包含附件。',
#             # attachments=['file1.txt', 'file2.jpg']  # 附件需要绝对路径
#         )
#     except ValueError as e:
#         print(e)