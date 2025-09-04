-- Drop inbox table and related indexes
DROP INDEX IF EXISTS idx_inbox_source_type;
DROP INDEX IF EXISTS idx_inbox_is_clipped;
DROP INDEX IF EXISTS idx_inbox_is_read;
DROP INDEX IF EXISTS idx_inbox_created_at;
DROP INDEX IF EXISTS idx_inbox_workspace_id;
DROP TABLE IF EXISTS inbox_table;
