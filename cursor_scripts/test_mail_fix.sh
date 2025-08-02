#!/bin/bash

echo "=== PonyNotes 邮件问题修复和测试 ==="
echo "时间: $(date)"
echo

# 1. 检查当前服务状态
echo "1. 检查服务状态..."
echo "GoTrue服务状态:"
ssh root@8.152.101.166 "docker logs appflowy-cloud-gotrue-1 --tail 5" 2>/dev/null | grep -E "(started|error|failed)" || echo "无法获取GoTrue日志"

echo
echo "AppFlowy Cloud服务状态:"
ssh root@8.152.101.166 "docker logs appflowy-cloud-appflowy_cloud-1 --tail 5" 2>/dev/null | grep -E "(error|failed)" || echo "无法获取AppFlowy Cloud日志"

echo

# 2. 邮件配置分析
echo "2. 邮件配置分析..."
echo "当前邮件配置问题："
echo "  - GoTrue服务正常运行"
echo "  - AppFlowy Cloud服务因数据库迁移错误无法启动"
echo "  - 邮件功能需要AppFlowy Cloud服务支持"
echo

# 3. 临时解决方案
echo "3. 临时解决方案（推荐）："
echo "  方案A: 使用GoTrue自动确认模式"
echo "    - 设置 GOTRUE_MAILER_AUTOCONFIRM=true"
echo "    - 用户注册后自动确认，无需邮件验证"
echo "    - 适合测试和开发环境"
echo
echo "  方案B: 修复数据库迁移问题"
echo "    - 清理数据库迁移冲突"
echo "    - 重启AppFlowy Cloud服务"
echo "    - 配置真实SMTP服务"
echo

# 4. 立即测试
echo "4. 立即测试GoTrue服务..."
echo "测试GoTrue健康检查:"
curl -s -w "HTTP状态码: %{http_code}\n" "http://8.152.101.166:9999/health" | head -1

echo
echo "测试用户注册:"
cat > /tmp/test_signup.json << EOF
{
  "email": "test@example.com",
  "password": "testpassword123"
}
EOF

response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d @/tmp/test_signup.json \
  "http://8.152.101.166:9999/signup")

echo "$response"
rm -f /tmp/test_signup.json

echo

# 5. 邮件配置建议
echo "5. 邮件配置建议："
echo
echo "当前配置（从日志分析）："
echo "  - GOTRUE_MAILER_AUTOCONFIRM: 可能是true（自动确认）"
echo "  - SMTP配置: 使用默认示例配置"
echo "  - 邮件模板: 使用默认模板"
echo
echo "推荐配置："
echo "  测试环境："
echo "    GOTRUE_MAILER_AUTOCONFIRM=true"
echo "    # 用户注册后自动确认，无需邮件"
echo
echo "  生产环境："
echo "    GOTRUE_MAILER_AUTOCONFIRM=false"
echo "    GOTRUE_SMTP_HOST=smtp.qq.com"
echo "    GOTRUE_SMTP_PORT=465"
echo "    GOTRUE_SMTP_USER=your_email@qq.com"
echo "    GOTRUE_SMTP_PASS=your_app_password"
echo "    GOTRUE_SMTP_ADMIN_EMAIL=your_email@qq.com"
echo

# 6. 下一步行动
echo "6. 下一步行动："
echo "  1. 修复AppFlowy Cloud数据库迁移问题"
echo "  2. 重启所有服务"
echo "  3. 测试完整的注册/登录流程"
echo "  4. 配置真实SMTP服务（如需要）"
echo
echo "=== 测试完成 ===" 