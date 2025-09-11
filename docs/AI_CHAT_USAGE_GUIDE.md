# PonyNotes AI聊天功能使用指南

## 功能概述

PonyNotes已集成完整的AI聊天功能，支持多种国内AI模型（DeepSeek、通义千问、豆包），具备以下特性：

### ✨ 核心功能
- **多AI模型支持**：DeepSeek、通义千问、豆包
- **实时对话**：流式AI响应，支持停止生成
- **历史记录**：自动保存聊天记录到本地文件
- **会话管理**：支持多个聊天会话
- **消息操作**：复制AI回复、清空对话
- **配置管理**：灵活的API密钥配置

### 💾 历史记录功能

**Flutter AI实现使用JSON文件存储历史对话，而Rust后端使用SQLite数据库！**

#### Flutter历史记录特性：
1. **自动保存**：每条消息都会自动保存到本地JSON文件
2. **会话管理**：支持多个独立的聊天会话  
3. **智能标题**：根据首条消息自动生成会话标题
4. **持久化存储**：使用JSON格式保存到设备本地文档目录
5. **导入导出**：支持聊天历史的备份和恢复

#### 存储架构说明：

**Flutter层（InteractiveAIChatPage）**：
- 存储位置：`应用文档目录/chat_history.json`
- 格式：JSON文件
- 管理：ChatHistoryService 独立管理

**Rust后端层（AI Chat系统）**：
- 存储位置：`{user_data_dir}/{user_id}/flowy-database.db`
- 格式：SQLite数据库
- 表结构：
  - `chat_table`：聊天会话信息
  - `chat_message_table`：聊天消息详情

#### 数据结构：
- **ChatSession**：聊天会话，包含ID、标题、创建时间、消息列表
- **ChatMessage**：聊天消息，包含ID、内容、角色、时间戳、错误信息

## 快速开始

### 1. 配置API密钥

复制配置模板：
```bash
cd frontend/appflowy_flutter
cp ai_config_example.env .env.ai
```

编辑 `.env.ai` 文件，填入你的API密钥：

#### DeepSeek配置
```env
AI_DEEPSEEK_API_KEY=your_deepseek_api_key_here
AI_DEEPSEEK_API_BASE=https://ark.cn-beijing.volces.com/api/v3
AI_DEEPSEEK_MODEL_NAME=deepseek-v3-250324
```

#### 通义千问配置
```env
AI_QWEN_API_KEY=your_qwen_api_key_here
AI_QWEN_API_BASE=https://dashscope.aliyuncs.com/compatible-mode/v1
AI_QWEN_MODEL_NAME=qwen-turbo
```

#### 豆包配置
```env
AI_DOUBAO_API_KEY=your_doubao_api_key_here
AI_DOUBAO_API_BASE=https://ark.cn-beijing.volces.com/api/v3
AI_DOUBAO_MODEL_NAME=ep-m-20250814175607-b77g6
```

### 2. 设置默认模型
```env
AI_DEFAULT_MODEL=deepseek  # 可选: deepseek, qwen, doubao
```

### 3. 启动应用
```bash
flutter run
```

## API密钥获取

### DeepSeek
- 网站：https://platform.deepseek.com/
- 注册并获取API密钥
- 支持通过火山方舟访问

### 通义千问
- 网站：https://dashscope.console.aliyun.com/
- 阿里云DashScope平台
- 注册阿里云账号并开通服务

### 豆包
- 网站：https://console.volcengine.com/ark/
- 字节跳动火山方舟平台
- 注册并获取API访问权限

## 使用方法

### 基本对话
1. 打开AI聊天页面
2. 在顶部选择AI模型
3. 在输入框输入消息
4. 点击发送按钮或按Enter键

### 快速开始示例
- "你好，请介绍一下自己"
- "帮我写一段代码"
- "解释一下Flutter"
- "今天天气怎么样？"

### 功能操作
- **切换模型**：点击顶部模型选择器
- **复制回复**：点击AI消息旁的复制图标
- **清空对话**：点击顶部清空按钮
- **停止生成**：生成过程中点击停止按钮
- **重新加载配置**：点击刷新按钮

## 历史记录管理

### ChatHistoryService API
```dart
// 获取服务实例
final historyService = ChatHistoryService.instance;

// 初始化服务
await historyService.initialize();

// 创建新会话
final session = historyService.createNewSession(title: "新对话");

// 添加消息
await historyService.addMessage(ChatMessage(
  id: 'msg_id',
  content: '消息内容',
  isUser: true,
  timestamp: DateTime.now(),
));

// 获取所有会话
final sessions = historyService.getAllSessions();

// 删除会话
await historyService.deleteSession(sessionId);

// 导出历史
final jsonData = await historyService.exportHistory();

// 导入历史
await historyService.importHistory(jsonData);
```

## 技术架构

### 核心组件
- **InteractiveAIChatPage**：主要聊天界面
- **AIChatService**：AI聊天服务
- **ChatHistoryService**：历史记录管理
- **AIConfigService**：配置管理
- **AIModelSelector**：模型选择器

### 数据流
1. 用户输入 → UI状态更新
2. 调用AIChatService → 发送API请求
3. 接收AI响应 → 更新消息列表
4. ChatHistoryService → 自动保存到本地

## 故障排除

### 常见问题

1. **AI服务初始化失败**
   - 检查API密钥是否正确
   - 确认网络连接正常
   - 重新加载配置

2. **消息发送失败**
   - 验证API密钥有效性
   - 检查API额度是否充足
   - 确认模型名称正确

3. **历史记录丢失**
   - 检查应用文档目录权限
   - 查看chat_history.json文件是否存在
   - 尝试重新初始化服务

### 调试信息
应用控制台会显示详细的调试信息：
- ✅ 成功操作
- ❌ 错误信息
- 💾 保存操作
- 📝 会话操作

## 安全注意事项

1. **API密钥安全**
   - `.env.ai`文件已加入`.gitignore`
   - 不要将API密钥提交到版本控制
   - 定期更换API密钥

2. **本地数据保护**
   - 聊天历史保存在本地设备
   - 可通过导出功能备份数据
   - 卸载应用会清除本地数据

## 总结

PonyNotes的AI聊天功能提供了完整的对话体验，包括：
- ✅ 多AI模型支持
- ✅ 双层历史记录架构
- ✅ 会话管理
- ✅ 数据持久化
- ✅ 导入导出功能
- ✅ 安全的配置管理

### 📋 历史记录存储总结

**回答你的问题：历史对话保存到本地的SQLite和RocksDB中了吗？**

答案：**部分是的，取决于使用哪个聊天系统**

1. **Flutter InteractiveAIChatPage**（你主要使用的）：
   - ❌ **不使用** SQLite/RocksDB
   - ✅ 使用JSON文件存储（`chat_history.json`）
   - 位置：应用文档目录

2. **Rust AI Chat系统**（后端完整系统）：
   - ✅ 使用SQLite数据库存储
   - 表：`chat_table` + `chat_message_table`
   - 位置：`flowy-database.db`

3. **文档协作系统**：
   - ✅ 使用RocksDB存储文档内容
   - 位置：`collab_db/`目录

**结论**：你当前使用的Flutter AI聊天界面使用JSON文件存储，而不是SQLite/RocksDB。如果要使用数据库存储，需要集成Rust后端的完整AI Chat系统。
