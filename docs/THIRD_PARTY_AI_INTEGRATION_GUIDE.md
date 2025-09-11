# 第三方AI API集成指南

这个指南将帮助你配置PonyNotes使用第三方AI API（如DeepSeek、通义千问、豆包），绕过Ollama和云服务直接调用第三方API。

## 支持的AI服务

- **DeepSeek**: 强大的对话和代码模型
- **通义千问**: 阿里云的AI服务
- **豆包**: 字节跳动的AI服务

## 快速配置

### 1. 创建配置文件

在项目根目录创建`.env.ai`文件：

```bash
# DeepSeek API配置
DEEPSEEK_API_KEY=sk-your-deepseek-api-key

# 通义千问API配置  
QWEN_API_KEY=your-qwen-api-key

# 豆包API配置
DOUBAO_API_KEY=your-doubao-api-key
```

### 2. 获取API密钥

#### DeepSeek
1. 访问 [DeepSeek平台](https://platform.deepseek.com/)
2. 注册账号并登录
3. 在API密钥页面创建新的API Key
4. 复制API Key到`.env.ai`文件

#### 通义千问  
1. 访问 [阿里云控制台](https://dashscope.console.aliyun.com/)
2. 开通DashScope服务
3. 创建API Key
4. 复制API Key到`.env.ai`文件

#### 豆包
1. 访问 [火山引擎控制台](https://console.volcengine.com/ark/)
2. 开通豆包服务
3. 创建API Key
4. 复制API Key到`.env.ai`文件

### 3. 重启应用

配置文件创建完成后，重启PonyNotes应用以加载新配置。

## 如何工作

### 优先级机制

PonyNotes AI服务使用以下优先级：

1. **本地AI**: 如果配置了Ollama且模型标记为本地，优先使用
2. **第三方API**: 如果模型名称匹配且配置了对应API Key，使用第三方API
3. **云服务**: 作为最后的回退选项

### 模型自动检测

系统会根据模型名称自动选择合适的API：

- 包含`deepseek`的模型 → DeepSeek API
- 包含`qwen`的模型 → 通义千问API  
- 包含`doubao`的模型 → 豆包API

### 可用模型

配置API Key后，系统会自动提供以下模型：

**DeepSeek模型:**
- `deepseek-chat` - 强大的对话模型
- `deepseek-coder` - 专业代码模型

**通义千问模型:**
- `qwen-turbo` - 快速响应
- `qwen-plus` - 平衡性能
- `qwen-max` - 最强性能

**豆包模型:**
- `doubao-pro-4k` - 高性能对话
- `doubao-pro-32k` - 长文本处理

## 技术实现

### 核心组件

1. **ExternalAPIService**: 第三方API适配器
2. **ExternalModelSource**: 第三方模型提供者
3. **ChatServiceMiddleware**: 请求路由中间件

### API适配

所有第三方API都被适配为统一的ChatGPT兼容格式：

```rust
{
  "model": "model-name",
  "messages": [
    {"role": "user", "content": "你好"}
  ],
  "stream": true,
  "temperature": 0.7
}
```

### 流式响应

支持Server-Sent Events (SSE)格式的流式响应，提供实时的对话体验。

## 配置示例

### 完整的.env.ai配置

```bash
# ====================
# 第三方AI API配置
# ====================

# DeepSeek配置 - https://platform.deepseek.com/
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 通义千问配置 - https://dashscope.console.aliyun.com/
QWEN_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 豆包配置 - https://console.volcengine.com/ark/
DOUBAO_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 只使用DeepSeek

```bash
# 只配置DeepSeek
DEEPSEEK_API_KEY=sk-your-deepseek-api-key
```

## 故障排除

### 常见问题

1. **模型不显示**
   - 检查`.env.ai`文件是否存在
   - 确认API Key格式正确
   - 重启应用

2. **API调用失败**
   - 检查网络连接
   - 确认API Key有效
   - 检查API配额是否用尽

3. **配置不生效**
   - 确保`.env.ai`在项目根目录
   - 重启应用加载新配置
   - 检查文件编码为UTF-8

### 调试模式

启用Rust日志查看详细信息：

```bash
RUST_LOG=info cargo run
```

## 安全注意事项

1. **保护API密钥**
   - 不要将`.env.ai`提交到版本控制
   - 定期轮换API密钥
   - 限制API密钥权限

2. **网络安全**
   - 使用HTTPS连接
   - 考虑使用代理或VPN
   - 监控API使用情况

## 成本控制

1. **设置API配额限制**
2. **监控Token使用量**
3. **合理设置temperature和max_tokens参数**

## 更新和维护

### 添加新的AI服务

1. 在`ExternalAPIConfig`中添加新的API密钥字段
2. 在`ExternalAPIService`中实现对应的流式方法
3. 在`ExternalModelSource`中添加新模型
4. 更新模型检测逻辑

### 自定义模型参数

可以通过修改`ExternalAPIService`中的请求payload来调整：

- `temperature`: 控制随机性
- `max_tokens`: 限制响应长度
- `top_p`: 核采样参数

## 支持

如果遇到问题，请：

1. 查看应用日志
2. 检查API服务状态
3. 确认配置文件格式
4. 提交Issue到项目仓库

---

*最后更新: 2025年9月*
