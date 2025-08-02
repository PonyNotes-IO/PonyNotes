# PonyNotes 邮件问题修复指南

## 当前问题分析

### 1. 服务状态
- ✅ **GoTrue服务**: 正常运行 (端口9999)
- ❌ **AppFlowy Cloud服务**: 因数据库迁移错误无法启动
- ❌ **Nginx服务**: 配置问题，无法正确代理请求

### 2. 邮件功能问题
- GoTrue服务支持邮件发送，但需要正确配置SMTP
- AppFlowy Cloud服务负责业务逻辑，包括用户验证
- 当前AppFlowy Cloud无法启动，影响完整流程

## 解决方案

### 方案A: 快速测试方案（推荐）

#### 1. 配置GoTrue自动确认模式
```bash
# 在服务器上修改GoTrue环境变量
ssh root@8.152.101.166 "cd /root/xiaoma/cloud/AppFlowy-Cloud && docker-compose -f docker-compose-full.yml down"

# 编辑环境变量文件，添加自动确认配置
echo "GOTRUE_MAILER_AUTOCONFIRM=true" >> .env

# 重新启动服务
docker-compose -f docker-compose-full.yml up -d
```

#### 2. 测试用户注册
```bash
# 测试注册API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  http://8.152.101.166:9999/signup
```

### 方案B: 完整修复方案

#### 1. 修复数据库迁移问题
```bash
# 连接到PostgreSQL数据库
ssh root@8.152.101.166 "docker exec -it appflowy-cloud-postgres-1 psql -U postgres -d postgres"

# 在数据库中执行
DROP TYPE IF EXISTS af_fragment CASCADE;
\q

# 重启AppFlowy Cloud服务
docker restart appflowy-cloud-appflowy_cloud-1
```

#### 2. 配置真实SMTP服务
```bash
# 在.env文件中添加SMTP配置
cat >> .env << EOF
GOTRUE_MAILER_AUTOCONFIRM=false
GOTRUE_SMTP_HOST=smtp.qq.com
GOTRUE_SMTP_PORT=465
GOTRUE_SMTP_USER=your_email@qq.com
GOTRUE_SMTP_PASS=your_app_password
GOTRUE_SMTP_ADMIN_EMAIL=your_email@qq.com
EOF
```

#### 3. 修复Nginx配置
```bash
# 检查nginx配置
docker exec appflowy-cloud-nginx-1 nginx -t

# 如果配置正确，重启nginx
docker restart appflowy-cloud-nginx-1
```

## 测试步骤

### 1. 测试GoTrue服务
```bash
# 健康检查
curl http://8.152.101.166:9999/health

# 用户注册
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  http://8.152.101.166:9999/signup
```

### 2. 测试客户端连接
```bash
# 在PonyNotes客户端中测试注册/登录
# 使用配置的API地址: https://api.xiaomabiji.com
```

### 3. 验证邮件发送
```bash
# 如果配置了真实SMTP，检查邮件是否发送成功
# 检查GoTrue日志中的邮件发送记录
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 | grep -i mail"
```

## 推荐配置

### 开发/测试环境
```env
GOTRUE_MAILER_AUTOCONFIRM=true
# 用户注册后自动确认，无需邮件验证
```

### 生产环境
```env
GOTRUE_MAILER_AUTOCONFIRM=false
GOTRUE_SMTP_HOST=smtp.qq.com
GOTRUE_SMTP_PORT=465
GOTRUE_SMTP_USER=your_email@qq.com
GOTRUE_SMTP_PASS=your_app_password
GOTRUE_SMTP_ADMIN_EMAIL=your_email@qq.com
```

## 下一步行动

1. **立即执行**: 使用方案A快速测试
2. **长期修复**: 使用方案B完整修复
3. **客户端测试**: 在PonyNotes客户端中测试注册/登录功能
4. **监控**: 持续监控服务状态和邮件发送情况

## 故障排除

### 常见问题
1. **GoTrue无法启动**: 检查环境变量和数据库连接
2. **邮件发送失败**: 检查SMTP配置和网络连接
3. **客户端连接失败**: 检查API地址和网络配置
4. **数据库迁移错误**: 清理冲突的数据库对象

### 日志检查
```bash
# 检查GoTrue日志
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 20"

# 检查AppFlowy Cloud日志
ssh root@8.152.101.166 "docker logs appflowy-cloud-appflowy_cloud-1 --tail 20"

# 检查Nginx日志
ssh root@8.152.101.166 "docker logs appflowy-cloud-nginx-1 --tail 20"
``` 