#!/bin/bash

NGINX_CONF="/opt/blue-green/nginx/nginx.conf"

if grep -q "server blue" "$NGINX_CONF"; then
  CURRENT="blue"
  TARGET="green"
  TARGET_SERVER="green:80"
  TARGET_PORT="8082"
else
  CURRENT="green"
  TARGET="blue"
  TARGET_SERVER="blue:80"
  TARGET_PORT="8081"
fi

echo "  Current : $CURRENT"
echo "  Target  : $TARGET"

echo "  🔍 Health checking $TARGET on port $TARGET_PORT..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$TARGET_PORT")
if [ "$HTTP_CODE" != "200" ]; then
  echo "  ❌ Health check failed (HTTP $HTTP_CODE). Aborting."
  exit 1
fi
echo "  ✅ $TARGET is healthy"

cat > "$NGINX_CONF" << NGINXEOF
upstream active_app {
    server $TARGET_SERVER;
}

server {
    listen 80;

    location / {
        proxy_pass http://active_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
NGINXEOF

docker compose -f /opt/blue-green/docker-compose.yml exec nginx-proxy nginx -s reload

echo "  ✅ Switched: $CURRENT → $TARGET"
