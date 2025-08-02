#!/bin/bash

echo "=== 验证码类型测试 ==="
echo ""

TEST_EMAIL="87103978@qq.com"

echo "1. 测试注册流程..."
echo ""

echo "1.1 发送注册请求..."
REGISTER_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"testpassword123\"}")

echo "注册响应: $REGISTER_RESPONSE"
echo ""

echo "1.2 检查注册验证码..."
ssh root@8.152.101.166 "docker exec appflowy-cloud-postgres-1 psql -U postgres -d postgres -c \"SELECT email, flow_type, created_at FROM auth.flow_state WHERE email = '$TEST_EMAIL' ORDER BY created_at DESC LIMIT 3;\"" 2>/dev/null || echo "无法查询数据库"

echo ""
echo "2. 测试魔法链接流程..."
echo ""

echo "2.1 发送魔法链接请求..."
MAGICLINK_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/magiclink" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\"}")

echo "魔法链接响应: $MAGICLINK_RESPONSE"
echo ""

echo "2.2 检查魔法链接验证码..."
ssh root@8.152.101.166 "docker exec appflowy-cloud-postgres-1 psql -U postgres -d postgres -c \"SELECT email, flow_type, created_at FROM auth.flow_state WHERE email = '$TEST_EMAIL' ORDER BY created_at DESC LIMIT 3;\"" 2>/dev/null || echo "无法查询数据库"

echo ""
echo "3. 测试不同的验证类型..."
echo ""

echo "3.1 使用 MagicLink 类型验证（客户端当前使用）..."
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"token\":\"123456\",\"type\":\"magiclink\"}" \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "3.2 使用 Signup 类型验证..."
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"token\":\"123456\",\"type\":\"signup\"}" \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "4. 检查最新的服务器日志..."
echo ""

ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 5" 2>/dev/null | grep -E "(verify|flow_type|magiclink|signup)" || echo "无法获取日志"

echo ""
echo "=== 测试完成 ==="
echo ""
echo "根据测试结果，问题可能是："
echo "1. 您使用的是魔法链接验证码，但客户端期望注册验证码"
echo "2. 或者您使用的是注册验证码，但客户端使用 MagicLink 类型验证"
echo "3. 验证码类型不匹配导致验证失败" 