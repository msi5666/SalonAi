#!/bin/bash
# 在 VPS 上执行此脚本签发 Let's Encrypt 证书
# 用法: DOMAIN=ai.example.com bash setup-ssl.sh

set -e

DOMAIN="${DOMAIN:-ai.example.com}"
SSL_DIR="$(dirname "$0")/ssl"

mkdir -p "$SSL_DIR/acme"

if [ ! -d ~/.acme.sh ]; then
  curl https://get.acme.sh | sh
fi

cd "$(dirname "$0")"
docker compose stop nginx 2>/dev/null || true

~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --httpport 80 --server letsencrypt

~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
  --fullchain-file "$SSL_DIR/fullchain.pem" \
  --key-file "$SSL_DIR/key.pem" \
  --reloadcmd "cd $(pwd) && docker compose restart nginx"

echo "=== 证书签发完成 ==="
echo "fullchain: $SSL_DIR/fullchain.pem"
echo "key:       $SSL_DIR/key.pem"

docker compose up -d --build
