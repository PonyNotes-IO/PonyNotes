#[cfg(test)]
mod tests {
  use super::inbox_sql::*;
  use flowy_sqlite::{DBConnection, Database};
  use std::sync::Arc;
  use tempfile::tempdir;

  fn setup_test_db() -> Arc<Database> {
    let dir = tempdir().unwrap();
    let db_path = dir.path().join("test.db");
    let db = Arc::new(Database::new(&db_path.to_string_lossy(), "test").unwrap());
    
    // Create inbox table
    let conn = db.get_connection().unwrap();
    diesel::sql_query(
      r#"
      CREATE TABLE IF NOT EXISTS inbox_table (
        id TEXT PRIMARY KEY NOT NULL,
        workspace_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        description TEXT NOT NULL,
        source_type INTEGER NOT NULL DEFAULT 0,
        source_url TEXT,
        file_url TEXT,
        image_url TEXT,
        is_read BOOLEAN NOT NULL DEFAULT 0,
        is_clipped BOOLEAN NOT NULL DEFAULT 0,
        is_starred BOOLEAN NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        tags TEXT,
        metadata TEXT
      )
      "#,
    )
    .execute(&mut *conn)
    .unwrap();

    db
  }

  #[test]
  fn test_create_inbox_item() {
    let db = setup_test_db();
    let conn = db.get_connection().unwrap();

    let item = InboxTable::new(
      "workspace_1".to_string(),
      "Test Title".to_string(),
      "Test Content".to_string(),
      "Test Description".to_string(),
      InboxSourceType::Manual,
    );

    let result = insert_inbox_item(conn, &item);
    assert!(result.is_ok());
  }

  #[test]
  fn test_get_inbox_item() {
    let db = setup_test_db();
    let conn = db.get_connection().unwrap();

    let item = InboxTable::new(
      "workspace_1".to_string(),
      "Test Title".to_string(),
      "Test Content".to_string(),
      "Test Description".to_string(),
      InboxSourceType::Manual,
    );

    insert_inbox_item(conn.clone(), &item).unwrap();

    let retrieved = select_inbox_item(conn, &item.id).unwrap();
    assert!(retrieved.is_some());
    
    let retrieved_item = retrieved.unwrap();
    assert_eq!(retrieved_item.title, "Test Title");
    assert_eq!(retrieved_item.content, "Test Content");
    assert_eq!(retrieved_item.workspace_id, "workspace_1");
  }

  #[test]
  fn test_update_inbox_item() {
    let db = setup_test_db();
    let conn = db.get_connection().unwrap();

    let item = InboxTable::new(
      "workspace_1".to_string(),
      "Test Title".to_string(),
      "Test Content".to_string(),
      "Test Description".to_string(),
      InboxSourceType::Manual,
    );

    insert_inbox_item(conn.clone(), &item).unwrap();

    let changeset = InboxTableChangeset::new(item.id.clone())
      .title("Updated Title".to_string())
      .mark_as_read(true);

    let result = update_inbox_item(conn.clone(), &changeset);
    assert!(result.is_ok());

    let updated = select_inbox_item(conn, &item.id).unwrap().unwrap();
    assert_eq!(updated.title, "Updated Title");
    assert_eq!(updated.is_read, true);
  }

  #[test]
  fn test_search_inbox_items() {
    let db = setup_test_db();
    let conn = db.get_connection().unwrap();

    let item1 = InboxTable::new(
      "workspace_1".to_string(),
      "Rust Programming".to_string(),
      "Learning Rust is fun".to_string(),
      "Rust tutorial".to_string(),
      InboxSourceType::Manual,
    );

    let item2 = InboxTable::new(
      "workspace_1".to_string(),
      "Python Guide".to_string(),
      "Python is also great".to_string(),
      "Python tutorial".to_string(),
      InboxSourceType::Manual,
    );

    insert_inbox_item(conn.clone(), &item1).unwrap();
    insert_inbox_item(conn.clone(), &item2).unwrap();

    let results = search_inbox_items(conn, "workspace_1", "Rust", Some(10)).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].title, "Rust Programming");
  }

  #[test]
  fn test_filter_inbox_items() {
    let db = setup_test_db();
    let conn = db.get_connection().unwrap();

    let item1 = InboxTable::new(
      "workspace_1".to_string(),
      "Read Item".to_string(),
      "Content 1".to_string(),
      "Description 1".to_string(),
      InboxSourceType::Manual,
    );

    let mut item2 = InboxTable::new(
      "workspace_1".to_string(),
      "Unread Item".to_string(),
      "Content 2".to_string(),
      "Description 2".to_string(),
      InboxSourceType::Clipped,
    );

    insert_inbox_item(conn.clone(), &item1).unwrap();
    insert_inbox_item(conn.clone(), &item2).unwrap();

    // Mark first item as read
    let changeset = InboxTableChangeset::new(item1.id.clone()).mark_as_read(true);
    update_inbox_item(conn.clone(), &changeset).unwrap();

    // Filter for unread items
    let unread_items = select_inbox_items_by_filter(
      conn.clone(),
      "workspace_1",
      Some(false), // is_read
      None,
      None,
      None,
      None,
      None,
    ).unwrap();

    assert_eq!(unread_items.len(), 1);
    assert_eq!(unread_items[0].title, "Unread Item");

    // Filter for clipped items
    let clipped_items = select_inbox_items_by_filter(
      conn,
      "workspace_1",
      None,
      Some(true), // is_clipped
      None,
      None,
      None,
      None,
    ).unwrap();

    assert_eq!(clipped_items.len(), 1);
    assert_eq!(clipped_items[0].title, "Unread Item");
  }

  #[test]
  fn test_inbox_item_with_metadata() {
    let db = setup_test_db();
    let conn = db.get_connection().unwrap();

    let metadata = InboxItemMetadata {
      author: Some("John Doe".to_string()),
      domain: Some("example.com".to_string()),
      word_count: Some(500),
      read_time: Some(3),
      language: Some("en".to_string()),
      custom_fields: Some(serde_json::json!({"category": "tech"})),
    };

    let item = InboxTable::new(
      "workspace_1".to_string(),
      "Article with Metadata".to_string(),
      "This is an article".to_string(),
      "Article description".to_string(),
      InboxSourceType::Clipped,
    ).with_metadata(metadata.clone());

    insert_inbox_item(conn.clone(), &item).unwrap();

    let retrieved = select_inbox_item(conn, &item.id).unwrap().unwrap();
    let retrieved_metadata = retrieved.get_metadata().unwrap();

    assert_eq!(retrieved_metadata.author, metadata.author);
    assert_eq!(retrieved_metadata.domain, metadata.domain);
    assert_eq!(retrieved_metadata.word_count, metadata.word_count);
  }
}

