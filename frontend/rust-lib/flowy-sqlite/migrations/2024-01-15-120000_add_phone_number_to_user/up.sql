-- Your SQL goes here
-- 修改email字段为可空
ALTER TABLE user_table
ALTER COLUMN email DROP NOT NULL;

-- 添加phone_number字段
ALTER TABLE user_table
ADD COLUMN phone_number TEXT; 