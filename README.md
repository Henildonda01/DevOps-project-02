# 💬 Real-Time Chat Application

<p align="center">
  <img src="https://img.shields.io/badge/status-live-success?style=flat-square" alt="Status">
  <img src="https://img.shields.io/badge/python-3.11-blue?style=flat-square" alt="Python">
  <img src="https://img.shields.io/badge/FastAPI-0.103+-green?style=flat-square" alt="FastAPI">
  <img src="https://img.shields.io/badge/nginx-alpine-brightgreen?style=flat-square" alt="Nginx">
  <img src="https://img.shields.io/badge/docker-compose-2496ED?style=flat-square&logo=docker" alt="Docker">
  <img src="https://img.shields.io/badge/terraform-1.14+-844FBA?style=flat-square&logo=terraform" alt="Terraform">
  <img src="https://img.shields.io/badge/AWS-EC2-FF9900?style=flat-square&logo=amazonaws" alt="AWS">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License">
</p>

A **real-time chat application** built with FastAPI (WebSocket) and vanilla JavaScript, fully containerized with Docker, reverse-proxied by Nginx, and deployed to AWS EC2 via **GitHub Actions CI/CD** with **Terraform/Terragrunt** infrastructure management.

> 🌐 **Live Application:** [http://100.30.90.253/](http://100.30.90.253/)

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture Diagram](#-architecture-diagram)
- [Docker Setup](#-docker-setup)
- [Docker Networking](#-docker-networking)
- [Nginx Reverse Proxy](#-nginx-reverse-proxy)
- [WebSocket Through Nginx](#-websocket-through-nginx)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Infrastructure (Terraform/Terragrunt)](#-infrastructure-terraformterragrunt)
- [Issues Found and Fixes](#-issues-found-and-fixes)
- [Submission Instructions](#-submission-instructions)
- [Important Notes](#-important-notes)

---

## 📖 Project Overview

This project demonstrates a **production-style DevOps deployment** of a multi-user real-time chat application. The stack consists of:

| Component | Technology | Role |
|-----------|-----------|------|
| **Backend** | Python FastAPI (`:8000`) | WebSocket server handling real-time messaging, connection management, and broadcasting |
| **Frontend** | Vanilla JavaScript + HTML/CSS | Single-page chat client with modern UI |
| **Reverse Proxy** | Nginx (`:80`) | Serves static files, proxies WebSocket connections, single entry point |
| **Infrastructure** | Terraform + Terragrunt | Provisions AWS resources (EC2, EIP, Security Groups, IAM, OIDC) |
| **CI/CD** | GitHub Actions | Automates deployment on push to `main` using OIDC authentication |

### Key Features

- ✅ Real-time messaging via WebSocket
- ✅ Multiple concurrent users with unique guest names
- ✅ Online user count and connection status
- ✅ Auto-scroll, self/other message styling
- ✅ Persistent Elastic IP for stable access
- ✅ Docker containers with auto-restart
- ✅ Production-ready Nginx reverse proxy
- ✅ Full infrastructure as code (Terraform)
- ✅ Automated CI/CD pipeline

---

## 🏗️ Architecture Diagram

```
                         INTERNET
                            │
                            ▼
                 ┌─────────────────────────┐
                 │ Elastic IP (Public IP)  │
                 │ 100.30.90.253           │
                 └──────────┬──────────────┘
                            │ HTTP / WS
                            ▼
                 ┌─────────────────────────┐
                 │       AWS EC2 Host      │
                 │  ┌───────────────────┐  │
                 │  │ nginx container   │  │
                 │  │ - serves /        │  │
                 │  │ - proxies /ws     │  │
                 │  └───────────────────┘  │
                 │  ┌───────────────────┐  │
                 │  │ backend container │  │
                 │  │ - FastAPI /ws     │  │
                 │  │ - port 8000       │  │
                 │  └───────────────────┘  │
                 └─────────────────────────┘
```

## 🔄 CI/CD Pipeline Diagram

```
          GitHub Actions
               │
               │ Checkout + id-token write
               ▼
        ┌────────────────────┐
        │ .github/workflows/ │
        │   terraform.yaml   │
        └─────────┬──────────┘
                  │ role-to-assume
                  ▼
        ┌─────────────────────────────────────────┐
        │ IAM Role: chat-app-prod-github-actions  │
        │ - Trusted by GitHub OIDC                │
        │ - AdministratorAccess                   │
        └─────────┬───────────────────────────────┘
                  │ AssumeRoleWithWebIdentity
                  ▼
        ┌────────────────────────────┐
        │ AWS Terraform / Terragrunt │
        │ config/prod/tenant         │
        └─────────┬──────────────────┘
                  │ provisions
                  ▼
        ┌────────────────────────────┐
        │ EC2 instance + Docker      │
        │ nginx + backend            │
        └────────────────────────────┘
```

---

## 🐳 Docker Setup

### Dockerfile (Backend)

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/main.py .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Key detail:** The `--host 0.0.0.0` flag binds to all network interfaces inside the container. Binding to `127.0.0.1` (the default) would make the backend unreachable from other containers.

### Docker Compose

```yaml
version: '3.8'

services:
  backend:
    build: .
    container_name: chat-backend
    expose:
      - "8000"
    restart: always

  nginx:
    image: nginx:alpine
    container_name: chat-nginx
    ports:
      - "80:80"
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend
    restart: always
```

**Note:** Both services use `restart: always` to ensure containers restart automatically if the server reboots (production requirement).

---

## 🌐 Docker Networking

- Docker Compose creates a **default bridge network** for the project.
- Containers communicate via **service names** (`backend`, `nginx`) — not IP addresses.
- The backend is **not exposed to the host** (`expose: ["8000"]` only makes it available within the Compose network).
- Nginx is the **sole entry point** on port `80` (mapped to the host).
- Communication flow: `Browser → Host:80 → Nginx → backend:8000`

```
┌─────────┐     :80     ┌──────────┐     backend:8000    ┌──────────┐
│ Browser │ ──────────► │  Nginx   │ ──────────────────► │  Backend │
└─────────┘             └──────────┘                     └──────────┘
```

---

## 🔄 Nginx Reverse Proxy

```nginx
events {
    worker_connections 1024;
}

http {
    include mime.types;

    server {
        listen 80;

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }

        location /ws {
            proxy_pass http://backend:8000/ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400s;
            proxy_send_timeout 86400s;
        }
    }
}
```

### How It Works

1. **`location /`** — Serves static HTML/JS files from `/usr/share/nginx/html` (mounted from `./frontend/`).
2. **`location /ws`** — Intercepts WebSocket upgrade requests and proxies them to the FastAPI backend.
3. **`proxy_pass http://backend:8000/ws`** — Uses the Docker service name `backend`, not `localhost` (critical inside containers).
4. **Timeouts** — Set to 24 hours (`86400s`) to prevent Nginx from closing idle WebSocket connections.

---

## 🔌 WebSocket Through Nginx

WebSocket connections start as HTTP requests with an `Upgrade: websocket` header. Nginx requires explicit configuration to handle this upgrade:

| Header | Purpose |
|--------|---------|
| `proxy_set_header Upgrade $http_upgrade` | Passes the client's WebSocket upgrade request to the backend |
| `proxy_set_header Connection "upgrade"` | Tells the upstream server to switch protocols |
| `proxy_http_version 1.1` | WebSocket requires HTTP/1.1 (not 1.0) |
| `proxy_read_timeout 86400s` | Keeps idle connections open for long-lived WebSocket sessions |

The frontend connects dynamically using:
```javascript
const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
const wsUrl = `${protocol}//${window.location.host}/ws`;
```

This ensures the WebSocket URL works correctly through Nginx without hardcoded addresses.

---

## 🔄 CI/CD Pipeline

### Deploy Workflow (`.github/workflows/deploy.yaml`)

Triggers automatically on **push to `main`**:

```
Git Push (main) → Checkout → SSH into EC2 → git pull → docker compose down → docker compose up -d --build
```

The workflow uses `appleboy/ssh-action` with:
- `EC2_HOST` — Elastic IP of the EC2 instance (GitHub secret)
- `EC2_SSH_KEY` — Private key for SSH access (GitHub secret)

### Terraform Workflow (`.github/workflows/terraform.yaml`)

Manual trigger via `workflow_dispatch` for infrastructure management:

```
workflow_dispatch → Checkout → AWS OIDC Auth → Setup Terraform → Setup Terragrunt → Init → Plan → Apply (optional)
```

Uses **GitHub OIDC** to authenticate to AWS — no static credentials needed.

---

## 🏗️ Infrastructure (Terraform/Terragrunt)

### Directory Structure

```
infrastructure/
├── config/prod/tenant/
│   └── terragrunt.hcl              # Environment config (region, backend, inputs)
└── module/tenant/
    ├── ec2.tf                       # EC2 instance, Security Group, Elastic IP, SSH key
    ├── iam.tf                       # IAM role for GitHub Actions with OIDC trust
    ├── oidc.tf                      # GitHub OIDC provider
    ├── locals.tf                    # Common tags and naming
    ├── outputs.tf                   # Instance ID, EIP, private key, SSH command, app URL
    ├── provider.tf                  # AWS provider configuration
    └── variable.tf                  # Input variables
```

### Resources Provisioned

| Resource | Purpose |
|----------|---------|
| **EC2 Instance** (t3.micro) | Runs Docker with the chat application |
| **Elastic IP** | Static public IP — persists across instance stops |
| **Security Group** | HTTP (80) from anywhere, SSH (22) from CIDR |
| **IAM Role + OIDC** | GitHub Actions authentication to AWS |
| **SSH Key Pair** | Terraform-managed RSA key pair for SSH access |
| **User Data** | Installs Docker Engine + Docker Compose on first boot |

### Infrastructure Diagram

```
          GitHub Actions OIDC
                   │
                   ▼
   ┌──────────────────────────────────┐
   │ Terraform Workflow               │
   │ .github/workflows/terraform.yaml │
   │ id-token: write                  │
   └───────────┬──────────────────────┘
               │
               ▼
   ┌──────────────────────────────────────────────────┐
   │ IAM Role: chat-app-prod-github-actions           │
   │ - Trusted by token.actions.githubusercontent.com │
   │ - sts:AssumeRoleWithWebIdentity                  │
   │ - AdministratorAccess                            │
   └───────────┬──────────────────────────────────────┘
               │
               ▼
   ┌──────────────────────────────────┐
   │ Terraform / Terragrunt           │
   │ infrastructure/config/prod/tenant│
   └───────────┬──────────────────────┘
               │
               ▼
   ┌───────────────────────────┐
   │ AWS Resources             │
   │ - aws_iam_oidc_provider   │
   │ - aws_iam_role            │
   │ - aws_instance (EC2)      │
   │ - aws_eip                 │
   │ - aws_security_group      │
   └───────────────────────────┘
```

### EC2 User Data (First Boot Setup)

```bash
#!/bin/bash
set -e
apt-get update -y
apt-get install -y docker.io docker-compose-v2
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu
```

---

## 🐛 Issues Found and Fixes

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | 🔴 Backend unreachable from Nginx | Uvicorn bound to `127.0.0.1` (container-local) | Changed `--host` to `0.0.0.0` in Dockerfile |
| 2 | 🔴 Blank "Welcome to Nginx" page | Frontend volume mount missing | Added `./frontend:/usr/share/nginx/html:ro` to docker-compose |
| 3 | 🔴 WebSocket handshake failed | `proxy_pass` used `localhost:8000` (wrong container) | Changed to `http://backend:8000/ws` (service name) |
| 4 | 🔴 WebSocket disconnecting immediately | Missing `Upgrade`/`Connection` headers | Added `proxy_set_header Upgrade $http_upgrade` and `Connection "upgrade"` |
| 5 | 🔴 `terraform plan` failed: multiple subnets | `subnet_id` was `null`, 6 default subnets in `us-east-1` | Set explicit `subnet_id` |
| 6 | 🔴 Public IP changes on instance stop/start | Default public IP is ephemeral | Added Elastic IP (`aws_eip`) attached to instance |
| 7 | 🔴 `InvalidKeyPair.NotFound: chat-app` | Key pair didn't exist in AWS | Added `tls_private_key` + `aws_key_pair` resources in Terraform |
| 8 | 🔴 OIDC `AssumeRoleWithWebIdentity` denied | `ForAllValues:StringEquals` on `iss` condition blocked auth | Simplified trust policy — removed `iss` + `ForAllValues` |
| 9 | 🔴 HTTP `ERR_CONNECTION_TIMED_OUT` | Default security group from EC2 module didn't allow HTTP | Set `create_security_group = false` in module |

---

## 📬 Submission Instructions

### 1. GitHub Repository

```bash
git clone https://github.com/Henildonda01/DevOps-project-02.git
```

### 2. Live Application

> 🌐 **http://100.30.90.253/**

Open the URL in multiple browser tabs to test real-time chat functionality.

### 3. Architecture Diagram

See the [Architecture Diagram](#-architecture-diagram) section above.

### 4. README Documentation

You are reading it! This document covers all aspects of the project.

### 5. Local Deployment

```bash
# Clone the repository
git clone https://github.com/Henildonda01/DevOps-project-02.git
cd DevOps-project-02

# Build and start containers
docker compose up -d --build

# Access the application
open http://localhost
```

### 6. Production Deployment via CI/CD

Push to `main` to trigger automated deployment:

```bash
git add .
git commit -m "update"
git push origin main
```

GitHub Actions will automatically SSH into EC2, pull the code, and redeploy.

### 7. Infrastructure Deployment

Trigger manually via GitHub Actions → Terragrunt workflow, or run locally:

```bash
cd infrastructure/config/prod/tenant
terragrunt init
terragrunt plan
terragrunt apply
```

After apply, save the SSH private key:

```bash
terragrunt output -raw private_key > ~/chat-app.pem
chmod 400 ~/chat-app.pem
ssh -i ~/chat-app.pem ubuntu@100.30.90.253
```

---

## ⚠️ Important Notes

1. **This is a DevOps assignment** — the focus is on Docker, networking, Nginx, CI/CD, and deployment, not backend development.
2. **The application code is unchanged** — all work was done on configuration, infrastructure, and deployment.
3. **Production-style environment** — the system uses Elastic IP, auto-restarting containers, proper reverse proxy, and CI/CD.
4. **Containers auto-restart** — both services use `restart: always` in docker-compose.yml.
5. **WebSocket works through Nginx** — verified with proper `Upgrade` headers and proxy configuration.
6. **Multiple users** — the FastAPI backend supports concurrent WebSocket connections with real-time broadcasting.
7. **All infrastructure is code** — EC2, networking, IAM, OIDC, and key pairs are managed via Terraform.
8. **Secure CI/CD** — GitHub Actions authenticates to AWS via OIDC (no static keys).

---

## 🛠️ Tech Stack

```
├── Backend        │  Python 3.11  │  FastAPI  │  Uvicorn  │  WebSockets
├── Frontend       │  Vanilla JS   │  HTML5    │  CSS3     │
├── Proxy          │  Nginx (Alpine)
├── Container      │  Docker       │  Docker Compose
├── Cloud          │  AWS EC2      │  Elastic IP  │  Security Groups
├── IAC            │  Terraform    │  Terragrunt  │  HCL
├── CI/CD          │  GitHub Actions  │  OIDC    │  SSH
└── OS             │  Ubuntu 24.04 (AMI)
```

---

<p align="center">
  <sub>Built with ❤️ as part of DevOps Engineering Assignment</sub>
  <br>
</p>
