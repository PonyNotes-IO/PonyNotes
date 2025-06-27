-- This file should undo anything in `up.sql`
-- 恢复email字段为NOT NULL
ALTER TABLE user_table
ALTER COLUMN email SET NOT NULL;

-- 移除phone_number字段
ALTER TABLE user_table
DROP COLUMN phone_number; 