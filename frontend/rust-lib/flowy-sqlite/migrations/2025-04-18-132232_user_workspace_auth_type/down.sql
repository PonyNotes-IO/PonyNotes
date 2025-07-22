-- This file should undo anything in `up.sql`

-- 1. 删除workspace设置表
DROP TABLE IF EXISTS workspace_setting_table;

-- 2. 恢复user_table的email字段为NOT NULL约束
-- 禁用外键约束
PRAGMA foreign_keys=off;

-- 备份当前数据
CREATE TABLE user_backup AS SELECT * FROM user_table;

-- 删除原表
DROP TABLE user_table;

-- 重新创建表，email恢复NOT NULL约束
CREATE TABLE user_table (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    icon_url TEXT NOT NULL DEFAULT '',
    token TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',  -- 恢复NOT NULL约束
    auth_type INTEGER NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL DEFAULT 0,
    phone_number TEXT
);

-- 从备份恢复数据，将null email转换为空字符串
INSERT INTO user_table (id, name, icon_url, token, email, auth_type, updated_at, phone_number)
SELECT 
    id,
    name,
    COALESCE(icon_url, ''),
    COALESCE(token, ''),
    COALESCE(email, ''),  -- null email转为空字符串
    COALESCE(auth_type, 0),
    COALESCE(updated_at, 0),
    phone_number
FROM user_backup;

-- 清理备份表
DROP TABLE user_backup;

-- 恢复外键约束
PRAGMA foreign_keys=on;

-- 3. 移除workspace_type列
-- 禁用外键约束
PRAGMA foreign_keys=off;

-- 创建临时表（没有workspace_type字段）
CREATE TABLE user_workspace_table_temp (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    uid BIGINT NOT NULL,
    created_at BIGINT NOT NULL,
    database_storage_id TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT '',
    member_count BIGINT NOT NULL DEFAULT 1,
    role INTEGER
);

-- 复制数据（排除workspace_type）
INSERT INTO user_workspace_table_temp 
SELECT id, name, uid, created_at, database_storage_id, icon, member_count, role
FROM user_workspace_table;

-- 删除原表
DROP TABLE user_workspace_table;

-- 重命名临时表
ALTER TABLE user_workspace_table_temp RENAME TO user_workspace_table;

-- 恢复外键约束
PRAGMA foreign_keys=on;
