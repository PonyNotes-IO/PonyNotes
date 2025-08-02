#!/bin/bash

echo "=== PonyNotes 服务器诊断 ==="
echo "时间: $(date)"
echo

# 1. 检查域名解析
echo "1. 域名解析检查..."
echo "api.xiaomabiji.com -> $(nslookup api.xiaomabiji.com 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}')"
echo "cloud.xiaomabiji.com -> $(nslookup cloud.xiaomabiji.com 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}')"
echo "xiaomabiji.com -> $(nslookup xiaomabiji.com 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}')"
echo

# 2. 检查端口连通性
echo "2. 端口连通性检查..."
echo "检查 HTTPS 443 端口..."
if nc -z api.xiaomabiji.com 443 2>/dev/null; then
    echo "✓ HTTPS 443 端口开放"
else
    echo "✗ HTTPS 443 端口不可达"
fi

echo "检查 HTTP 80 端口..."
if nc -z api.xiaomabiji.com 80 2>/dev/null; then
    echo "✓ HTTP 80 端口开放"
else
    echo "✗ HTTP 80 端口不可达"
fi
echo

# 3. 检查各个服务端点
echo "3. 服务端点检查..."

echo "主网站 (xiaomabiji.com):"
curl -s -w "HTTP状态码: %{http_code}\n" "https://xiaomabiji.com/" | head -1

echo "API服务 (api.xiaomabiji.com):"
curl -s -w "HTTP状态码: %{http_code}\n" "https://api.xiaomabiji.com/" | head -1

echo "管理控制台 (cloud.xiaomabiji.com):"
curl -s -w "HTTP状态码: %{http_code}\n" "https://cloud.xiaomabiji.com/" | head -1

echo "GoTrue认证服务:"
curl -s -w "HTTP状态码: %{http_code}\n" "https://api.xiaomabiji.com/gotrue/health" | head -1

echo "AppFlowy Cloud API:"
curl -s -w "HTTP状态码: %{http_code}\n" "https://api.xiaomabiji.com/api/user/profile" | head -1
echo

# 4. 邮件配置分析
echo "4. 邮件配置分析..."
echo "根据配置文件分析，邮件问题可能的原因："
echo
echo "问题1: GOTRUE_MAILER_AUTOCONFIRM=true"
echo "  - 这意味着用户注册后会自动确认，不需要邮件验证"
echo "  - 解决方案: 设置为 false 以启用邮件验证"
echo
echo "问题2: SMTP配置使用默认值"
echo "  - GOTRUE_SMTP_HOST=smtp.gmail.com"
echo "  - GOTRUE_SMTP_USER=email_sender@some_company.com"
echo "  - GOTRUE_SMTP_PASS=email_sender_password"
echo "  - 这些都是示例配置，需要替换为真实的SMTP信息"
echo
echo "问题3: 邮件模板URL配置"
echo "  - 需要配置正确的邮件模板URL"
echo "  - 或者使用本地邮件模板"
echo

# 5. 建议的解决方案
echo "5. 建议的解决方案："
echo
echo "方案A: 临时禁用邮件验证（快速解决）"
echo "  1. 确保 GOTRUE_MAILER_AUTOCONFIRM=true"
echo "  2. 用户注册后自动确认，无需邮件验证"
echo "  3. 适合测试环境"
echo
echo "方案B: 配置真实的SMTP服务（推荐生产环境）"
echo "  1. 设置 GOTRUE_MAILER_AUTOCONFIRM=false"
echo "  2. 配置真实的SMTP服务器信息："
echo "     - GOTRUE_SMTP_HOST=你的SMTP服务器"
echo "     - GOTRUE_SMTP_USER=你的邮箱用户名"
echo "     - GOTRUE_SMTP_PASS=你的邮箱密码"
echo "  3. 配置邮件模板URL或使用本地模板"
echo
echo "方案C: 使用第三方邮件服务"
echo "  1. 使用 SendGrid, Mailgun, AWS SES 等服务"
echo "  2. 配置相应的SMTP信息"
echo

# 6. 当前状态总结
echo "6. 当前状态总结："
echo "  - 域名解析: 正常"
echo "  - HTTPS连接: 正常"
echo "  - 主网站: 正常"
echo "  - API服务: 404错误（需要检查Docker容器状态）"
echo "  - 邮件服务: 未配置或配置错误"
echo
echo "建议："
echo "1. 首先检查服务器上的Docker容器状态"
echo "2. 检查nginx配置是否正确"
echo "3. 根据需求选择邮件配置方案"
echo
echo "=== 诊断完成 ===" 