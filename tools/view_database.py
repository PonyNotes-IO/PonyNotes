#!/usr/bin/env python3
"""
PonyNotes SQLite 数据库查看工具

这个工具可以帮助你查看和探索PonyNotes项目中的SQLite数据库。
使用方法：
1. python3 tools/view_database.py list - 列出所有数据库文件
2. python3 tools/view_database.py inspect <db_path> - 查看数据库结构和数据
3. python3 tools/view_database.py query <db_path> <sql> - 执行SQL查询
"""

import os
import sqlite3
import sys
import json
from pathlib import Path
from datetime import datetime
import argparse

# PonyNotes 数据库路径模式
DB_PATTERNS = [
    "~/Library/Application Support/com.appflowy.appflowy.flutter/ponynotes_data_dev*",
    "~/Library/Application Support/com.appflowy.appflowy.flutter/ponynotes_data*"
]

def find_databases():
    """查找所有PonyNotes数据库文件"""
    databases = []
    
    # 使用find命令查找所有.db文件
    base_paths = [
        os.path.expanduser("~/Library/Application Support/com.appflowy.appflowy.flutter")
    ]
    
    for base_path in base_paths:
        if os.path.exists(base_path):
            for root, dirs, files in os.walk(base_path):
                for file in files:
                    if file.endswith('.db'):
                        full_path = os.path.join(root, file)
                        databases.append(full_path)
    
    return databases

def list_databases():
    """列出所有数据库文件"""
    databases = find_databases()
    
    print("🗄️  PonyNotes SQLite 数据库文件：\n")
    
    if not databases:
        print("❌ 未找到数据库文件")
        return
    
    # 按类型分组
    main_dbs = []
    cache_dbs = []
    vector_dbs = []
    
    for db in databases:
        if 'flowy-database.db' in db:
            main_dbs.append(db)
        elif 'cache.db' in db:
            cache_dbs.append(db)
        elif 'vector.db' in db:
            vector_dbs.append(db)
    
    if main_dbs:
        print("📊 主数据库文件 (flowy-database.db):")
        for i, db in enumerate(main_dbs, 1):
            size = get_file_size(db)
            mtime = get_file_mtime(db)
            print(f"  {i}. {db}")
            print(f"     大小: {size}, 修改时间: {mtime}")
        print()
    
    if cache_dbs:
        print("🗃️  缓存数据库文件 (cache.db):")
        for i, db in enumerate(cache_dbs, 1):
            size = get_file_size(db)
            mtime = get_file_mtime(db)
            print(f"  {i}. {db}")
            print(f"     大小: {size}, 修改时间: {mtime}")
        print()
    
    if vector_dbs:
        print("🔍 向量数据库文件 (vector.db):")
        for i, db in enumerate(vector_dbs, 1):
            size = get_file_size(db)
            mtime = get_file_mtime(db)
            print(f"  {i}. {db}")
            print(f"     大小: {size}, 修改时间: {mtime}")

def get_file_size(filepath):
    """获取文件大小"""
    try:
        size = os.path.getsize(filepath)
        if size < 1024:
            return f"{size} B"
        elif size < 1024 * 1024:
            return f"{size / 1024:.1f} KB"
        else:
            return f"{size / (1024 * 1024):.1f} MB"
    except:
        return "未知"

def get_file_mtime(filepath):
    """获取文件修改时间"""
    try:
        mtime = os.path.getmtime(filepath)
        return datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
    except:
        return "未知"

def inspect_database(db_path):
    """查看数据库结构和数据"""
    if not os.path.exists(db_path):
        print(f"❌ 数据库文件不存在: {db_path}")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        print(f"🔍 检查数据库: {db_path}\n")
        
        # 获取所有表
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        if not tables:
            print("❌ 数据库中没有表")
            return
        
        print(f"📋 找到 {len(tables)} 个表：\n")
        
        for table in tables:
            table_name = table[0]
            print(f"📊 表: {table_name}")
            
            # 获取表结构
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            
            print("   列:")
            for col in columns:
                nullable = "NULL" if col[3] == 0 else "NOT NULL"
                default = f" DEFAULT {col[4]}" if col[4] is not None else ""
                pk = " PRIMARY KEY" if col[5] == 1 else ""
                print(f"     - {col[1]} ({col[2]}) {nullable}{default}{pk}")
            
            # 获取记录数
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                count = cursor.fetchone()[0]
                print(f"   记录数: {count}")
                
                # 如果记录数少于10，显示一些示例数据
                if 0 < count <= 10:
                    cursor.execute(f"SELECT * FROM {table_name} LIMIT 5")
                    rows = cursor.fetchall()
                    print("   示例数据:")
                    for row in rows:
                        row_dict = dict(row)
                        # 截断长字段
                        for key, value in row_dict.items():
                            if isinstance(value, str) and len(value) > 50:
                                row_dict[key] = value[:50] + "..."
                        print(f"     {json.dumps(row_dict, ensure_ascii=False, default=str)}")
                
            except Exception as e:
                print(f"   ❌ 查询记录数失败: {e}")
            
            print()
        
        conn.close()
        
    except Exception as e:
        print(f"❌ 打开数据库失败: {e}")

def execute_query(db_path, sql):
    """执行SQL查询"""
    if not os.path.exists(db_path):
        print(f"❌ 数据库文件不存在: {db_path}")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        
        print(f"🔍 在数据库 {db_path} 中执行查询:")
        print(f"SQL: {sql}\n")
        
        cursor.execute(sql)
        
        if sql.strip().upper().startswith('SELECT'):
            rows = cursor.fetchall()
            if rows:
                print(f"📊 查询结果 ({len(rows)} 行):\n")
                for i, row in enumerate(rows, 1):
                    row_dict = dict(row)
                    print(f"{i}. {json.dumps(row_dict, ensure_ascii=False, default=str, indent=2)}")
                    if i < len(rows):
                        print()
            else:
                print("📊 查询结果: 无数据")
        else:
            conn.commit()
            print(f"✅ 查询执行成功，影响行数: {cursor.rowcount}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ 查询执行失败: {e}")

def main():
    parser = argparse.ArgumentParser(description='PonyNotes SQLite 数据库查看工具')
    subparsers = parser.add_subparsers(dest='command', help='可用命令')
    
    # list 命令
    subparsers.add_parser('list', help='列出所有数据库文件')
    
    # inspect 命令
    inspect_parser = subparsers.add_parser('inspect', help='查看数据库结构和数据')
    inspect_parser.add_argument('db_path', help='数据库文件路径')
    
    # query 命令
    query_parser = subparsers.add_parser('query', help='执行SQL查询')
    query_parser.add_argument('db_path', help='数据库文件路径')
    query_parser.add_argument('sql', help='要执行的SQL语句')
    
    args = parser.parse_args()
    
    if args.command == 'list':
        list_databases()
    elif args.command == 'inspect':
        inspect_database(args.db_path)
    elif args.command == 'query':
        execute_query(args.db_path, args.sql)
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
