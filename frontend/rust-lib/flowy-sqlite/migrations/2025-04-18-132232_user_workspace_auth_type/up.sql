-- Your SQL goes here

-- 1. 添加workspace_type列到user_workspace_table
ALTER TABLE user_workspace_table
    ADD COLUMN workspace_type INTEGER NOT NULL DEFAULT 1;

-- 2. 简单地重建user_table，使用最基础的方法
-- 禁用外键约束
PRAGMA foreign_keys=off;

-- 备份当前数据到临时表
CREATE TABLE user_backup AS SELECT * FROM user_table;

-- 删除原表
DROP TABLE user_table;

-- 创建新的user_table结构
CREATE TABLE user_table (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT '',
    icon_url TEXT NOT NULL DEFAULT '',
    token TEXT NOT NULL DEFAULT '',
    email TEXT,  -- 设为nullable
    auth_type INTEGER NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL DEFAULT 0,
    phone_number TEXT
);

-- 从备份表恢复数据，只使用确定存在的字段
INSERT INTO user_table (id, name, icon_url, token, email, auth_type, updated_at, phone_number)
SELECT 
    id,
    name,
    COALESCE(icon_url, ''),
    COALESCE(token, ''),
    email,
    COALESCE(auth_type, 0),
    COALESCE(updated_at, 0),
    CASE 
        WHEN (SELECT COUNT(*) FROM pragma_table_info('user_backup') WHERE name='phone_number') > 0 
        THEN phone_number 
        ELSE NULL 
    END
FROM user_backup;

-- 清理备份表
DROP TABLE user_backup;

-- 恢复外键约束
PRAGMA foreign_keys=on;

-- 3. 根据user_table.auth_type回填workspace_type数据
UPDATE user_workspace_table
SET workspace_type = (SELECT COALESCE(ut.auth_type, 1)
                     FROM user_table ut
                     WHERE ut.id = CAST(user_workspace_table.uid AS TEXT))
WHERE EXISTS (SELECT 1
              FROM user_table ut
              WHERE ut.id = CAST(user_workspace_table.uid AS TEXT));

-- 4. 创建workspace设置表
CREATE TABLE IF NOT EXISTS workspace_setting_table (
    id TEXT PRIMARY KEY NOT NULL ,
    disable_search_indexing BOOLEAN DEFAULT FALSE NOT NULL ,
    ai_model TEXT DEFAULT "" NOT NULL
);