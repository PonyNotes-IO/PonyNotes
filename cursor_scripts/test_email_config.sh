#!/bin/bash

echo "=== 邮件配置测试 ==="
echo

# 测试GoTrue服务
echo "1. 测试GoTrue服务连接..."
curl -s -w "HTTP状态码: %{http_code}\n" "https://api.xiaomabiji.com/gotrue/health" || echo "GoTrue服务不可达"

echo

# 测试注册流程
echo "2. 测试用户注册流程..."
echo "尝试注册测试用户..."

# 创建测试注册请求
cat > /tmp/test_signup.json << EOF
{
  "email": "test@example.com",
  "password": "testpassword123"
}
EOF

# 发送注册请求
echo "发送注册请求到: https://api.xiaomabiji.com/gotrue/signup"
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d @/tmp/test_signup.json \
  "https://api.xiaomabiji.com/gotrue/signup")

echo "$response"
echo

# 清理临时文件
rm -f /tmp/test_signup.json

echo "=== 邮件配置分析 ==="
echo
echo "可能的问题："
echo "1. GOTRUE_MAILER_AUTOCONFIRM=true - 用户自动确认，不需要邮件验证"
echo "2. SMTP配置使用默认值，可能无法发送邮件"
echo "3. 邮件模板URL配置不正确"
echo
echo "建议的解决方案："
echo "1. 检查服务器上的环境变量配置"
echo "2. 设置正确的SMTP服务器信息"
echo "3. 将GOTRUE_MAILER_AUTOCONFIRM设置为false以启用邮件验证"
echo "4. 配置正确的邮件模板URL" 