use std::sync::{Arc, Weak};
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::DBConnection;
use tracing::{error, info, instrument};

use crate::services::inbox_sql::{
  InboxTable, InboxTableChangeset, InboxSourceType, InboxItemMetadata,
  insert_inbox_item, update_inbox_item, delete_inbox_item, select_inbox_item,
  select_inbox_items_by_workspace, select_inbox_items_by_filter,
  count_inbox_items_by_workspace, count_unread_inbox_items, search_inbox_items,
};

pub trait InboxUserService: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn sqlite_connection(&self, uid: i64) -> Result<DBConnection, FlowyError>;
}

pub struct InboxManager {
  user_service: Weak<dyn InboxUserService>,
}

impl InboxManager {
  pub fn new(user_service: Weak<dyn InboxUserService>) -> Self {
    Self { user_service }
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn create_inbox_item(
    &self,
    title: String,
    content: String,
    description: String,
    source_type: InboxSourceType,
    source_url: Option<String>,
    file_url: Option<String>,
    image_url: Option<String>,
    tags: Option<Vec<String>>,
    metadata: Option<InboxItemMetadata>,
  ) -> FlowyResult<InboxTable> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let workspace_id = user_service.workspace_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let mut item = InboxTable::new(workspace_id, title, content, description, source_type);

    if let Some(url) = source_url {
      item = item.with_source_url(url);
    }

    if let Some(url) = file_url {
      item = item.with_file_url(url);
    }

    if let Some(url) = image_url {
      item = item.with_image_url(url);
    }

    if let Some(tags) = tags {
      item = item.with_tags(tags);
    }

    if let Some(metadata) = metadata {
      item = item.with_metadata(metadata);
    }

    insert_inbox_item(conn, &item).map_err(|err| {
      error!("Failed to insert inbox item: {}", err);
      FlowyError::internal().with_context("Failed to create inbox item")
    })?;

    info!("Created inbox item with id: {}", item.id);
    Ok(item)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn update_inbox_item(
    &self,
    item_id: String,
    title: Option<String>,
    content: Option<String>,
    description: Option<String>,
    is_read: Option<bool>,
    is_starred: Option<bool>,
    tags: Option<Vec<String>>,
    metadata: Option<InboxItemMetadata>,
  ) -> FlowyResult<()> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let mut changeset = InboxTableChangeset::new(item_id.clone());

    if let Some(title) = title {
      changeset = changeset.title(title);
    }

    if let Some(content) = content {
      changeset = changeset.content(content);
    }

    if let Some(description) = description {
      changeset = changeset.description(description);
    }

    if let Some(is_read) = is_read {
      changeset = changeset.mark_as_read(is_read);
    }

    if let Some(is_starred) = is_starred {
      changeset = changeset.mark_as_starred(is_starred);
    }

    if let Some(tags) = tags {
      changeset = changeset.tags(tags);
    }

    if let Some(metadata) = metadata {
      changeset = changeset.metadata(metadata);
    }

    update_inbox_item(conn, &changeset).map_err(|err| {
      error!("Failed to update inbox item {}: {}", item_id, err);
      FlowyError::internal().with_context("Failed to update inbox item")
    })?;

    info!("Updated inbox item with id: {}", item_id);
    Ok(())
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn delete_inbox_item(&self, item_id: String) -> FlowyResult<()> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    delete_inbox_item(conn, &item_id).map_err(|err| {
      error!("Failed to delete inbox item {}: {}", item_id, err);
      FlowyError::internal().with_context("Failed to delete inbox item")
    })?;

    info!("Deleted inbox item with id: {}", item_id);
    Ok(())
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn get_inbox_item(&self, item_id: String) -> FlowyResult<Option<InboxTable>> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let item = select_inbox_item(conn, &item_id).map_err(|err| {
      error!("Failed to get inbox item {}: {}", item_id, err);
      FlowyError::internal().with_context("Failed to get inbox item")
    })?;

    Ok(item)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn get_inbox_items(
    &self,
    limit: Option<i64>,
    offset: Option<i64>,
  ) -> FlowyResult<Vec<InboxTable>> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let workspace_id = user_service.workspace_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let items = select_inbox_items_by_workspace(conn, &workspace_id, limit, offset).map_err(|err| {
      error!("Failed to get inbox items: {}", err);
      FlowyError::internal().with_context("Failed to get inbox items")
    })?;

    Ok(items)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn get_filtered_inbox_items(
    &self,
    is_read: Option<bool>,
    is_clipped: Option<bool>,
    is_starred: Option<bool>,
    source_type: Option<InboxSourceType>,
    limit: Option<i64>,
    offset: Option<i64>,
  ) -> FlowyResult<Vec<InboxTable>> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let workspace_id = user_service.workspace_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let items = select_inbox_items_by_filter(
      conn,
      &workspace_id,
      is_read,
      is_clipped,
      is_starred,
      source_type,
      limit,
      offset,
    ).map_err(|err| {
      error!("Failed to get filtered inbox items: {}", err);
      FlowyError::internal().with_context("Failed to get filtered inbox items")
    })?;

    Ok(items)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn search_inbox_items(
    &self,
    query: String,
    limit: Option<i64>,
  ) -> FlowyResult<Vec<InboxTable>> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let workspace_id = user_service.workspace_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let items = search_inbox_items(conn, &workspace_id, &query, limit).map_err(|err| {
      error!("Failed to search inbox items: {}", err);
      FlowyError::internal().with_context("Failed to search inbox items")
    })?;

    Ok(items)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn get_inbox_stats(&self) -> FlowyResult<InboxStats> {
    let user_service = self.user_service_upgrade()?;
    let uid = user_service.user_id()?;
    let workspace_id = user_service.workspace_id()?;
    let conn = user_service.sqlite_connection(uid)?;

    let total_count = count_inbox_items_by_workspace(conn, &workspace_id).map_err(|err| {
      error!("Failed to count inbox items: {}", err);
      FlowyError::internal().with_context("Failed to count inbox items")
    })?;

    let conn2 = user_service.sqlite_connection(uid)?;
    let unread_count = count_unread_inbox_items(conn2, &workspace_id).map_err(|err| {
      error!("Failed to count unread inbox items: {}", err);
      FlowyError::internal().with_context("Failed to count unread inbox items")
    })?;

    Ok(InboxStats {
      total_count,
      unread_count,
      read_count: total_count - unread_count,
    })
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn mark_as_read(&self, item_id: String) -> FlowyResult<()> {
    self.update_inbox_item(
      item_id,
      None,
      None,
      None,
      Some(true),
      None,
      None,
      None,
    ).await
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn mark_as_unread(&self, item_id: String) -> FlowyResult<()> {
    self.update_inbox_item(
      item_id,
      None,
      None,
      None,
      Some(false),
      None,
      None,
      None,
    ).await
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn toggle_star(&self, item_id: String) -> FlowyResult<()> {
    // First get the current state
    let item = self.get_inbox_item(item_id.clone()).await?;
    if let Some(item) = item {
      let new_starred_state = !item.is_starred;
      self.update_inbox_item(
        item_id,
        None,
        None,
        None,
        None,
        Some(new_starred_state),
        None,
        None,
      ).await
    } else {
      Err(FlowyError::record_not_found().with_context("Inbox item not found"))
    }
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn clip_content(
    &self,
    title: String,
    content: String,
    source_url: String,
    image_url: Option<String>,
    metadata: Option<InboxItemMetadata>,
  ) -> FlowyResult<InboxTable> {
    // Extract description from content (first 200 chars)
    let description = if content.len() > 200 {
      format!("{}...", &content[..200])
    } else {
      content.clone()
    };

    self.create_inbox_item(
      title,
      content,
      description,
      InboxSourceType::Clipped,
      Some(source_url),
      None,
      image_url,
      None,
      metadata,
    ).await
  }

  fn user_service_upgrade(&self) -> FlowyResult<Arc<dyn InboxUserService>> {
    let user_service = self.user_service.upgrade().ok_or_else(|| {
      FlowyError::internal().with_context("The user session is already dropped")
    })?;
    Ok(user_service)
  }
}

#[derive(Debug, Clone)]
pub struct InboxStats {
  pub total_count: i64,
  pub unread_count: i64,
  pub read_count: i64,
}
