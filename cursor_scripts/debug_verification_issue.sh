#!/bin/bash

echo "=== 调试验证码问题 ==="
echo ""

# 测试邮箱
TEST_EMAIL="87103978@qq.com"

echo "1. 首先发送魔法链接..."
echo ""

MAGICLINK_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/magiclink" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\"}")

echo "魔法链接响应: $MAGICLINK_RESPONSE"
echo ""

echo "2. 检查数据库中的验证码..."
echo ""

ssh root@8.152.101.166 "docker exec appflowy-cloud-postgres-1 psql -U postgres -d postgres -c \"SELECT email, token_hash, created_at, expires_at FROM auth.flow_state WHERE email = '$TEST_EMAIL' ORDER BY created_at DESC LIMIT 5;\"" 2>/dev/null || echo "无法查询数据库"

echo ""
echo "3. 测试不同的验证请求格式..."
echo ""

echo "3.1 测试缺少邮箱的请求:"
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d '{"token":"123456","type":"signup"}' \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "3.2 测试缺少验证类型的请求:"
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","token":"123456"}' \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "3.3 测试正确的请求格式:"
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","token":"123456","type":"signup"}' \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "4. 检查最新的服务器日志..."
echo ""

ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 10" 2>/dev/null | grep -E "(verify|error|token)" || echo "无法获取日志"

echo ""
echo "=== 调试完成 ==="
echo ""
echo "根据日志分析，问题可能是："
echo "1. 客户端发送的请求缺少必要的参数（邮箱或验证类型）"
echo "2. 验证码已经过期或无效"
echo "3. 验证码类型不匹配（signup vs magiclink）" 