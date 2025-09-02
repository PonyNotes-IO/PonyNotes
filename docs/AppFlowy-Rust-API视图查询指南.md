# AppFlowy Rust API 视图查询指南

## 📋 概述

本指南详细介绍如何使用AppFlowy的Rust API查询视图的详细信息，包括名称、层级关系、类型等完整数据。与SQLite数据库只存储索引信息不同，Rust API可以直接从RocksDB协作数据库中获取完整的视图数据。

## 🏗️ API架构概览

AppFlowy使用分层架构来处理视图数据：

```
Frontend (Dart)
    ↓
ViewBackendService API
    ↓
Rust Backend Events
    ↓
FolderManager
    ↓
RocksDB (collab_db/)
```

## 🎯 核心API方法

### 1. `ViewBackendService.getAllViews()` - 获取所有视图

这是最常用的API，返回工作区中所有视图的完整信息。

#### Dart调用示例：

```dart
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';

// 获取所有视图
Future<List<ViewPB>> getAllViews() async {
  final result = await ViewBackendService.getAllViews();
  
  return result.fold(
    (views) => views.items,  // 成功时返回视图列表
    (error) {
      print('获取视图失败: $error');
      return <ViewPB>[];     // 失败时返回空列表
    },
  );
}

// 使用示例
void loadViews() async {
  final views = await getAllViews();
  
  for (final view in views) {
    print('视图ID: ${view.id}');
    print('视图名称: ${view.name}');
    print('父视图ID: ${view.parentViewId}');
    print('视图类型: ${view.layout}');
    print('是否收藏: ${view.isFavorite}');
    print('创建时间: ${view.createTime}');
    print('最后编辑: ${view.lastEdited}');
    print('子视图数量: ${view.childViews.length}');
    print('---');
  }
}
```

### 2. `ViewBackendService.getView()` - 获取单个视图

根据视图ID获取特定视图的详细信息。

```dart
Future<ViewPB?> getViewById(String viewId) async {
  final result = await ViewBackendService.getView(viewId);
  
  return result.fold(
    (view) => view,
    (error) {
      print('获取视图失败: $error');
      return null;
    },
  );
}
```

### 3. `ViewBackendService.getChildViews()` - 获取子视图

```dart
Future<List<ViewPB>> getChildViews(String parentViewId) async {
  final result = await ViewBackendService.getChildViews(viewId: parentViewId);
  
  return result.fold(
    (views) => views,
    (error) {
      print('获取子视图失败: $error');
      return <ViewPB>[];
    },
  );
}
```

### 4. `ViewBackendService.getViewAncestors()` - 获取视图祖先

```dart
Future<List<ViewPB>> getViewAncestors(String viewId) async {
  final result = await ViewBackendService.getViewAncestors(viewId);
  
  return result.fold(
    (views) => views.items,
    (error) {
      print('获取祖先视图失败: $error');
      return <ViewPB>[];
    },
  );
}
```

## 📊 ViewPB 数据结构详解

`ViewPB` (View Protocol Buffer) 是视图数据的核心结构：

```dart
class ViewPB {
  String id;                    // 视图唯一标识符
  String parentViewId;          // 父视图ID
  String name;                  // 视图名称
  int createTime;               // 创建时间戳
  List<ViewPB> childViews;      // 子视图列表
  ViewLayoutPB layout;          // 视图布局类型
  ViewIconPB? icon;             // 视图图标
  bool isFavorite;              // 是否收藏
  String? extra;                // 额外数据
  int? createdBy;               // 创建者用户ID
  int lastEdited;               // 最后编辑时间戳
  int? lastEditedBy;            // 最后编辑者用户ID
  bool? isLocked;               // 是否锁定
}
```

### 视图布局类型 (ViewLayoutPB)

```dart
enum ViewLayoutPB {
  Document = 0,    // 文档
  Grid = 1,        // 表格
  Board = 2,       // 看板
  Calendar = 3,    // 日历
  Chat = 4,        // 聊天
  Folder = 5,      // 文件夹
  Notebook = 6,    // 笔记本
}
```

## 🔧 实际应用示例

### 构建视图树结构

```dart
class ViewTree {
  final ViewPB view;
  final List<ViewTree> children;
  
  ViewTree(this.view, this.children);
}

Future<List<ViewTree>> buildViewTree() async {
  final allViews = await getAllViews();
  final Map<String, ViewPB> viewMap = {
    for (var view in allViews) view.id: view
  };
  
  // 找到根视图（没有父视图的视图）
  final rootViews = allViews.where((view) => 
    view.parentViewId.isEmpty || 
    !viewMap.containsKey(view.parentViewId)
  ).toList();
  
  List<ViewTree> buildChildren(ViewPB parent) {
    final children = allViews
        .where((view) => view.parentViewId == parent.id)
        .map((child) => ViewTree(child, buildChildren(child)))
        .toList();
    return children;
  }
  
  return rootViews.map((root) => ViewTree(root, buildChildren(root))).toList();
}
```

### 过滤特定类型的视图

```dart
Future<List<ViewPB>> getDocumentViews() async {
  final allViews = await getAllViews();
  return allViews.where((view) => view.layout == ViewLayoutPB.Document).toList();
}

Future<List<ViewPB>> getFavoriteViews() async {
  final allViews = await getAllViews();
  return allViews.where((view) => view.isFavorite).toList();
}

Future<List<ViewPB>> getRecentlyEditedViews({int limit = 10}) async {
  final allViews = await getAllViews();
  allViews.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
  return allViews.take(limit).toList();
}
```

### 搜索视图

```dart
Future<List<ViewPB>> searchViews(String query) async {
  final allViews = await getAllViews();
  final lowerQuery = query.toLowerCase();
  
  return allViews.where((view) {
    return view.name.toLowerCase().contains(lowerQuery);
  }).toList();
}
```

## 🛠️ Rust后端实现分析

### 事件处理流程

1. **Dart层调用** → `ViewBackendService.getAllViews()`
2. **事件分发** → `FolderEventGetAllViews`
3. **处理器执行** → `get_all_views_handler()`
4. **管理器调用** → `FolderManager.get_all_views_pb()`
5. **数据获取** → 从RocksDB读取视图数据

### 核心Rust代码

```rust
// 事件处理器 (event_handler.rs)
pub(crate) async fn get_all_views_handler(
  folder: AFPluginState<Weak<FolderManager>>,
) -> DataResult<RepeatedViewPB, FlowyError> {
  let folder = upgrade_folder(folder)?;
  let view_pbs = folder.get_all_views_pb().await?;
  data_result_ok(RepeatedViewPB::from(view_pbs))
}

// FolderManager实现 (manager.rs)
pub async fn get_all_views_pb(&self) -> FlowyResult<Vec<ViewPB>> {
  let lock = self.mutex_folder.load_full().ok_or_else(folder_not_init_error)?;
  let folder = lock.read().await;
  let view_ids_should_be_filtered = Self::get_view_ids_should_be_filtered(&folder);
  
  let all_views = folder.get_all_views();
  let views = all_views
    .into_iter()
    .filter(|view| !view_ids_should_be_filtered.contains(&view.id))
    .map(view_pb_without_child_views_from_arc)
    .collect::<Vec<_>>();
    
  Ok(views)
}
```

## 🔍 数据过滤逻辑

Rust后端会自动过滤以下视图：
- **垃圾桶中的视图** - 已删除但未永久删除的视图
- **私有视图** - 标记为私有的视图
- **孤儿视图** - 没有正确父子关系的视图

## ⚡ 性能优化建议

### 1. 缓存视图数据

```dart
class ViewCache {
  static final Map<String, ViewPB> _cache = {};
  static DateTime? _lastUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  static Future<List<ViewPB>> getCachedViews() async {
    if (_lastUpdate == null || 
        DateTime.now().difference(_lastUpdate!) > _cacheExpiry) {
      final views = await ViewBackendService.getAllViews().then(
        (result) => result.fold((views) => views.items, (error) => <ViewPB>[])
      );
      
      _cache.clear();
      for (var view in views) {
        _cache[view.id] = view;
      }
      _lastUpdate = DateTime.now();
    }
    
    return _cache.values.toList();
  }
}
```

### 2. 按需加载子视图

```dart
Future<ViewPB> getViewWithChildren(String viewId) async {
  final view = await ViewBackendService.getView(viewId);
  return view.fold(
    (viewPB) async {
      if (viewPB.childViews.isEmpty) {
        // 只在需要时加载子视图
        final children = await ViewBackendService.getChildViews(viewId: viewId);
        children.fold(
          (childViews) => viewPB.childViews.addAll(childViews),
          (error) => print('加载子视图失败: $error'),
        );
      }
      return viewPB;
    },
    (error) => throw Exception('获取视图失败: $error'),
  );
}
```

## 🚨 错误处理

```dart
class ViewService {
  static Future<List<ViewPB>> getAllViewsSafely() async {
    try {
      final result = await ViewBackendService.getAllViews();
      return result.fold(
        (views) => views.items,
        (error) {
          // 记录错误
          print('API错误: ${error.msg}');
          
          // 根据错误类型采取不同策略
          switch (error.code) {
            case ErrorCode.UserUnauthorized:
              // 重新认证
              break;
            case ErrorCode.NetworkError:
              // 使用缓存数据
              break;
            default:
              // 返回空列表
              break;
          }
          
          return <ViewPB>[];
        },
      );
    } catch (e) {
      print('未知错误: $e');
      return <ViewPB>[];
    }
  }
}
```

## 📚 相关文件位置

### Dart层文件
- **API服务**: `frontend/appflowy_flutter/lib/workspace/application/view/view_service.dart`
- **数据结构**: `frontend/appflowy_backend/lib/protobuf/flowy-folder/view.pb.dart`

### Rust层文件
- **事件映射**: `frontend/rust-lib/flowy-folder/src/event_map.rs`
- **事件处理**: `frontend/rust-lib/flowy-folder/src/event_handler.rs`
- **管理器**: `frontend/rust-lib/flowy-folder/src/manager.rs`
- **数据结构**: `frontend/rust-lib/flowy-folder/src/entities/view.rs`

## 🎯 最佳实践

1. **始终进行错误处理** - 使用`fold()`方法处理`FlowyResult`
2. **合理使用缓存** - 避免频繁调用API
3. **按需加载数据** - 只在需要时加载子视图
4. **过滤无效数据** - 检查视图是否为空或已删除
5. **监听数据变化** - 使用通知机制更新UI

## 🔗 总结

通过AppFlowy的Rust API，我们可以：
- ✅ 获取视图的完整信息（名称、类型、层级关系等）
- ✅ 构建完整的视图树结构
- ✅ 实现高效的视图搜索和过滤
- ✅ 处理复杂的父子关系
- ✅ 获得实时的数据更新

这比直接查询SQLite数据库更加可靠和完整，因为Rust API会从RocksDB中读取最新的协作数据，并提供了完善的错误处理和数据过滤机制。
