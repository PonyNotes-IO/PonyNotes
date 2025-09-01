# PonyNotes SQLite 数据库查看指南

## 概述

PonyNotes 使用多个 SQLite 数据库来存储应用数据，包括用户信息、工作区设置、聊天记录、文件上传记录等。这个指南将帮助你了解如何查看和分析这些数据库。

## 数据库类型

PonyNotes 主要使用三种类型的数据库：

### 1. 主数据库 (flowy-database.db)
- **用途**: 存储核心业务数据
- **位置**: `{user_data_dir}/{user_id}/flowy-database.db`
- **主要表结构**:
  - `user_table`: 用户基本信息
  - `user_workspace_table`: 工作区信息
  - `workspace_members_table`: 工作区成员
  - `chat_table`: 聊天会话
  - `chat_message_table`: 聊天消息
  - `upload_file_table`: 文件上传记录
  - `collab_snapshot`: 协作快照
  - `workspace_setting_table`: 工作区设置

### 2. 缓存数据库 (cache.db)
- **用途**: 存储应用配置和缓存数据
- **位置**: `{user_data_dir}/cache.db`
- **主要表结构**:
  - `kv_table`: 键值对存储，包含用户设置、主题配置、同步设置等

### 3. 向量数据库 (vector.db)
- **用途**: 存储 AI 相关的向量数据，用于语义搜索
- **位置**: `{user_data_dir}/vector.db`
- **功能**: 支持文档的向量化搜索和 AI 功能

## 数据库位置

### macOS
默认数据目录：
```
~/Library/Application Support/com.appflowy.appflowy.flutter/ponynotes_data_dev/
```

开发环境下可能有多个目录：
- `ponynotes_data_dev_localhost/`: 本地开发环境
- `ponynotes_data_dev_api.xiaomabiji.com/`: 连接小马笔记服务器
- `ponynotes_data_dev/`: 默认开发环境

### 数据目录结构
```
ponynotes_data_dev_localhost/
├── cache.db                    # 缓存数据库
├── vector.db                   # 向量数据库  
├── {user_id}/                  # 用户数据目录
│   ├── flowy-database.db       # 主数据库
│   └── collab_db/              # 协作数据
└── shortcuts/                  # 快捷方式
```

## 使用数据库查看工具

我们提供了一个 Python 工具来方便地查看数据库内容：

### 1. 列出所有数据库
```bash
python3 tools/view_database.py list
```

### 2. 查看数据库结构
```bash
python3 tools/view_database.py inspect "数据库文件路径"
```

### 3. 执行自定义查询
```bash
python3 tools/view_database.py query "数据库文件路径" "SELECT * FROM user_table"
```

## 常用查询示例

### 查看用户信息
```sql
SELECT * FROM user_table;
```

### 查看工作区信息
```sql
SELECT * FROM user_workspace_table;
```

### 查看聊天记录
```sql
SELECT chat_id, created_at, summary FROM chat_table ORDER BY created_at DESC;
```

### 查看聊天消息
```sql
SELECT 
    chat_id, 
    content, 
    created_at, 
    author_type,
    author_id 
FROM chat_message_table 
ORDER BY created_at DESC 
LIMIT 10;
```

### 查看应用配置
```sql
-- 在 cache.db 中执行
SELECT key, value FROM kv_table WHERE key LIKE '%appearance%';
```

### 查看同步配置
```sql
-- 在 cache.db 中执行
SELECT key, value FROM kv_table WHERE key LIKE '%cloud_config%';
```

## 重要数据表说明

### user_table
存储用户基本信息：
- `id`: 用户ID
- `name`: 用户名
- `email`: 邮箱（可为空）
- `auth_type`: 认证类型（0=匿名，1=邮箱等）
- `phone_number`: 手机号

### user_workspace_table
存储工作区信息：
- `id`: 工作区ID
- `name`: 工作区名称
- `uid`: 用户ID
- `workspace_type`: 工作区类型
- `member_count`: 成员数量

### chat_table
存储聊天会话：
- `chat_id`: 聊天ID
- `created_at`: 创建时间
- `metadata`: 元数据
- `rag_ids`: RAG配置ID列表
- `summary`: 会话摘要

### kv_table (在 cache.db 中)
存储配置信息：
- `appearance_settings`: 外观设置
- `af_user_cloud_config:{user_id}`: 用户云同步配置
- `appflowy_session_cache`: 会话缓存

## 数据库备份和维护

### 备份数据库
```bash
# 备份整个数据目录
cp -r "~/Library/Application Support/com.appflowy.appflowy.flutter/ponynotes_data_dev/" ~/Desktop/ponynotes_backup/
```

### 清理旧数据
数据库会自动进行迁移和清理，但如果需要手动清理：
1. 停止 PonyNotes 应用
2. 删除不需要的用户数据目录
3. 重新启动应用

## 故障排除

### 数据库锁定
如果遇到数据库锁定错误：
1. 确保 PonyNotes 应用已完全关闭
2. 检查是否有其他进程在访问数据库
3. 重启应用

### 数据丢失
如果数据丢失：
1. 检查是否有备份
2. 查看应用日志文件
3. 检查数据目录权限

### 性能问题
如果数据库查询较慢：
1. 检查数据库文件大小
2. 考虑重新索引
3. 清理无用的历史数据

## 开发者说明

### 数据库迁移
数据库结构变更通过 Diesel 迁移管理：
- 迁移文件位置: `frontend/rust-lib/flowy-sqlite/migrations/`
- 迁移记录表: `__diesel_schema_migrations`

### 添加新表
1. 在 `schema.rs` 中定义表结构
2. 创建迁移文件
3. 更新相关的 Rust 代码

### 调试建议
1. 使用提供的查看工具进行数据检查
2. 监控数据库文件大小变化
3. 定期检查迁移记录

## 安全注意事项

1. **敏感数据**: 数据库可能包含敏感信息，请妥善保管
2. **加密**: 支持数据加密，可在设置中启用
3. **权限**: 确保数据目录有正确的文件权限
4. **备份**: 定期备份重要数据

## 相关文件

- 数据库查看工具: `tools/view_database.py`
- 数据库配置: `frontend/appflowy_flutter/lib/workspace/application/settings/application_data_storage.dart`
- 表结构定义: `frontend/rust-lib/flowy-sqlite/src/schema.rs`
- 迁移文件: `frontend/rust-lib/flowy-sqlite/migrations/`
