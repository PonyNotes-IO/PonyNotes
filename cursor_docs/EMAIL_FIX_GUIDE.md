# PonyNotes 邮件配置修复指南

## 问题诊断

### 当前状态
- ✅ **GoTrue 服务**: 正常运行
- ✅ **用户注册**: 成功
- ❌ **邮件发送**: 失败（使用 Noop 客户端）
- ❌ **魔法链接**: 生成成功但无法发送
- ❌ **邮箱验证**: 用户收不到验证码

### 根本原因
1. **SMTP 配置无效**: 使用示例配置而非真实凭据
2. **GoTrue 自动降级**: 检测到无效配置后使用 Noop 邮件客户端
3. **邮件模板问题**: 可能无法访问远程模板

## 解决方案

### 方案 A: 快速修复（推荐用于测试）

#### 1. 启用自动确认模式
```bash
# 在服务器上执行
ssh root@8.152.101.166 "cd /root/xiaoma/cloud/AppFlowy-Cloud"

# 确保自动确认已启用
echo "GOTRUE_MAILER_AUTOCONFIRM=true" >> .env

# 重启 GoTrue 服务
docker-compose -f docker-compose-full.yml restart gotrue
```

#### 2. 验证修复
```bash
# 测试用户注册（应该自动确认）
curl -X POST "https://api.xiaomabiji.com/gotrue/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 方案 B: 完整邮件配置（推荐用于生产）

#### 1. 配置真实 SMTP 服务

**使用 QQ 邮箱（推荐）:**
```bash
# 编辑环境变量
ssh root@8.152.101.166 "cd /root/xiaoma/cloud/AppFlowy-Cloud"

# 备份当前配置
cp .env .env.backup

# 添加真实 SMTP 配置
cat >> .env << 'EOF'

# =============================================================================
# 📧 真实邮件配置
# =============================================================================
GOTRUE_MAILER_AUTOCONFIRM=false
GOTRUE_SMTP_HOST=smtp.qq.com
GOTRUE_SMTP_PORT=465
GOTRUE_SMTP_USER=your_qq_email@qq.com
GOTRUE_SMTP_PASS=your_qq_app_password
GOTRUE_SMTP_ADMIN_EMAIL=your_qq_email@qq.com
GOTRUE_SMTP_SENDER_NAME=PonyNotes

# AppFlowy Cloud 邮件配置
APPFLOWY_MAILER_SMTP_HOST=smtp.qq.com
APPFLOWY_MAILER_SMTP_PORT=465
APPFLOWY_MAILER_SMTP_USERNAME=your_qq_email@qq.com
APPFLOWY_MAILER_SMTP_EMAIL=your_qq_email@qq.com
APPFLOWY_MAILER_SMTP_PASSWORD=your_qq_app_password
APPFLOWY_MAILER_SMTP_TLS_KIND=wrapper
EOF
```

**使用 Gmail（备选）:**
```bash
# Gmail 配置
GOTRUE_SMTP_HOST=smtp.gmail.com
GOTRUE_SMTP_PORT=465
GOTRUE_SMTP_USER=your_gmail@gmail.com
GOTRUE_SMTP_PASS=your_gmail_app_password
GOTRUE_SMTP_ADMIN_EMAIL=your_gmail@gmail.com
```

#### 2. 获取邮箱应用密码

**QQ 邮箱:**
1. 登录 QQ 邮箱
2. 设置 → 账户 → POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务
3. 开启 SMTP 服务
4. 生成授权码（应用密码）

**Gmail:**
1. 登录 Google 账户
2. 安全 → 两步验证 → 应用专用密码
3. 生成应用专用密码

#### 3. 重启服务
```bash
# 重启所有服务
docker-compose -f docker-compose-full.yml down
docker-compose -f docker-compose-full.yml up -d

# 检查服务状态
docker ps
```

#### 4. 验证邮件配置
```bash
# 检查 GoTrue 日志
docker logs appflowy-cloud-gotrue-1 --tail 10

# 应该看到类似信息：
# "SMTP mail client being used for smtp.qq.com"
```

### 方案 C: 使用第三方邮件服务

#### 1. SendGrid 配置
```bash
GOTRUE_SMTP_HOST=smtp.sendgrid.net
GOTRUE_SMTP_PORT=587
GOTRUE_SMTP_USER=apikey
GOTRUE_SMTP_PASS=your_sendgrid_api_key
GOTRUE_SMTP_ADMIN_EMAIL=your_email@domain.com
```

#### 2. Mailgun 配置
```bash
GOTRUE_SMTP_HOST=smtp.mailgun.org
GOTRUE_SMTP_PORT=587
GOTRUE_SMTP_USER=your_mailgun_username
GOTRUE_SMTP_PASS=your_mailgun_password
GOTRUE_SMTP_ADMIN_EMAIL=your_email@domain.com
```

## 测试步骤

### 1. 测试邮件发送
```bash
# 注册新用户
curl -X POST "https://api.xiaomabiji.com/gotrue/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@yourdomain.com","password":"test123"}'

# 检查邮箱是否收到确认邮件
```

### 2. 测试魔法链接
```bash
# 请求魔法链接
curl -X POST "https://api.xiaomabiji.com/gotrue/magiclink" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@yourdomain.com"}'

# 检查邮箱是否收到魔法链接
```

### 3. 检查日志
```bash
# 查看 GoTrue 日志
docker logs appflowy-cloud-gotrue-1 --tail 20

# 查看 AppFlowy Cloud 日志
docker logs appflowy-cloud-appflowy_cloud-1 --tail 20
```

## 常见问题

### 1. 邮件发送失败
- 检查 SMTP 凭据是否正确
- 确认邮箱开启了 SMTP 服务
- 检查防火墙是否阻止 SMTP 端口

### 2. 邮件进入垃圾箱
- 配置 SPF、DKIM 记录
- 使用企业邮箱而非个人邮箱
- 设置正确的发件人地址

### 3. 模板加载失败
- 检查网络连接
- 使用本地模板文件
- 配置代理服务器

## 推荐配置

### 开发环境
```bash
GOTRUE_MAILER_AUTOCONFIRM=true  # 自动确认，跳过邮件验证
```

### 生产环境
```bash
GOTRUE_MAILER_AUTOCONFIRM=false  # 需要邮件验证
# 配置真实的 SMTP 服务
```

## 安全建议

1. **使用应用专用密码**，不要使用邮箱登录密码
2. **定期更换 SMTP 密码**
3. **监控邮件发送日志**
4. **配置邮件发送频率限制**
5. **使用企业邮箱服务**

## 联系支持

如果问题持续存在，请：
1. 检查服务器网络连接
2. 验证 SMTP 配置
3. 查看详细错误日志
4. 联系邮箱服务提供商 