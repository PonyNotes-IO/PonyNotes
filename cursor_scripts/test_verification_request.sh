#!/bin/bash

# 测试验证码请求格式
echo "=== 验证码请求格式测试 ==="
echo ""

# 测试邮箱
TEST_EMAIL="87103978@qq.com"
TEST_CODE="123456"

echo "1. 测试错误的请求格式（只发送验证码）..."
echo ""

curl -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TEST_CODE\"}" \
  -w "\nHTTP状态码: %{http_code}\n" \
  -s

echo ""
echo "2. 测试正确的请求格式（包含邮箱地址）..."
echo ""

curl -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"token\":\"$TEST_CODE\",\"type\":\"signup\"}" \
  -w "\nHTTP状态码: %{http_code}\n" \
  -s

echo ""
echo "3. 检查服务器日志..."
echo ""

ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 5" 2>/dev/null | grep -E "(verify|token|email)" || echo "无法获取日志"

echo ""
echo "=== 测试完成 ==="
echo ""
echo "如果第一个请求返回 400 错误，第二个请求返回不同的响应，"
echo "说明问题确实是请求格式不正确。"
echo ""
echo "客户端需要确保在调用验证接口时包含邮箱地址。" 