#!/bin/bash

# 修改Docker Nginx配置，添加/auth/v1路径的配置
echo "正在修改Docker Nginx配置..."

# 连接到服务器并修改Nginx配置
ssh root@8.152.101.166 << 'EOF'
# 进入Docker Nginx容器
docker exec appflowy-cloud-nginx-1 sh -c '
# 备份原始配置
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# 添加/auth/v1路径配置
cat > /tmp/auth_location.conf << "AUTH_CONFIG"
        # GoTrue Auth Server (alternative path)
        location /auth/v1 {
            proxy_pass http://gotrue_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
AUTH_CONFIG

# 在/gotrue配置之前插入/auth/v1配置
sed -i "/location \/gotrue {/i\\$(cat /tmp/auth_location.conf)" /etc/nginx/nginx.conf

# 重新加载Nginx配置
nginx -s reload

echo "Nginx配置已更新，添加了/auth/v1路径"
EOF

echo "配置修改完成！" 