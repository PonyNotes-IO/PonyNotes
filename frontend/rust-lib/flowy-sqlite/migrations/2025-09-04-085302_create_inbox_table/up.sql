-- @ts-nocheck
-- Create inbox table for storing inbox items
CREATE TABLE inbox_table (
    id TEXT PRIMARY KEY NOT NULL,
    workspace_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    source_type INTEGER NOT NULL DEFAULT 0, -- 0: manual, 1: clipped, 2: imported, 3: shared
    source_url TEXT DEFAULT NULL, -- URL for clipped content
    file_url TEXT DEFAULT NULL, -- Associated file URL
    image_url TEXT DEFAULT NULL, -- Associated image URL
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_clipped BOOLEAN NOT NULL DEFAULT FALSE,
    is_starred BOOLEAN NOT NULL DEFAULT FALSE,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    tags TEXT DEFAULT NULL, -- JSON array of tags
    metadata TEXT DEFAULT NULL -- JSON metadata
);

-- Create index for better query performance
CREATE INDEX idx_inbox_workspace_id ON inbox_table (workspace_id);
CREATE INDEX idx_inbox_created_at ON inbox_table (created_at DESC);
CREATE INDEX idx_inbox_is_read ON inbox_table (is_read);
CREATE INDEX idx_inbox_is_clipped ON inbox_table (is_clipped);
CREATE INDEX idx_inbox_source_type ON inbox_table (source_type);
