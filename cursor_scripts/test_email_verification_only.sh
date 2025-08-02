#!/bin/bash

echo "=== 测试只使用邮箱验证码的注册登录流程 ==="
echo ""

TEST_EMAIL="test_email_verification@example.com"
TEST_PASSWORD="testpassword123"

echo "1. 测试注册流程..."
echo ""

echo "1.1 发送注册请求..."
REGISTER_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

echo "注册响应: $REGISTER_RESPONSE"
echo ""

echo "1.2 检查注册是否成功（应该返回 confirmation_sent_at）..."
if echo "$REGISTER_RESPONSE" | grep -q "confirmation_sent_at"; then
  echo "✅ 注册成功，验证码已发送到邮箱"
else
  echo "❌ 注册失败或验证码未发送"
fi
echo ""

echo "2. 测试使用注册验证码验证..."
echo ""

echo "2.1 使用 Signup 类型验证（客户端修改后使用）..."
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"token\":\"123456\",\"type\":\"signup\"}" \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "2.2 使用 MagicLink 类型验证（客户端修改前使用）..."
curl -s -X POST "https://api.xiaomabiji.com/gotrue/verify" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"token\":\"123456\",\"type\":\"magiclink\"}" \
  -w "\nHTTP状态码: %{http_code}\n"

echo ""
echo "3. 测试登录流程..."
echo ""

echo "3.1 尝试使用密码登录（应该失败，因为邮箱未验证）..."
LOGIN_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/token?grant_type=password" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

echo "登录响应: $LOGIN_RESPONSE"
echo ""

echo "3.2 检查登录是否被阻止..."
if echo "$LOGIN_RESPONSE" | grep -q "Email not confirmed"; then
  echo "✅ 登录被正确阻止，需要先验证邮箱"
else
  echo "❌ 登录未被阻止，可能存在安全问题"
fi
echo ""

echo "4. 检查服务器日志..."
echo ""

ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 10" 2>/dev/null | grep -E "(signup|verify|signupVerification|magiclinkVerification)" || echo "无法获取日志"

echo ""
echo "=== 测试完成 ==="
echo ""
echo "修改说明："
echo "1. ✅ 在 VerifyType 枚举中添加了 Signup 类型"
echo "2. ✅ 修改了 sign_in_with_passcode 方法使用 VerifyType::Signup"
echo "3. ✅ 添加了 verify_signup_with_passcode 方法"
echo "4. ✅ 修改了云服务实现使用新的验证方法"
echo ""
echo "现在客户端将："
echo "- 注册时发送邮箱验证码"
echo "- 验证时使用 Signup 类型而不是 MagicLink 类型"
echo "- 确保验证码类型与验证方式匹配" 