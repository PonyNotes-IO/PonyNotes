use flowy_sqlite::{
  AsChangeset, DBConnection, ExpressionMethods, Identifiable, Insertable, Queryable,
  TextExpressionMethods, OptionalExtension, BoolExpressionMethods,
  diesel,
  query_dsl::*,
  schema::inbox_table,
};
use lib_infra::util::timestamp;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[repr(i32)]
pub enum InboxSourceType {
  Manual = 0,
  Clipped = 1,
  Imported = 2,
  Shared = 3,
}

impl From<i32> for InboxSourceType {
  fn from(value: i32) -> Self {
    match value {
      0 => InboxSourceType::Manual,
      1 => InboxSourceType::Clipped,
      2 => InboxSourceType::Imported,
      3 => InboxSourceType::Shared,
      _ => InboxSourceType::Manual,
    }
  }
}

impl From<InboxSourceType> for i32 {
  fn from(source_type: InboxSourceType) -> Self {
    source_type as i32
  }
}

impl Copy for InboxSourceType {}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct InboxItemMetadata {
  pub author: Option<String>,
  pub domain: Option<String>,
  pub word_count: Option<i32>,
  pub read_time: Option<i32>,
  pub language: Option<String>,
  pub custom_fields: Option<serde_json::Value>,
}

#[derive(Clone, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = inbox_table)]
#[diesel(primary_key(id))]
pub struct InboxTable {
  pub id: String,
  pub workspace_id: String,
  pub title: String,
  pub content: String,
  pub description: String,
  pub source_type: i32,
  pub source_url: Option<String>,
  pub file_url: Option<String>,
  pub image_url: Option<String>,
  pub is_read: bool,
  pub is_clipped: bool,
  pub is_starred: bool,
  pub created_at: i64,
  pub updated_at: i64,
  pub tags: Option<String>, // JSON array
  pub metadata: Option<String>, // JSON metadata
}

impl InboxTable {
  pub fn new(
    workspace_id: String,
    title: String,
    content: String,
    description: String,
    source_type: InboxSourceType,
  ) -> Self {
    let now = timestamp();
    Self {
      id: Uuid::new_v4().to_string(),
      workspace_id,
      title,
      content,
      description,
      source_type: source_type.into(),
      source_url: None,
      file_url: None,
      image_url: None,
      is_read: false,
      is_clipped: source_type == InboxSourceType::Clipped,
      is_starred: false,
      created_at: now,
      updated_at: now,
      tags: None,
      metadata: None,
    }
  }

  pub fn with_source_url(mut self, url: String) -> Self {
    self.source_url = Some(url);
    self
  }

  pub fn with_file_url(mut self, url: String) -> Self {
    self.file_url = Some(url);
    self
  }

  pub fn with_image_url(mut self, url: String) -> Self {
    self.image_url = Some(url);
    self
  }

  pub fn with_tags(mut self, tags: Vec<String>) -> Self {
    if !tags.is_empty() {
      self.tags = Some(serde_json::to_string(&tags).unwrap_or_default());
    }
    self
  }

  pub fn with_metadata(mut self, metadata: InboxItemMetadata) -> Self {
    self.metadata = Some(serde_json::to_string(&metadata).unwrap_or_default());
    self
  }

  pub fn get_tags(&self) -> Vec<String> {
    self.tags
      .as_ref()
      .and_then(|tags| serde_json::from_str(tags).ok())
      .unwrap_or_default()
  }

  pub fn get_metadata(&self) -> Option<InboxItemMetadata> {
    self.metadata
      .as_ref()
      .and_then(|metadata| serde_json::from_str(metadata).ok())
  }
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = inbox_table)]
#[diesel(primary_key(id))]
pub struct InboxTableChangeset {
  pub id: String,
  pub title: Option<String>,
  pub content: Option<String>,
  pub description: Option<String>,
  pub source_url: Option<String>,
  pub file_url: Option<String>,
  pub image_url: Option<String>,
  pub is_read: Option<bool>,
  pub is_clipped: Option<bool>,
  pub is_starred: Option<bool>,
  pub updated_at: Option<i64>,
  pub tags: Option<String>,
  pub metadata: Option<String>,
}

impl InboxTableChangeset {
  pub fn new(id: String) -> Self {
    Self {
      id,
      updated_at: Some(timestamp()),
      ..Default::default()
    }
  }

  pub fn title(mut self, title: String) -> Self {
    self.title = Some(title);
    self
  }

  pub fn content(mut self, content: String) -> Self {
    self.content = Some(content);
    self
  }

  pub fn description(mut self, description: String) -> Self {
    self.description = Some(description);
    self
  }

  pub fn mark_as_read(mut self, is_read: bool) -> Self {
    self.is_read = Some(is_read);
    self
  }

  pub fn mark_as_starred(mut self, is_starred: bool) -> Self {
    self.is_starred = Some(is_starred);
    self
  }

  pub fn tags(mut self, tags: Vec<String>) -> Self {
    self.tags = Some(serde_json::to_string(&tags).unwrap_or_default());
    self
  }

  pub fn metadata(mut self, metadata: InboxItemMetadata) -> Self {
    self.metadata = Some(serde_json::to_string(&metadata).unwrap_or_default());
    self
  }
}

// Database operations
pub fn insert_inbox_item(
  mut conn: DBConnection,
  item: &InboxTable,
) -> Result<(), flowy_sqlite::Error> {
  diesel::insert_into(inbox_table::table)
    .values(item)
    .execute(&mut *conn)?;
  Ok(())
}

pub fn update_inbox_item(
  mut conn: DBConnection,
  changeset: &InboxTableChangeset,
) -> Result<(), flowy_sqlite::Error> {
  diesel::update(inbox_table::table.filter(inbox_table::id.eq(&changeset.id)))
    .set(changeset)
    .execute(&mut *conn)?;
  Ok(())
}

pub fn delete_inbox_item(
  mut conn: DBConnection,
  item_id: &str,
) -> Result<(), flowy_sqlite::Error> {
  diesel::delete(inbox_table::table.filter(inbox_table::id.eq(item_id)))
    .execute(&mut *conn)?;
  Ok(())
}

pub fn select_inbox_item(
  mut conn: DBConnection,
  item_id: &str,
) -> Result<Option<InboxTable>, flowy_sqlite::Error> {
  let item = inbox_table::table
    .filter(inbox_table::id.eq(item_id))
    .first::<InboxTable>(&mut *conn)
    .optional()?;
  Ok(item)
}

pub fn select_inbox_items_by_workspace(
  mut conn: DBConnection,
  workspace_id: &str,
  limit: Option<i64>,
  offset: Option<i64>,
) -> Result<Vec<InboxTable>, flowy_sqlite::Error> {
  let mut query = inbox_table::table
    .filter(inbox_table::workspace_id.eq(workspace_id))
    .order(inbox_table::created_at.desc())
    .into_boxed();

  if let Some(limit) = limit {
    query = query.limit(limit);
  }

  if let Some(offset) = offset {
    query = query.offset(offset);
  }

  let items = query.load::<InboxTable>(&mut *conn)?;
  Ok(items)
}

pub fn select_inbox_items_by_filter(
  mut conn: DBConnection,
  workspace_id: &str,
  is_read: Option<bool>,
  is_clipped: Option<bool>,
  is_starred: Option<bool>,
  source_type: Option<InboxSourceType>,
  limit: Option<i64>,
  offset: Option<i64>,
) -> Result<Vec<InboxTable>, flowy_sqlite::Error> {
  let mut query = inbox_table::table
    .filter(inbox_table::workspace_id.eq(workspace_id))
    .into_boxed();

  if let Some(is_read) = is_read {
    query = query.filter(inbox_table::is_read.eq(is_read));
  }

  if let Some(is_clipped) = is_clipped {
    query = query.filter(inbox_table::is_clipped.eq(is_clipped));
  }

  if let Some(is_starred) = is_starred {
    query = query.filter(inbox_table::is_starred.eq(is_starred));
  }

  if let Some(source_type) = source_type {
    query = query.filter(inbox_table::source_type.eq::<i32>(source_type.into()));
  }

  query = query.order(inbox_table::created_at.desc());

  if let Some(limit) = limit {
    query = query.limit(limit);
  }

  if let Some(offset) = offset {
    query = query.offset(offset);
  }

  let items = query.load::<InboxTable>(&mut *conn)?;
  Ok(items)
}

pub fn count_inbox_items_by_workspace(
  mut conn: DBConnection,
  workspace_id: &str,
) -> Result<i64, flowy_sqlite::Error> {
  use diesel::dsl::count_star;
  let count = inbox_table::table
    .filter(inbox_table::workspace_id.eq(workspace_id))
    .select(count_star())
    .first::<i64>(&mut *conn)?;
  Ok(count)
}

pub fn count_unread_inbox_items(
  mut conn: DBConnection,
  workspace_id: &str,
) -> Result<i64, flowy_sqlite::Error> {
  use diesel::dsl::count_star;
  let count = inbox_table::table
    .filter(inbox_table::workspace_id.eq(workspace_id))
    .filter(inbox_table::is_read.eq(false))
    .select(count_star())
    .first::<i64>(&mut *conn)?;
  Ok(count)
}

pub fn search_inbox_items(
  mut conn: DBConnection,
  workspace_id: &str,
  query: &str,
  limit: Option<i64>,
) -> Result<Vec<InboxTable>, flowy_sqlite::Error> {
  let search_pattern = format!("%{}%", query);
  let mut db_query = inbox_table::table
    .filter(inbox_table::workspace_id.eq(workspace_id))
    .filter(
      inbox_table::title
        .like(&search_pattern)
        .or(inbox_table::content.like(&search_pattern))
        .or(inbox_table::description.like(&search_pattern)),
    )
    .order(inbox_table::created_at.desc())
    .into_boxed();

  if let Some(limit) = limit {
    db_query = db_query.limit(limit);
  }

  let items = db_query.load::<InboxTable>(&mut *conn)?;
  Ok(items)
}
