# Real-Time Chat Application

A real-time chat application built with FastAPI (WebSocket) and a vanilla JavaScript frontend, containerized with Docker, reverse-proxied by Nginx, and deployed to AWS EC2 via GitHub Actions CI/CD with Terraform/Terragrunt infrastructure management.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Internet                            │
│                            │                             │
│                     ┌──────┘──────┐                      │
│                     │  :80 (EIP)  │                      │
│                     │   NGINX     │                      │
│                     └──────┬──────┘                      │
│                            │                             │
│                    ┌───────┴────────┐                    │
│                    │                │                     │
│           ┌────────┴──┐    ┌───────┴────────┐            │
│           │  / (HTTP)  │    │  /ws (WS)      │            │
│           │ Serve      │    │ Proxy to       │            │
│           │ index.html │    │ backend:8000   │            │
│           └────────────┘    └───────┬────────┘            │
│                                     │                     │
│                          ┌──────────┴──────────┐          │
│                          │   FastAPI Backend    │          │
│                          │   Port 8000          │          │
│                          │   WebSocket /ws      │          │
│                          └─────────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

### Components

| Component | Technology | Port | Description |
|-----------|-----------|------|-------------|
| **Backend** | Python FastAPI | 8000 | WebSocket server, connection management, message broadcasting |
| **Frontend Proxy** | Nginx | 80 | Serves static HTML, reverse-proxies WebSocket connections |
| **Infrastructure** | Terraform/Terragrunt | — | AWS provisioning (EC2, IAM, OIDC, EIP) |
| **CI/CD** | GitHub Actions | — | Automated deploy on push to `main` |

## Docker Setup

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

- Binds to `0.0.0.0` so the service is reachable from other containers (binding to `127.0.0.1` would make it container-local only).

### Docker Compose

Two services on a shared Compose network:

```yaml
services:
  backend:
    build: .
    container_name: chat-backend
    expose:
      - "8000"

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
```

### Docker Networking

- Compose creates a default bridge network; containers resolve each other by service name (`backend`, `nginx`).
- The backend is not exposed to the host — only Nginx reaches it internally via `backend:8000`.
- Nginx is the sole entry point on port 80.

## Nginx Reverse Proxy

```nginx
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
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
```

- **Static files**: Served from `/usr/share/nginx/html` (mounted from `./frontend`).
- **WebSocket proxy**: The `/ws` location forwards to `backend:8000/ws` (uses service name, not `localhost`).

## WebSocket Through Nginx

Nginx requires explicit headers to upgrade an HTTP connection to a WebSocket tunnel:

- `proxy_set_header Upgrade $http_upgrade` — passes the client's upgrade request.
- `proxy_set_header Connection "upgrade"` — tells the upstream server to switch protocols.
- `proxy_read_timeout 86400s` / `proxy_send_timeout 86400s` — prevents Nginx from closing idle WebSocket connections.

The frontend connects via `ws://<host>/ws` using the `window.location.host` so it works through the reverse proxy without hardcoded URLs.

## CI/CD Pipeline

### Deploy Workflow (`.github/workflows/deploy.yaml`)

On push to `main`:
1. Checkout code
2. SSH into EC2 using `appleboy/ssh-action`
3. Pull latest code, run `docker compose down && docker compose up -d --build`

### Terraform Workflow (`.github/workflows/terraform.yaml`)

Manual `workflow_dispatch`:
1. Checkout code
2. Authenticate to AWS via OIDC (IAM role with GitHub Actions trust)
3. Setup Terraform + Terragrunt
4. Run `terragrunt init`, `plan`, and optionally `apply`

## Infrastructure (Terraform/Terragrunt)

```
infrastructure/
├── config/prod/tenant/terragrunt.hcl   # Terragrunt config (env: prod, region: us-east-1)
└── module/tenant/
    ├── ec2.tf       # EC2 instance + Security Group + Elastic IP
    ├── iam.tf       # IAM role for GitHub Actions (OIDC)
    ├── oidc.tf      # OIDC provider for GitHub
    ├── locals.tf    # Common tags & naming
    ├── outputs.tf   # Instance ID, EIP, SSH command, app URL
    ├── provider.tf  # AWS provider config
    └── variable.tf  # Input variables
```

- EC2 launched in a specific subnet with an Elastic IP.
- Security group allows HTTP (80) from anywhere and SSH (22) from configurable CIDR.
- IAM role with `AdministratorAccess` trusted by GitHub's OIDC for CI/CD.

## Issues Found and Fixes

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | Backend unreachable from Nginx | Uvicorn bound to `127.0.0.1` | Changed `--host` to `0.0.0.0` |
| 2 | Blank Nginx welcome page | Frontend volume mount was missing in `docker-compose.yml` | Added `./frontend:/usr/share/nginx/html:ro` |
| 3 | WebSocket handshake failed | `proxy_pass` used `localhost:8000` (inside Nginx container, `localhost` ≠ backend) | Changed to `http://backend:8000/ws` |
| 4 | WebSocket disconnecting | Missing Upgrade/Connection headers | Added `proxy_set_header Upgrade $http_upgrade` and `Connection "upgrade"` |
| 5 | `plan` failed: multiple subnets matched | `subnet_id` was `null` and 6 default subnets exist in `us-east-1` | Set `subnet_id` explicitly |
| 6 | Public IP changes on stop/start | Default public IP is ephemeral | Added Elastic IP and attached to instance |

## Steps to Deploy

### Local (Docker Compose)

```bash
git clone https://github.com/Henildonda01/DevOps-project-02.git
cd DevOps-project-02
docker compose up -d --build
```

Open `http://localhost` in multiple browser tabs.

### Production (via CI/CD)

1. Push to `main` — GitHub Actions automatically deploys via SSH.
2. Or manually trigger Infrastructure deployment:
   - Go to GitHub → Actions → Terragrunt Init, Plan or Apply
   - Choose `prod`, `tenant`, optionally check `Apply`

### Prerequisites

- Docker & Docker Compose (local)
- AWS credentials with permissions (infra)
- GitHub repository secrets: `EC2_HOST`, `EC2_SSH_KEY`, `AWS_ROLE_ARN`, `AWS_REGION`
