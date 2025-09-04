use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use validator::Validate;

use crate::services::inbox_sql::{InboxTable, InboxSourceType, InboxItemMetadata};

#[derive(Debug, Default, Clone, ProtoBuf_Enum)]
pub enum InboxSourceTypePB {
  #[default]
  Manual = 0,
  Clipped = 1,
  Imported = 2,
  Shared = 3,
}

impl From<InboxSourceType> for InboxSourceTypePB {
  fn from(source_type: InboxSourceType) -> Self {
    match source_type {
      InboxSourceType::Manual => InboxSourceTypePB::Manual,
      InboxSourceType::Clipped => InboxSourceTypePB::Clipped,
      InboxSourceType::Imported => InboxSourceTypePB::Imported,
      InboxSourceType::Shared => InboxSourceTypePB::Shared,
    }
  }
}

impl From<InboxSourceTypePB> for InboxSourceType {
  fn from(source_type: InboxSourceTypePB) -> Self {
    match source_type {
      InboxSourceTypePB::Manual => InboxSourceType::Manual,
      InboxSourceTypePB::Clipped => InboxSourceType::Clipped,
      InboxSourceTypePB::Imported => InboxSourceType::Imported,
      InboxSourceTypePB::Shared => InboxSourceType::Shared,
    }
  }
}

impl From<i32> for InboxSourceTypePB {
  fn from(value: i32) -> Self {
    match value {
      0 => InboxSourceTypePB::Manual,
      1 => InboxSourceTypePB::Clipped,
      2 => InboxSourceTypePB::Imported,
      3 => InboxSourceTypePB::Shared,
      _ => InboxSourceTypePB::Manual,
    }
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct InboxItemMetadataPB {
  #[pb(index = 1, one_of)]
  pub author: Option<String>,
  
  #[pb(index = 2, one_of)]
  pub domain: Option<String>,
  
  #[pb(index = 3, one_of)]
  pub word_count: Option<i32>,
  
  #[pb(index = 4, one_of)]
  pub read_time: Option<i32>,
  
  #[pb(index = 5, one_of)]
  pub language: Option<String>,
  
  #[pb(index = 6, one_of)]
  pub custom_fields: Option<String>, // JSON string representation
}

impl From<InboxItemMetadata> for InboxItemMetadataPB {
  fn from(metadata: InboxItemMetadata) -> Self {
    InboxItemMetadataPB {
      author: metadata.author,
      domain: metadata.domain,
      word_count: metadata.word_count,
      read_time: metadata.read_time,
      language: metadata.language,
      custom_fields: metadata.custom_fields.map(|v| v.to_string()),
    }
  }
}

impl From<InboxItemMetadataPB> for InboxItemMetadata {
  fn from(metadata: InboxItemMetadataPB) -> Self {
    InboxItemMetadata {
      author: metadata.author,
      domain: metadata.domain,
      word_count: metadata.word_count,
      read_time: metadata.read_time,
      language: metadata.language,
      custom_fields: metadata.custom_fields.and_then(|s| serde_json::from_str(&s).ok()),
    }
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct InboxItemPB {
  #[pb(index = 1)]
  pub id: String,
  
  #[pb(index = 2)]
  pub workspace_id: String,
  
  #[pb(index = 3)]
  pub title: String,
  
  #[pb(index = 4)]
  pub content: String,
  
  #[pb(index = 5)]
  pub description: String,
  
  #[pb(index = 6)]
  pub source_type: InboxSourceTypePB,
  
  #[pb(index = 7)]
  pub is_read: bool,
  
  #[pb(index = 8)]
  pub is_starred: bool,
  
  #[pb(index = 9)]
  pub is_clipped: bool,
  
  #[pb(index = 10)]
  pub created_at: i64,
  
  #[pb(index = 11)]
  pub updated_at: i64,
  
  #[pb(index = 12, one_of)]
  pub metadata: Option<InboxItemMetadataPB>,
}

impl From<InboxTable> for InboxItemPB {
  fn from(table: InboxTable) -> Self {
    let metadata = table.get_metadata().map(|m| m.into());
    InboxItemPB {
      id: table.id,
      workspace_id: table.workspace_id,
      title: table.title,
      content: table.content,
      description: table.description,
      source_type: InboxSourceTypePB::from(table.source_type as i32),
      is_read: table.is_read,
      is_starred: table.is_starred,
      is_clipped: table.is_clipped,
      created_at: table.created_at,
      updated_at: table.updated_at,
      metadata,
    }
  }
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct RepeatedInboxItemPB {
  #[pb(index = 1)]
  pub items: Vec<InboxItemPB>,
  
  #[pb(index = 2)]
  pub total_count: i32,
  
  #[pb(index = 3)]
  pub unread_count: i32,
}

#[derive(Debug, Default, Clone, ProtoBuf, Validate)]
pub struct CreateInboxItemPB {
  #[pb(index = 1)]
  #[validate(length(min = 1, max = 255, message = "Title must be between 1 and 255 characters"))]
  pub title: String,
  
  #[pb(index = 2)]
  pub content: String,
  
  #[pb(index = 3)]
  pub description: String,
  
  #[pb(index = 4)]
  pub source_type: InboxSourceTypePB,
  
  #[pb(index = 5, one_of)]
  pub source_url: Option<String>,
  
  #[pb(index = 6, one_of)]
  pub file_url: Option<String>,
  
  #[pb(index = 7, one_of)]
  pub image_url: Option<String>,
  
  #[pb(index = 8)]
  pub tags: Vec<String>,
  
  #[pb(index = 9, one_of)]
  pub metadata: Option<InboxItemMetadataPB>,
}

#[derive(Debug, Default, Clone, ProtoBuf, Validate)]
pub struct UpdateInboxItemPB {
  #[pb(index = 1)]
  #[validate(length(min = 1, message = "Item ID cannot be empty"))]
  pub id: String,
  
  #[pb(index = 2, one_of)]
  pub title: Option<String>,
  
  #[pb(index = 3, one_of)]
  pub content: Option<String>,
  
  #[pb(index = 4, one_of)]
  pub description: Option<String>,
  
  #[pb(index = 5, one_of)]
  pub is_read: Option<bool>,
  
  #[pb(index = 6, one_of)]
  pub is_starred: Option<bool>,
  
  #[pb(index = 7)]
  pub tags: Vec<String>,
  
  #[pb(index = 8, one_of)]
  pub metadata: Option<InboxItemMetadataPB>,
}

#[derive(Debug, Default, Clone, ProtoBuf, Validate)]
pub struct DeleteInboxItemPB {
  #[pb(index = 1)]
  #[validate(length(min = 1, message = "Item ID cannot be empty"))]
  pub id: String,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct GetInboxItemsFilterPB {
  #[pb(index = 1, one_of)]
  pub is_read: Option<bool>,
  
  #[pb(index = 2, one_of)]
  pub is_starred: Option<bool>,
  
  #[pb(index = 3, one_of)]
  pub is_clipped: Option<bool>,
  
  #[pb(index = 4, one_of)]
  pub source_type: Option<InboxSourceTypePB>,
  
  #[pb(index = 5, one_of)]
  pub limit: Option<i32>,
  
  #[pb(index = 6, one_of)]
  pub offset: Option<i32>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct SearchInboxItemsPB {
  #[pb(index = 1)]
  pub query: String,
  
  #[pb(index = 2, one_of)]
  pub limit: Option<i32>,
}

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct InboxStatsPB {
  #[pb(index = 1)]
  pub total_count: i32,
  
  #[pb(index = 2)]
  pub unread_count: i32,
}
