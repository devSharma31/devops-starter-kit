# DevOps Starter Kit — FastAPI • Docker • CI/CD • Azure • Terraform

![CI/CD](https://github.com/devSharma31/devops-starter-kit/actions/workflows/ci-cd.yml/badge.svg?branch=main)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

A **sandbox** project to demonstrate real DevOps skills safely and honestly for interviews.

## Why this matters (interview lens)
- Support/Cloud: Health probe + rollback runbook = safe, reversible changes.
- DevOps: GitHub Actions pipeline (lint/test/deploy), Terraform RG/AppService/WebApp.
- Evidence: screenshots in /evidence for CI→CD logs, tf apply outputs, and alerts.
> Demo: push → pipeline → Azure live /health in ~2–3 min.

---

## What’s inside
- **FastAPI** app with `/health` and a root redirect (`/` → `/health`)
- **Dockerfile** and `docker-compose.yml`
- **Pytest** unit test
- **GitHub Actions** CI/CD (lint + test + **deploy to Azure Web App**)
- **Terraform (foundational)**: Azure Resource Group, Linux App Service Plan, Web App
- **README** instructions, rollback notes, and **evidence** screenshots

> ⚠️ Never commit secrets. Use GitHub **Secrets**.

---

## Quick Start
1. **Fork/clone** this repo.
2. **Secrets (Repo → Settings → Secrets & variables → Actions):**
   - `AZURE_WEBAPP_NAME`, `AZURE_RESOURCE_GROUP`, `AZURE_PUBLISH_PROFILE` (or OIDC if you’ve set it up)
3. **Run locally**:
   ```bash
   uvicorn app.main:app --reload
   curl http://127.0.0.1:8000/health
4. **Deploy: push to main. Check Actions → on success, browse https://<webapp-name>.azurewebsites.net/health.

---
## Prereqs
- Python **3.11+**
- Git
- (Optional) Docker Desktop
- Azure CLI (`az`) and Terraform (only needed if you run Terraform locally)

---

## 1) Run locally

### Windows (PowerShell)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
# http://127.0.0.1:8000/health

```

### MacOS / Linux
```
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
# http://127.0.0.1:8000/health

```

## 2) Run with Docker
docker compose up --build
```
http://127.0.0.1:8000/health
```



## 3) Tests
```
pytest -q
```


## 4) CI/CD with GitHub Actions

Workflow: .github/workflows/ci-cd.yml

Pipeline

- On push/PR to main: Setup Python → install deps → ruff → pytest

- Then deploys to Azure Web App using a Publish Profile secret

Required repo secret (one-time)

-AZURE_WEBAPP_PUBLISH_PROFILE → paste the XML from Azure Portal → App Service → Get publish profile
(or via CLI: az webapp deployment list-publishing-profiles --resource-group <rg> --name <webapp> --xml)


App name

-Hard-coded in the workflow deploy job:
```
env:
  AZURE_WEBAPP_NAME: devops-starter-webapp-dev31
```
Change here if you rename the app.


## 5) Terraform (foundational)
```
Folder: terraform/ — Creates Resource Group, Linux App Service Plan, Web App.
```
```
cd terraform
# Windows: copy terraform.tfvars.example terraform.tfvars
# macOS/Linux:
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars:
# - subscription_id = "<your-sub-id>"
# - webapp_name     = "devops-starter-webapp-<unique>"
# - location        = "Central India" (or nearest)
# - sku_name        = "F1" (Free; if unavailable, use "B1")
terraform init
terraform plan
terraform apply
```

Outputs
```
terraform output webapp_url
```

Refresh-only apply (nice for screenshots)
```
terraform apply -refresh-only
```

Rollback / clean-up
terraform destroy
```
# Emergency: stop Web App in Portal
```

## 6) App Service configuration (how it boots)

- Startup command required for FastAPI on App Service:
```
gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app
```

(Set via Terraform/CLI.)

- HTTPS only:
```
az webapp update -g rg-devops-starter -n devops-starter-webapp-dev31 --set httpsOnly=true
```

- Free (F1) plan: always_on = false and cold starts are normal after idle.


## 7) Proofs & Screenshots

Place all images in /evidence:

- CI → CD success:

- Deploy logs:

- Terraform apply (refresh-only) & outputs:

- Azure resources:

- Live health:

(Optional extras)

- Secrets present (name only): evidence/06-secrets-present.png

- Startup command set: evidence/07-startup-cmd.png

- App logs (startup): evidence/08-log-startup.png

- Alerts (rule + email): evidence/09-alert-rule.png, evidence/10-alert-email.png



## 8) Extensions 

- Deployment Slots + slot swap for zero-downtime rollouts

- Remote state for Terraform (Azure Storage + SAS)

- PostgreSQL (Azure Flexible Server) or containerized DB (secrets in Key Vault)

- Azure Monitor metrics/alerts (CPU, 5xx, latency p95, availability SLO)

- Cost tags on resources (project, owner, env)



## 9) Troubleshooting quickies

- Deploy step: “Missing AZURE_WEBAPP_PUBLISH_PROFILE”
  Re-create the repo secret and paste the full XML (don’t trim).

- App returns 500 after deploy
  Ensure startup command is set, then restart:
```
az webapp config set -g rg-devops-starter -n devops-starter-webapp-dev31 --startup-file "gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app"

az webapp restart     -g rg-devops-starter -n devops-starter-webapp-dev31
```

- Pytest import error for app
  Ensure app/__init__.py exists and CI sets PYTHONPATH if needed.

- requirements.txt parse error
  Re-save as UTF-8/ASCII (no UTF-16 BOM / null bytes).




## 10) License

MIT (or your choice).
```
::contentReference[oaicite:0]{index=0}
```
