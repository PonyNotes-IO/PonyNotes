#!/bin/bash

echo "=== PonyNotes 用户注册测试 ==="
echo "时间: $(date)"
echo

# 1. 测试GoTrue服务
echo "1. 测试GoTrue服务..."
echo "GoTrue健康检查:"
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 curl -s http://gotrue:9999/health" 2>/dev/null

echo

# 2. 测试用户注册
echo "2. 测试用户注册..."
echo "注册新用户: test@example.com"
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  "http://8.152.101.166:8081/gotrue/signup" 2>/dev/null)

echo "$response"

echo

# 3. 测试用户登录
echo "3. 测试用户登录..."
echo "登录用户: test@example.com"
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  "http://8.152.101.166:8081/gotrue/token?grant_type=password" 2>/dev/null)

echo "$response"

echo

# 4. 测试邮件配置
echo "4. 测试邮件配置..."
echo "检查GoTrue日志中的邮件相关记录:"
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 10 | grep -i mail" 2>/dev/null

echo

# 5. 测试客户端配置
echo "5. 客户端配置建议..."
echo "当前配置:"
echo "  cloud_env.dart: kAppflowyCloudUrl = \"https://api.xiaomabiji.com\""
echo
echo "临时测试配置:"
echo "  cloud_env.dart: kAppflowyCloudUrl = \"http://8.152.101.166:8081\""
echo

# 6. 测试结果分析
echo "6. 测试结果分析..."
echo "如果注册成功，用户将自动确认（无需邮件验证）"
echo "如果登录成功，将返回access_token和refresh_token"
echo "可以在PonyNotes客户端中使用这些token进行认证"

echo

echo "=== 测试完成 ===" 