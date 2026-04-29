# SalonAi

> 为沙龙、工作室、咖啡厅、自习室、图书馆等共享空间提供 AI 办公助手的一站式部署方案

SalonAi 让你的顾客在连接店内 WiFi 后即可使用 AI 辅助办公，无需安装任何软件。所有服务运行在你的 VPS 上，店内不需要新增任何硬件。

## ✨ 特性

- **零客户端**：浏览器打开即用，基于 LobeChat
- **IP 白名单**：只有店内 WiFi 用户可访问，外网自动拦截
- **AI 网关**：统一代理 AI 请求，支持多提供商、并发控制、RPM 限制、每日 Token 上限
- **管理面板**：Web UI 管理提供商、模型、用量统计、网络状态
- **动态 IP 同步**：店内设备定期上报出口 IP，宽带换 IP 也不怕
- **一键部署**：Docker Compose 启动，Let's Encrypt 自动签发 SSL

## 🏗 架构

```
顾客设备
  → 连接店内 WiFi
  → 访问 https://your-domain
  → VPS Nginx (443 SSL)
  → IP 白名单校验
  → LobeChat → AI Gateway → AI 提供商

店内设备（路由器/手机/ESP8266）
  → 定期 POST /internal/report-egress-ip
  → VPS 记录出口 IP
```

## 🚀 快速开始

### 前提

- 一台 VPS（有公网 IP）
- 一个域名（DNS 指向 VPS，**灰云/DNS Only**，不要走代理）

### 1. 克隆项目

```bash
git clone https://github.com/YOUR_USERNAME/SalonAi.git
cd SalonAi
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填写以下必填项：

| 变量 | 说明 |
|------|------|
| `SITE_CODE` | 站点标识，如 `my-salon` |
| `REPORT_TOKEN` | IP 上报认证令牌，随机长字符串 |
| `ACCESS_STATUS_TOKEN` | 状态查询令牌，随机长字符串 |
| `ADMIN_PASSWORD` | 管理面板密码 |
| `NEXT_AUTH_SECRET` | LobeChat 认证密钥，随机长字符串 |
| `OPENAI_API_KEY` | AI 提供商 API Key（也可在管理面板中配置） |

### 3. 签发 SSL 证书

```bash
# 临时自签证书（先跑通链路）
bash gen-temp-cert.sh

# 正式 Let's Encrypt 证书（正式使用）
DOMAIN=ai.your-domain.com bash setup-ssl.sh
```

### 4. 启动服务

```bash
docker compose up -d --build
```

### 5. 上报店内 IP

从店内 WiFi 环境执行：

```bash
curl -X POST "https://your-domain/internal/report-egress-ip" \
  -H "Authorization: Bearer YOUR_REPORT_TOKEN" \
  -H "X-Site-Code: YOUR_SITE_CODE" \
  -H "Content-Type: application/json" \
  -d '{"device_name":"test","device_type":"manual"}'
```

### 6. 访问管理面板

浏览器打开 `https://your-domain/admin`，输入管理密码登录。

在管理面板中：
1. 添加 **API 提供商**（如 DeepSeek、OpenAI）
2. 添加 **模型**（绑定到提供商，设置 RPM 限制）
3. 配置 **网关**（并发数、每日 Token 上限）

### 7. 让 LobeChat 走网关

在 `.env` 中设置：

```env
OPENAI_PROXY_URL=http://sync-service:8000/gateway
```

然后重启：

```bash
docker compose up -d --build
```

## 📋 管理面板

访问 `/admin`，功能包括：

- **概览**：今日请求数、Token 用量、失败数
- **API 提供商**：添加/删除/启停提供商（名称、Base URL、API Key）
- **模型管理**：添加/删除/启停模型，绑定提供商，设置 RPM 限制
- **网关配置**：最大并发数、每日 Token 上限
- **调用日志**：AI 请求记录（模型、Token、状态、来源 IP）
- **网络状态**：当前出口 IP、上报记录

## 🔧 API 接口

### 上报出口 IP

```
POST /internal/report-egress-ip
Authorization: Bearer <REPORT_TOKEN>
X-Site-Code: <SITE_CODE>
Body: {"device_name":"xxx","device_type":"xxx"}
```

### 查看站点状态

```
GET /internal/site-status
Authorization: Bearer <ACCESS_STATUS_TOKEN>
```

### AI 网关

```
POST /gateway/v1/chat/completions   # OpenAI 兼容接口
GET  /gateway/v1/models             # 可用模型列表
```

### 健康检查

```
GET /healthz
```

## 🔄 IP 同步方案

当店内宽带出口 IP 变化时，需要重新上报。推荐方案：

| 方案 | 说明 | 适用场景 |
|------|------|----------|
| **手动上报** | 到店时 curl 一次 | IP 基本不变 |
| **手机自动化** | Tasker/快捷指令，连 WiFi 自动上报 | 店主每天到店 |
| **ESP8266 心跳** | ¥15 模块，通电自动上报 | 全自动，零维护 |
| **访问码兜底** | IP 不匹配时显示输入码页面 | 万一 IP 没同步 |

## ☁️ Cloudflare 设置

如果你用 Cloudflare 管理 DNS：

- A 记录指向 VPS IP → **灰云（DNS Only）**
- **不要开橙云代理**，否则部分地区可能无法直连

## 📁 项目结构

```
SalonAi/
├── docker-compose.yml        # 服务编排
├── nginx/nginx.conf          # Nginx 反代 + SSL + IP 白名单
├── sync-service/             # 核心服务（FastAPI）
│   ├── app/
│   │   ├── main.py           # 入口 + IP 白名单逻辑
│   │   ├── db.py             # 数据库模块
│   │   ├── gateway.py        # AI 网关代理
│   │   ├── admin.py          # 管理 API
│   │   └── admin_ui.py       # 管理 Web UI
│   ├── Dockerfile
│   └── requirements.txt
├── reporter-examples/        # IP 上报脚本示例
├── gen-temp-cert.sh          # 生成临时自签证书
├── setup-ssl.sh              # 签发 Let's Encrypt 证书
├── deploy.sh                 # 一键部署
├── .env.example              # 环境变量模板
└── README.md
```

## 🛠 更新

```bash
cd SalonAi
git pull
docker compose up -d --build
```

## 📄 License

MIT
