use flowy_error::{FlowyError, FlowyResult};
use lib_dispatch::prelude::{data_result_ok, AFPluginData, AFPluginState, DataResult};
use std::sync::{Arc, Weak};

use crate::entities::{
  CreateInboxItemPB, DeleteInboxItemPB, InboxItemPB, RepeatedInboxItemPB, UpdateInboxItemPB,
};
use crate::user_manager::UserManager;

fn upgrade_manager(manager: AFPluginState<Weak<UserManager>>) -> FlowyResult<Arc<UserManager>> {
  let manager = manager
    .upgrade()
    .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;
  Ok(manager)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn get_inbox_items_handler(
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<RepeatedInboxItemPB, FlowyError> {
  let manager = upgrade_manager(manager)?;
  let inbox_manager = manager.inbox_manager();
  let items = inbox_manager.get_inbox_items(None, None).await?;
  let stats = inbox_manager.get_inbox_stats().await?;
  
  let pb_items: Vec<InboxItemPB> = items.into_iter().map(|item| item.into()).collect();
  
  let result = RepeatedInboxItemPB {
    items: pb_items,
    total_count: stats.total_count as i32,
    unread_count: stats.unread_count as i32,
  };
  
  data_result_ok(result)
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn create_inbox_item_handler(
  data: AFPluginData<CreateInboxItemPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> DataResult<InboxItemPB, FlowyError> {
  let data = data.into_inner();
  let manager = upgrade_manager(manager)?;
  let inbox_manager = manager.inbox_manager();
  
  let metadata = data.metadata.map(|m| m.into());
  
  let tags = if data.tags.is_empty() { None } else { Some(data.tags) };
  
  let item = inbox_manager
    .create_inbox_item(
      data.title,
      data.content,
      data.description,
      data.source_type.into(),
      data.source_url,
      data.file_url,
      data.image_url,
      tags,
      metadata,
    )
    .await?;
    
  data_result_ok(item.into())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn update_inbox_item_handler(
  data: AFPluginData<UpdateInboxItemPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();
  let manager = upgrade_manager(manager)?;
  let inbox_manager = manager.inbox_manager();
  
  let metadata = data.metadata.map(|m| m.into());
  
  let tags = if data.tags.is_empty() { None } else { Some(data.tags) };
  
  inbox_manager
    .update_inbox_item(
      data.id,
      data.title,
      data.content,
      data.description,
      data.is_read,
      data.is_starred,
      tags,
      metadata,
    )
    .await?;
    
  Ok(())
}

#[tracing::instrument(level = "debug", skip_all, err)]
pub async fn delete_inbox_item_handler(
  data: AFPluginData<DeleteInboxItemPB>,
  manager: AFPluginState<Weak<UserManager>>,
) -> Result<(), FlowyError> {
  let data = data.into_inner();
  let manager = upgrade_manager(manager)?;
  let inbox_manager = manager.inbox_manager();
  
  inbox_manager.delete_inbox_item(data.id).await?;
  
  Ok(())
}
