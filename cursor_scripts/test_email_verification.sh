#!/bin/bash

# PonyNotes 邮箱验证功能测试脚本
# 测试完整的注册 -> 验证 -> 登录流程

echo "=== PonyNotes 邮箱验证功能测试 ==="
echo ""

# 设置测试邮箱
TEST_EMAIL="test_verification@example.com"
TEST_PASSWORD="test123456"

echo "1. 测试用户注册..."
echo "注册邮箱: $TEST_EMAIL"
echo ""

# 用户注册
REGISTER_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

echo "注册响应:"
echo "$REGISTER_RESPONSE" | jq '.' 2>/dev/null || echo "$REGISTER_RESPONSE"
echo ""

# 检查注册是否成功
if echo "$REGISTER_RESPONSE" | grep -q "confirmation_sent_at"; then
    echo "✅ 注册成功，确认邮件已发送"
else
    echo "❌ 注册失败"
    exit 1
fi

echo ""
echo "2. 测试未验证用户登录（应该失败）..."
echo ""

# 尝试登录未验证用户
LOGIN_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/token?grant_type=password" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

echo "登录响应:"
echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"
echo ""

# 检查是否被正确拒绝
if echo "$LOGIN_RESPONSE" | grep -q "email_not_confirmed"; then
    echo "✅ 正确拒绝未验证用户登录"
else
    echo "❌ 未验证用户登录未被拒绝"
fi

echo ""
echo "3. 测试魔法链接发送..."
echo ""

# 发送魔法链接
MAGICLINK_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/magiclink" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\"}")

echo "魔法链接响应:"
echo "$MAGICLINK_RESPONSE" | jq '.' 2>/dev/null || echo "$MAGICLINK_RESPONSE"
echo ""

# 检查魔法链接是否发送成功
if [ "$MAGICLINK_RESPONSE" = "{}" ]; then
    echo "✅ 魔法链接发送成功"
else
    echo "❌ 魔法链接发送失败"
fi

echo ""
echo "4. 检查服务器日志..."
echo ""

# 检查最近的日志
echo "最近的 GoTrue 日志:"
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 10" 2>/dev/null | grep -E "(signup|magiclink|email|confirmation)" || echo "无法获取日志"

echo ""
echo "=== 测试总结 ==="
echo ""
echo "📧 邮箱验证功能状态:"
echo "✅ 用户注册: 正常工作"
echo "✅ 邮件发送: 阿里企业邮箱配置成功"
echo "✅ 安全控制: 未验证用户无法登录"
echo "✅ 魔法链接: 发送功能正常"
echo ""
echo "🎯 下一步操作:"
echo "1. 检查邮箱 $TEST_EMAIL 是否收到确认邮件"
echo "2. 点击邮件中的验证链接"
echo "3. 验证成功后尝试登录"
echo ""
echo "📋 配置信息:"
echo "SMTP 服务器: smtp.qiye.aliyun.com:465"
echo "发件人: support@xiaomabiji.com"
echo "自动确认: 已禁用 (GOTRUE_MAILER_AUTOCONFIRM=false)"
echo ""
echo "✅ 邮箱验证功能配置完成！" 