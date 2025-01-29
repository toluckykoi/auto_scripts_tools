#!/usr/bin/env python
# -*-coding:utf-8 -*-

'''
# @Author      ：幸运锦鲤
# @Time        : 2025-01-29 23:24:10
# @version     : python3
# @Update time :
# @Description : Mysql备份恢复工具
'''


import os
import subprocess
import argparse
from datetime import datetime
from pathlib import Path
import tempfile
import getpass
from dotenv import load_dotenv
from typing import List, Optional

class SecureDatabaseManager:
    @staticmethod
    def load_env():
        load_dotenv()

    def __init__(self, db_names: List[str], user: str, password: Optional[str] = None, host: str = "localhost", port: int = 3306):
        SecureDatabaseManager.load_env()
        self.db_names = db_names
        self.user = user or os.getenv("DB_USER")
        self.password = password or os.getenv("DB_PASSWORD")
        self.host = host or os.getenv("DB_HOST", "localhost")
        self.port = port or int(os.getenv("DB_PORT", 3306))
        self.backup_dir = Path.home() / "Backup" / "database"
        print(self.backup_dir)
        self._ensure_dir_exists()

    def _ensure_dir_exists(self):
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        self.backup_dir.chmod(0o700)

    def _generate_filename(self, db_name: str) -> str:
        timestamp = datetime.now().isoformat(timespec="seconds").replace(":", "")
        return f"{db_name}_backup_{timestamp}.sql"

    def _validate_database(self, db_name: str):
        try:
            cmd = ["mysql", "-u", self.user, f"-p{self.password}", "-h", self.host, "-P", str(self.port), "-e", f"USE {db_name}; SELECT 1;"]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        except subprocess.CalledProcessError as e:
            error = e.stderr.decode().lower()
            if "unknown database" in error:
                raise PermissionError(f"数据库 {db_name} 不存在")
            elif "access denied" in error:
                raise PermissionError("数据库访问被拒绝：无效凭据")
            else:
                raise ConnectionError(f"数据库连接失败：{error.strip()}")

    def backup(self) -> List[str]:
        backup_paths = []
        for db_name in self.db_names:
            self._validate_database(db_name)
            filename = self._generate_filename(db_name)
            backup_path = self.backup_dir / filename

            cmd = ["mysqldump", "-u", self.user, f"-p{self.password}", "-h", self.host, "-P", str(self.port),
                   "--single-transaction", "--routines", "--triggers", "--skip-add-drop-table", db_name]

            with open(backup_path, "wb") as f:
                process = subprocess.Popen(cmd, stdout=f, stderr=subprocess.PIPE)
                _, stderr = process.communicate()

            if process.returncode != 0:
                self._remove_failed_backup(backup_path)
                raise RuntimeError(f"备份失败：{stderr.decode().strip()}")

            backup_path.chmod(0o600)
            backup_paths.append(str(backup_path))
            self._clean_old_backups(db_name)

        return backup_paths

    def _clean_old_backups(self, db_name: str):
        pattern = f"{db_name}_backup_*.sql"
        backups = sorted(self.backup_dir.glob(pattern), key=lambda x: x.stat().st_mtime, reverse=True)
        for old_backup in backups[int(os.getenv("DB_NUM_VERSION")):]:
            try:
                old_backup.unlink()
                # print(f"Deleted old backup file: {old_backup}")
            except PermissionError:
                continue

    def _remove_failed_backup(self, path: Path):
        """安全删除失败备份"""
        try:
            path.unlink(missing_ok=True)
        except PermissionError:
            pass

    def _create_temp_config(self):
        """创建安全临时配置文件"""
        config_content = f"""
[client]
user = {self.user}
password = {self.password}
host = {self.host}
port = {self.port}
"""
        # 使用更安全的命名临时文件
        fd, self.temp_config = tempfile.mkstemp(prefix="mysql_", text=True)
        with os.fdopen(fd, 'w') as f:
            f.write(config_content)
        # 严格文件权限 (仅所有者可读)
        os.chmod(self.temp_config, 0o600)

    def _remove_temp_config(self):
        """安全清理临时配置"""
        if self.temp_config and os.path.exists(self.temp_config):
            try:
                os.remove(self.temp_config)
            except PermissionError:
                pass  # 防止权限问题导致程序中断

    def restore(self, backup_file: str):
        """安全恢复数据库"""
        if not (backup_path := Path(backup_file)).exists():
            raise FileNotFoundError("备份文件不存在")
        
        if backup_path.suffix != ".sql":
            raise ValueError("无效备份文件格式，必须为 .sql 文件")

        self._create_temp_config()
        try:
            # 验证数据库可写
            self._validate_database(self.db_names)
            cmd = ["mysql", f"--defaults-extra-file={self.temp_config}", self.db_names]
            
            with open(backup_path, "rb") as f:
                process = subprocess.Popen(
                    cmd,
                    stdin=f,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.PIPE
                )
                _, stderr = process.communicate()
                
            if process.returncode != 0:
                raise RuntimeError(f"恢复失败：{stderr.decode().strip()}")
        finally:
            self._remove_temp_config()

def parse_args():
    parser = argparse.ArgumentParser(description="数据库备份恢复工具", formatter_class=argparse.RawTextHelpFormatter)
    subparsers = parser.add_subparsers(dest="command", required=True)

    # 备份命令
    backup_parser = subparsers.add_parser("backup", help="执行数据库备份")
    backup_parser.add_argument("--dbs", nargs='+', required=True, help="要备份的数据库名称列表")
    backup_parser.add_argument("--user", required=True, help="数据库用户")
    backup_parser.add_argument("--password", nargs="?", const="", help="密码（建议使用环境变量或交互输入）")
    backup_parser.add_argument("--host", default="localhost", help="数据库主机")
    backup_parser.add_argument("--port", type=int, default=3306, help="数据库端口")

    # 恢复命令保持不变
    restore_parser = subparsers.add_parser("restore", help="执行数据库恢复")
    restore_parser.add_argument("file", help="备份文件路径")
    restore_parser.add_argument("--db", required=True, help="目标数据库名称")
    restore_parser.add_argument("--user", required=True, help="数据库用户")
    restore_parser.add_argument("--password", nargs="?", const="", help="密码（建议使用环境变量或交互输入）")
    restore_parser.add_argument("--host", default="localhost", help="数据库主机")
    restore_parser.add_argument("--port", type=int, default=3306, help="数据库端口")

    return parser.parse_args()

def get_password_interactively() -> str:
    return getpass.getpass("请输入数据库密码：")

def main():
    args = parse_args()
    load_dotenv()

    try:
        password = os.getenv("DB_PASSWORD") or args.password or get_password_interactively()

        if args.command == "backup":
            manager = SecureDatabaseManager(
                db_names=args.dbs,
                user=args.user,
                password=password,
                host=args.host,
                port=args.port
            )
            backup_paths = manager.backup()
            for path in backup_paths:
                print(f"✅ 备份成功\n路径：{path}")

        elif args.command == "restore":
            manager = SecureDatabaseManager(
                db_names=args.db,
                user=args.user,
                password=password,
                host=args.host,
                port=args.port
            )
            manager.restore(args.file)
            print("✅ 数据库恢复成功")
        
        else:
            print("无效的命令")

    except Exception as e:
        print(f"❌ 操作失败：{str(e)}")
        exit(1)

if __name__ == "__main__":
    main()
