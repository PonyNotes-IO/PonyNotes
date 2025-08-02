# PonyNotes 邮箱验证配置完成

## 配置状态

### ✅ 已完成的配置
1. **关闭自动确认模式**: `GOTRUE_MAILER_AUTOCONFIRM=false`
2. **配置 SMTP 服务**: QQ 邮箱 SMTP 配置已添加
3. **环境变量正确**: 所有必要的环境变量都已设置
4. **服务重启**: GoTrue 服务已重新启动

### ❌ 当前问题
**QQ 邮箱 SMTP 认证失败**:
```
535 Login fail. Account is abnormal, service is not open, password is incorrect, login frequency limited, or system is busy.
```

## 当前配置

### 环境变量
```bash
GOTRUE_MAILER_AUTOCONFIRM=false
GOTRUE_SMTP_HOST=smtp.qq.com
GOTRUE_SMTP_PORT=465
GOTRUE_SMTP_USER=87103978@qq.com
GOTRUE_SMTP_PASS=LyfCbh09291031
GOTRUE_SMTP_ADMIN_EMAIL=87103978@qq.com
```

### 测试结果
- ✅ **用户注册**: 系统正确尝试发送确认邮件
- ❌ **邮件发送**: QQ 邮箱 SMTP 认证失败
- ✅ **API 响应**: 返回正确的错误信息

## 问题诊断

### QQ 邮箱 SMTP 问题
1. **可能的原因**:
   - 应用专用密码不正确
   - QQ 邮箱 SMTP 服务未开启
   - 账户安全设置限制
   - 登录频率限制

2. **解决步骤**:
   - 登录 QQ 邮箱网页版
   - 设置 → 账户 → POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务
   - 开启 SMTP 服务
   - 重新生成授权码

## 解决方案

### 方案 A: 修复 QQ 邮箱配置

#### 1. 检查 QQ 邮箱设置
1. 登录 QQ 邮箱 (https://mail.qq.com)
2. 点击"设置" → "账户"
3. 找到"POP3/IMAP/SMTP/Exchange/CardDAV/CalDAV服务"
4. 开启"SMTP服务"
5. 生成新的授权码

#### 2. 更新配置
```bash
# 在服务器上更新密码
ssh root@8.152.101.166 "cd /root/xiaoma/cloud/AppFlowy-Cloud && sed -i 's/GOTRUE_SMTP_PASS=.*/GOTRUE_SMTP_PASS=新的授权码/' docker-compose-full.yml"

# 重启服务
docker-compose -f docker-compose-full.yml restart gotrue
```

### 方案 B: 使用 Gmail（推荐）

#### 1. 配置 Gmail SMTP
```bash
# 修改 docker-compose-full.yml
ssh root@8.152.101.166 "cd /root/xiaoma/cloud/AppFlowy-Cloud && sed -i 's/GOTRUE_SMTP_HOST=smtp.qq.com/GOTRUE_SMTP_HOST=smtp.gmail.com/' docker-compose-full.yml && sed -i 's/GOTRUE_SMTP_PORT=465/GOTRUE_SMTP_PORT=587/' docker-compose-full.yml"
```

#### 2. 获取 Gmail 应用专用密码
1. 登录 Google 账户
2. 安全 → 两步验证 → 应用专用密码
3. 生成新的应用专用密码

#### 3. 更新配置
```bash
# 更新 Gmail 配置
ssh root@8.152.101.166 "cd /root/xiaoma/cloud/AppFlowy-Cloud && sed -i 's/GOTRUE_SMTP_USER=.*/GOTRUE_SMTP_USER=your_gmail@gmail.com/' docker-compose-full.yml && sed -i 's/GOTRUE_SMTP_PASS=.*/GOTRUE_SMTP_PASS=your_gmail_app_password/' docker-compose-full.yml && sed -i 's/GOTRUE_SMTP_ADMIN_EMAIL=.*/GOTRUE_SMTP_ADMIN_EMAIL=your_gmail@gmail.com/' docker-compose-full.yml"
```

### 方案 C: 使用第三方邮件服务

#### SendGrid 配置
```bash
GOTRUE_SMTP_HOST=smtp.sendgrid.net
GOTRUE_SMTP_PORT=587
GOTRUE_SMTP_USER=apikey
GOTRUE_SMTP_PASS=your_sendgrid_api_key
GOTRUE_SMTP_ADMIN_EMAIL=your_email@domain.com
```

## 测试步骤

### 1. 验证配置
```bash
# 检查环境变量
docker exec appflowy-cloud-gotrue-1 env | grep -E 'GOTRUE_MAILER_AUTOCONFIRM|GOTRUE_SMTP'
```

### 2. 测试用户注册
```bash
curl -X POST "https://api.xiaomabiji.com/gotrue/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 3. 检查邮件发送
- 检查用户邮箱是否收到确认邮件
- 查看 GoTrue 日志中的邮件发送状态

### 4. 测试邮箱验证
```bash
# 用户点击邮件中的验证链接后
curl -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d '{"token":"验证token"}'
```

## 当前状态

### ✅ 功能正常
- 用户注册 API 正常工作
- 系统正确尝试发送确认邮件
- 邮箱验证流程已启用

### 🔧 需要修复
- QQ 邮箱 SMTP 认证问题
- 需要配置有效的 SMTP 服务

## 下一步操作

1. **选择邮件服务**: 修复 QQ 邮箱或切换到 Gmail/SendGrid
2. **测试邮件发送**: 验证确认邮件能正常发送
3. **测试完整流程**: 注册 → 收邮件 → 验证 → 登录

## 配置总结

**当前配置已正确**，只需要解决 SMTP 认证问题即可实现完整的邮箱验证功能。 