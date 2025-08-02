#!/bin/bash

echo "=== PonyNotes 外部访问测试 ==="
echo "时间: $(date)"
echo

# 1. 测试DNS解析
echo "1. DNS解析测试..."
nslookup api.xiaomabiji.com
echo

# 2. 测试SSL证书
echo "2. SSL证书测试..."
openssl s_client -connect api.xiaomabiji.com:443 -servername api.xiaomabiji.com < /dev/null 2>/dev/null | openssl x509 -noout -dates
echo

# 3. 测试根路径
echo "3. 根路径测试..."
curl -s -w "HTTP状态码: %{http_code}\n" "https://api.xiaomabiji.com/" | head -1
echo

# 4. 测试GoTrue健康检查
echo "4. GoTrue健康检查测试..."
curl -s -w "HTTP状态码: %{http_code}\n" "https://api.xiaomabiji.com/gotrue/health" | head -1
echo

# 5. 测试内部服务
echo "5. 内部服务测试..."
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 curl -s http://gotrue:9999/health" 2>/dev/null | head -1
echo

# 6. 测试端口映射
echo "6. 端口映射测试..."
ssh root@8.152.101.166 "netstat -tlnp | grep -E '(8081|8443)'" 2>/dev/null
echo

# 7. 测试系统nginx配置
echo "7. 系统nginx配置测试..."
ssh root@8.152.101.166 "cat /etc/nginx/conf.d/api.xiaomabiji.com.conf" 2>/dev/null
echo

# 8. 测试用户注册
echo "8. 用户注册测试..."
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  "https://api.xiaomabiji.com/gotrue/signup")

echo "$response"
echo

# 9. 测试用户登录
echo "9. 用户登录测试..."
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  "https://api.xiaomabiji.com/gotrue/token?grant_type=password")

echo "$response"
echo

echo "=== 测试完成 ===" 