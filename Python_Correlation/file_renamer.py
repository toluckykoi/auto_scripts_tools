#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : 2025-01-29 15:27:14
# @version     : python3
# @Update time :
# @Description : 文件批量重命名工具
'''

import os
import argparse
import sys
from typing import List, Optional


class FileRenamer:
    """文件批量重命名工具"""
    def __init__(self, path: str):
        if not os.path.exists(path):
            raise FileNotFoundError(f"路径不存在: {path}")
        self.path = os.path.abspath(path)
        self.files = os.listdir(self.path)

    def rename(
        self,
        prefix: str = "file",
        mode: str = "numeric",
        start_num: int = 1,
        custom_format: Optional[str] = None,
        specific_files: Optional[List[str]] = None,
        dry_run: bool = False
    ) -> None:
        """
        执行重命名操作
        :param prefix: 文件名前缀
        :param mode: 命名模式 (numeric/type/custom)
        :param start_num: 起始序号
        :param custom_format: 自定义格式字符串 (需包含{num}和{ext})
        :param specific_files: 指定要处理的文件列表
        :param dry_run: 试运行模式（不实际修改）
        """
        counter = start_num
        for filename in self.files:
            # 处理特定文件过滤
            if specific_files and filename not in specific_files:
                continue

            old_path = os.path.join(self.path, filename)
            if os.path.isfile(old_path):
                name, ext = os.path.splitext(filename)
                ext = ext.lower()

                # 生成新文件名
                if mode == "numeric":
                    new_name = f"{prefix}_{counter:03d}{ext}"
                elif mode == "type":
                    new_name = f"{prefix}_{ext[1:]}_{counter:03d}{ext}"
                elif mode == "custom":
                    if not custom_format:
                        raise ValueError("自定义模式需要提供custom_format参数")
                    new_name = custom_format.format(num=counter, ext=ext)
                else:
                    raise ValueError(f"不支持的命名模式: {mode}")

                new_path = os.path.join(self.path, new_name)
                
                # 处理文件名冲突
                if os.path.exists(new_path):
                    raise FileExistsError(f"文件名冲突: {new_path}")

                # 执行重命名
                if not dry_run:
                    os.rename(old_path, new_path)
                print(f"[{'模拟' if dry_run else '实际'}] 重命名: {filename} -> {new_name}")
                counter += 1

def main():
    # 命令行参数解析
    parser = argparse.ArgumentParser(description="文件批量重命名工具")
    parser.add_argument("path", help="目标文件夹路径")
    parser.add_argument("-p", "--prefix", default="file", help="文件名前缀")
    parser.add_argument("-m", "--mode", choices=["numeric", "type", "custom"], default="numeric",
                        help="命名模式: numeric(数字序号), type(包含类型), custom(自定义格式)")
    parser.add_argument("-s", "--start", type=int, default=1, help="起始序号")
    parser.add_argument("-f", "--format", help="自定义格式字符串 (示例: '剧集_{num:03d}{ext}')")
    parser.add_argument("-sf", "--specific-files", nargs="+", help="指定要处理的文件列表")
    parser.add_argument("-d", "--dry-run", action="store_true", help="试运行模式")
    args = parser.parse_args()

    try:
        renamer = FileRenamer(args.path)
        renamer.rename(
            prefix=args.prefix,
            mode=args.mode,
            start_num=args.start,
            custom_format=args.format,
            specific_files=args.specific_files,
            dry_run=args.dry_run
        )
    except Exception as e:
        print(f"错误发生: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    """
    # 基本用法
    python renamer.py "/path/to/files" -p 视频 -m numeric

    # 自定义格式
    python renamer.py "/path/to/files" -m custom -f "第{num}集{ext}"

    # 模拟运行(第一次使用建议试运行先)：
    python renamer.py "/path/to/files" -m custom -f "file_test_{num}{ext}" -d
    
    # 指定文件试运行
    python renamer.py "/path/to/files" -sf file1.txt file2.jpg -d
    """
    main()

    # 实例化方式
    # renamer = FileRenamer(r"/path/to/files")

    # 数字序号模式（起始编号为1）
    # renamer.rename(prefix="旅游视频", mode="numeric")

    # # 文件类型模式（仅处理jpg/png）
    # renamer.rename(
    #     prefix="照片",
    #     mode="type",
    #     specific_files=[f for f in renamer.files if f.lower().endswith((".jpg", ".png"))]
    # )

    # 完全自定义格式
    # renamer.rename(
    #     mode="custom",
    #     custom_format="家庭相册_{num:03d}{ext}",
    #     start_num=100,
    #     dry_run=True
    # )
