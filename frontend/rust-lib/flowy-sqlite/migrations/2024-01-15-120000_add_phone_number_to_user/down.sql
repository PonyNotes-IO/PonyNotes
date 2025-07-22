-- This file should undo anything in `up.sql`
-- 移除phone_number字段 (使用SQLite兼容的方式)

-- 禁用外键约束
PRAGMA foreign_keys=off;

-- 创建临时表，不包含phone_number字段，保持email的当前状态
CREATE TABLE user_table_temp (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    icon_url TEXT NOT NULL DEFAULT '',
    token TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',  -- 保持原始的NOT NULL约束
    auth_type INTEGER NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL DEFAULT 0
);

-- 复制数据到临时表（不包括phone_number，处理email可能为null的情况）
INSERT INTO user_table_temp 
SELECT id, name, icon_url, token, COALESCE(email, ''), auth_type, updated_at 
FROM user_table;

-- 删除原表
DROP TABLE user_table;

-- 重命名临时表
ALTER TABLE user_table_temp RENAME TO user_table;

-- 恢复外键约束
PRAGMA foreign_keys=on; 