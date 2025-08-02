# 仅使用GoTrue服务的邮件测试方案

## 当前状况
- ✅ GoTrue服务正常运行 (端口9999)
- ❌ AppFlowy Cloud服务因数据库迁移问题无法启动
- ❌ Nginx无法正确代理请求

## 解决方案：直接测试GoTrue服务

### 1. 测试GoTrue健康状态
```bash
# 直接访问GoTrue服务（绕过nginx）
curl http://8.152.101.166:9999/health
```

### 2. 测试用户注册（自动确认模式）
```bash
# 注册新用户
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  http://8.152.101.166:9999/signup
```

### 3. 测试用户登录
```bash
# 用户登录
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  http://8.152.101.166:9999/token?grant_type=password
```

### 4. 检查邮件配置
```bash
# 检查GoTrue日志中的邮件相关配置
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 | grep -i mail"
```

## 邮件功能分析

### 当前配置
- `GOTRUE_MAILER_AUTOCONFIRM=true` - 用户注册后自动确认
- 无需邮件验证即可登录
- 适合测试环境

### 邮件发送测试
即使设置了自动确认，GoTrue仍会尝试发送邮件。检查：
1. SMTP配置是否正确
2. 邮件是否实际发送
3. 邮件模板是否正确

## 客户端测试

### 修改客户端配置
在`cloud_env.dart`中，可以临时使用IP地址直接访问GoTrue：

```dart
// 临时测试配置
const String kAppflowyCloudUrl = "http://8.152.101.166:9999";
```

### 测试步骤
1. 在PonyNotes客户端中尝试注册
2. 检查是否收到确认邮件
3. 尝试登录
4. 检查用户数据是否正确保存

## 下一步行动

### 立即执行
1. 测试GoTrue服务是否响应
2. 测试用户注册/登录API
3. 检查邮件发送日志

### 长期修复
1. 解决AppFlowy Cloud数据库迁移问题
2. 修复Nginx配置
3. 配置真实SMTP服务
4. 恢复完整的服务架构

## 预期结果

### 成功情况
- GoTrue服务正常响应
- 用户注册成功（自动确认）
- 用户登录成功
- 客户端可以正常连接

### 失败情况
- GoTrue服务无响应
- 注册/登录API返回错误
- 客户端连接失败
- 邮件发送失败

## 故障排除

### 如果GoTrue无响应
```bash
# 检查容器状态
ssh root@8.152.101.166 "docker ps | grep gotrue"

# 检查日志
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 10"

# 重启服务
ssh root@8.152.101.166 "docker restart appflowy-cloud-gotrue-1"
```

### 如果注册失败
```bash
# 检查请求格式
# 检查数据库连接
# 检查环境变量配置
```

### 如果邮件发送失败
```bash
# 检查SMTP配置
# 检查网络连接
# 检查邮件模板
``` 