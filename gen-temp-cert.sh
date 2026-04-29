#!/bin/bash
# 生成临时自签证书，让 nginx 能启动
# 之后再用 acme.sh 签发正式的 Let's Encrypt 证书

set -e

SSL_DIR="$(dirname "$0")/ssl"
mkdir -p "$SSL_DIR"

if [ -f "$SSL_DIR/fullchain.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
  echo "证书已存在，跳过"
  exit 0
fi

echo "生成临时自签证书..."
openssl req -x509 -nodes \
  -days 365 \
  -newkey rsa:2048 \
  -keyout "$SSL_DIR/key.pem" \
  -out "$SSL_DIR/fullchain.pem" \
  -subj "/CN=${DOMAIN:-ai.example.com}"

echo "临时证书已生成"
echo "启动服务后，请执行 bash setup-ssl.sh 签发正式证书"
