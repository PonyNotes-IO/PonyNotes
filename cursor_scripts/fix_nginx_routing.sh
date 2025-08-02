#!/bin/bash

echo "=== PonyNotes Nginx路由修复 ==="
echo "时间: $(date)"
echo

# 1. 检查当前状态
echo "1. 检查当前状态..."
echo "GoTrue服务状态:"
ssh root@8.152.101.166 "docker ps | grep gotrue" 2>/dev/null

echo
echo "Docker nginx状态:"
ssh root@8.152.101.166 "docker ps | grep nginx" 2>/dev/null

echo

# 2. 测试内部服务
echo "2. 测试内部服务..."
echo "GoTrue健康检查:"
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 curl -s http://gotrue:9999/health" 2>/dev/null

echo
echo "Docker nginx根路径:"
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 curl -s http://localhost/" 2>/dev/null

echo

# 3. 修复nginx配置
echo "3. 修复nginx配置..."
echo "备份当前配置..."
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup" 2>/dev/null

echo "修改/gotrue路由配置..."
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 sed -i 's|location /gotrue {|location /gotrue/ {|g' /etc/nginx/nginx.conf" 2>/dev/null
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 sed -i 's|proxy_pass http://gotrue_backend;|proxy_pass http://gotrue_backend/;|g' /etc/nginx/nginx.conf" 2>/dev/null

echo "测试nginx配置..."
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 nginx -t" 2>/dev/null

echo "重启Docker nginx..."
ssh root@8.152.101.166 "docker restart appflowy-cloud-nginx-1" 2>/dev/null

echo

# 4. 测试修复结果
echo "4. 测试修复结果..."
echo "等待服务启动..."
sleep 5

echo "测试内部/gotrue路由:"
ssh root@8.152.101.166 "docker exec appflowy-cloud-nginx-1 curl -s http://localhost/gotrue/health" 2>/dev/null

echo
echo "测试外部访问:"
curl -s "http://8.152.101.166:8081/gotrue/health" 2>/dev/null

echo

# 5. 测试用户注册
echo "5. 测试用户注册..."
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  "http://8.152.101.166:8081/gotrue/signup" 2>/dev/null)

echo "$response"

echo

# 6. 测试用户登录
echo "6. 测试用户登录..."
response=$(curl -s -w "\nHTTP状态码: %{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  "http://8.152.101.166:8081/gotrue/token?grant_type=password" 2>/dev/null)

echo "$response"

echo

echo "=== 修复完成 ===" 