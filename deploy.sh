#!/bin/bash
# SalonAi 一键部署脚本
# 在 VPS 上执行: bash deploy.sh

set -e

echo "╔══════════════════════════════════════╗"
echo "║         SalonAi 部署脚本              ║"
echo "╚══════════════════════════════════════╝"

echo ""
echo "=== 1. 检查 Docker ==="
docker --version || { echo "❌ 请先安装 Docker"; exit 1; }
docker compose version || { echo "❌ 请先安装 Docker Compose"; exit 1; }
echo "✅ Docker 已就绪"

echo ""
echo "=== 2. 检查 .env ==="
if [ ! -f .env ]; then
  cp .env.example .env
  echo "⚠️  已创建 .env，请编辑填写真实值后重新运行此脚本"
  echo "   必填项: REPORT_TOKEN, ADMIN_PASSWORD, NEXT_AUTH_SECRET, OPENAI_API_KEY"
  exit 1
fi
echo "✅ .env 已存在"

echo ""
echo "=== 3. 创建目录 ==="
mkdir -p ssl/acme data
echo "✅ 目录已就绪"

echo ""
echo "=== 4. SSL 证书 ==="
if [ ! -f ssl/fullchain.pem ] || [ ! -f ssl/key.pem ]; then
  echo "⚠️  证书不存在，生成临时自签证书..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/key.pem -out ssl/fullchain.pem \
    -subj "/CN=${DOMAIN:-salon.local}"
  echo "✅ 临时证书已生成（正式使用请执行: DOMAIN=your-domain bash setup-ssl.sh）"
else
  echo "✅ 证书已存在"
fi

echo ""
echo "=== 5. 构建并启动服务 ==="
docker compose up -d --build

echo ""
echo "=== 6. 等待服务就绪 ==="
sleep 5

echo ""
echo "=== 7. 检查状态 ==="
docker compose ps

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         🎉 部署完成！                  ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "下一步："
echo "  1. 从店内 WiFi 上报出口 IP:"
echo "     curl -X POST https://your-domain/internal/report-egress-ip \\"
echo "       -H 'Authorization: Bearer YOUR_REPORT_TOKEN' \\"
echo "       -H 'X-Site-Code: YOUR_SITE_CODE' \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"device_name\":\"test\",\"device_type\":\"manual\"}'"
echo ""
echo "  2. 访问管理面板: https://your-domain/admin"
echo ""
echo "  3. 签发正式 SSL 证书:"
echo "     DOMAIN=ai.your-domain.com bash setup-ssl.sh"
