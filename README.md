# DevOps Starter Kit

![CI/CD](https://github.com/devSharma31/devops-starter-kit/actions/workflows/ci-cd.yml/badge.svg?branch=main)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green?logo=fastapi)
![Azure](https://img.shields.io/badge/Azure-Container%20Apps-0078D4?logo=microsoftazure)
![OpenAI](https://img.shields.io/badge/Azure%20OpenAI-GPT--4o-orange?logo=openai)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)
![Docker](https://img.shields.io/badge/Docker-GHCR-2496ED?logo=docker)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

A production-style cloud application demonstrating DevOps and GenAI engineering — a FastAPI service with an Azure OpenAI GPT-4o summariser, containerised, provisioned with Terraform, and shipped by a GitHub Actions pipeline that builds, deploys and smoke-tests every change.

**Live demo:** https://devops-starter-app-dev31.jollyglacier-afc01775.centralindia.azurecontainerapps.io

> The app scales to zero when idle, so the first request after a quiet period takes ~5–15 seconds while a container starts. After that it responds instantly.

---

## Version history

| Version | What changed | Why |
|---|---|---|
| **v1.0.0** | FastAPI app on Azure App Service, Terraform IaC, GitHub Actions lint → test → deploy | Baseline cloud deployment |
| **v2.0.0** | Azure OpenAI GPT-4o `/summarize` endpoint, dashboard UI, post-deploy AI smoke test | GenAI integration with integration-level testing |
| **v3.0.0** | Migrated hosting to **Azure Container Apps** (scale-to-zero), images on **GHCR**, deploy via **OIDC** with least-privilege RBAC | Zero idle cost, no long-lived deploy credentials, same image locally and in the cloud |

See [What changed in v3](#what-changed-in-v3) for the migration details.

---

## What this project demonstrates

| Skill area | What was built |
|---|---|
| Cloud infrastructure | Azure Container Apps (Consumption, `min_replicas = 0`) provisioned via Terraform |
| Containers | Dockerfile built in CI, pushed to GitHub Container Registry, same image used locally |
| CI/CD | GitHub Actions — lint → test → build & push image → deploy → smoke test |
| GenAI integration | Azure OpenAI GPT-4o `/summarize` endpoint |
| Security | OIDC federated login (no stored Azure credentials), RBAC scoped to the single container app, OpenAI key stored as a Container Apps secret, HTTPS-only ingress |
| IaC | Terraform with import, lifecycle rules, drift handling, state kept out of Git |
| Cost engineering | Scale-to-zero hosting with no Log Analytics workspace — ₹0 when idle |
| Observability | Health endpoint, cold-start-aware post-deploy smoke test |

---

## Architecture

```
Browser / Client
      │  HTTPS (insecure connections disabled)
      ▼
Azure Container Apps — devops-starter-app-dev31 (Central India)
  Consumption profile · min 0 / max 1 replica · 0.25 vCPU · 0.5 GiB
      │
      ├── GET  /          → Dashboard UI (HTML/CSS/JS)
      ├── GET  /health    → {"status": "ok"}
      ├── POST /summarize → Azure OpenAI GPT-4o
      └── GET  /docs      → Swagger UI
            │
            ▼
    Azure OpenAI Service (East US)
         GPT-4o · temperature 0.3 · max_tokens 150
```

**CI/CD flow:**
```
git push → build-test (ruff + pytest) → image (Docker → GHCR) → deploy (OIDC → az containerapp update) → smoke-test (health + AI check)
```

**Infrastructure (Terraform):**
```
Azure Subscription
└── Resource Group: rg-devops-starter-kit (East US)
    ├── Container Apps Environment: cae-devops-starter-kit (Central India)
    │   └── Container App: devops-starter-app-dev31
    └── Azure OpenAI: devops-starter-kit-instance (East US, gpt-4o deployment)*

* created outside Terraform; Terraform passes its endpoint and key to the app
```

---

## Tech stack

- **Backend** — Python 3.11, FastAPI, Uvicorn
- **AI** — Azure OpenAI Service (GPT-4o), openai Python SDK
- **Infrastructure** — Terraform (azurerm ~3.100), Azure Container Apps
- **Containers** — Docker, docker-compose, GitHub Container Registry (GHCR)
- **CI/CD** — GitHub Actions (ruff, pytest, Docker build/push, OIDC deploy, smoke test)
- **Security** — Entra ID workload identity federation (OIDC), Azure RBAC, Container Apps secrets, GitHub secret scanning

---

## Local development

### Prerequisites
- Python 3.11+
- An Azure OpenAI resource with a GPT-4o deployment

### 1 — Clone and set up environment

```powershell
git clone https://github.com/devSharma31/devops-starter-kit.git
cd devops-starter-kit
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2 — Configure environment variables

```powershell
copy .env.example .env
```

```bash
# .env — never commit this file
AZURE_OPENAI_KEY=your_key_here
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4o
AZURE_OPENAI_API_VERSION=2025-01-01-preview
```

### 3 — Run locally

```powershell
uvicorn app.main:app --reload
```

Visit `http://127.0.0.1:8000`.

```bash
curl -X POST http://127.0.0.1:8000/summarize \
  -H "Content-Type: application/json" \
  -d '{"text": "Your text to summarise here"}'
```

### 4 — Run with Docker (same image as production)

```bash
docker compose up --build
```

### 5 — Run tests

```bash
pytest -q
```

---

## API reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Dashboard UI |
| `GET` | `/health` | Service health check |
| `POST` | `/summarize` | AI-powered text summarisation |
| `GET` | `/docs` | Swagger interactive docs |

**POST /summarize** — request `{"text": "..."}`, response `{"summary": "..."}`. Model config: GPT-4o · temperature `0.3` · max_tokens `150`.

---

## CI/CD pipeline

Workflow file: `.github/workflows/ci-cd.yml`

```
push to main
    │
    ▼
build-test ── ruff lint · pytest
    │
    ▼
image ─────── docker build · push ghcr.io/devsharma31/devops-starter-kit:<sha> and :latest
    │
    ▼
deploy ────── azure/login (OIDC, no secrets) · az containerapp update --image <sha>
    │
    ▼
smoke-test ── GET /health (retries for cold start) · POST /summarize → assert "summary"
```

Pull requests run `build-test` only. Image build runs on every push; deploy and smoke test run on `main`.

**GitHub secrets (identifiers only — no passwords or keys):**

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | App registration used by the federated credential |
| `AZURE_TENANT_ID` | Entra ID tenant |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |

The app registration trusts only `repo:devSharma31/devops-starter-kit:ref:refs/heads/main` and holds **Contributor on the container app alone** — it cannot touch anything else in the subscription.

---

## Terraform infrastructure

Secrets and the subscription ID are passed as environment variables, never written to files:

```powershell
cd terraform
$env:TF_VAR_subscription_id       = az account show --query id -o tsv
$env:TF_VAR_azure_openai_endpoint = "<https://your-resource.openai.azure.com/>"
$env:TF_VAR_azure_openai_key      = "<key>"   # or fetch with az cognitiveservices account keys list

terraform init
terraform plan -out tfplan    # review before applying
terraform apply tfplan
terraform output containerapp_url
```

| Variable | Description |
|---|---|
| `subscription_id` | Azure subscription ID (env var) |
| `location` | Resource group region |
| `app_location` | Container Apps region (can differ from RG) |
| `container_app_name` / `container_env_name` | Resource names |
| `container_image` | Initial image; CI/CD rolls out new tags afterwards |
| `azure_openai_key` | Azure OpenAI API key (sensitive, env var) |
| `azure_openai_endpoint` | Azure OpenAI endpoint URL |

> **Security:** `terraform.tfstate` and plan files contain the OpenAI key and are gitignored. `terraform.tfvars` holds only non-secret settings.

---

## What changed in v3

v2 ran on Azure App Service. When the original subscription expired, the web app was deleted and its hostname stopped resolving (NXDOMAIN), which browsers reported as an HTTPS error. Rebuilding on a new subscription surfaced a second problem: the Free (F1) plan rejected deployments with `Site Disabled (403)`, so a working App Service needed the paid B1 tier.

Rather than pay for an always-on plan for a demo app, v3 moves to Azure Container Apps:

| | v2 — App Service | v3 — Container Apps |
|---|---|---|
| Idle cost | B1 billed hourly while the plan exists | ₹0 — scales to zero, within the monthly free grant |
| Artifact | Source zip, built on the server | Docker image, identical locally and in Azure |
| Deploy auth | Publish profile (long-lived secret) | OIDC federated token, no stored credential |
| Deploy permissions | Full publish rights to the web app | Contributor scoped to one container app |
| HTTP | `https_only = false` | Insecure connections disabled |
| Cold start | None | ~5–15 s after idle, handled by smoke-test retries |

The cutover ran both stacks side by side: v3 was built on a feature branch, verified end-to-end, merged, and only then were the App Service resources removed with a reviewed `terraform plan` (2 to destroy, nothing else).

---

## Engineering decisions

**Scale to zero, no Log Analytics** — `min_replicas = 0` means no compute is billed while idle. The environment has no Log Analytics workspace attached, avoiding the one ancillary resource that can bill while idle.

**Terraform owns infrastructure, CI owns the image** — `ignore_changes = [template[0].container[0].image]` lets the pipeline roll out new image tags without Terraform reverting them on the next apply.

**Explicit workload profile** — newer Container Apps environments place apps on the built-in `Consumption` profile. Declaring `workload_profile_name = "Consumption"` keeps Terraform's plan clean instead of trying to null it.

**Least-privilege OIDC** — the federated credential is bound to the `main` branch of this repo, and the role assignment is scoped to the container app resource rather than the resource group or subscription.

**Lazy client initialisation** — the `AzureOpenAI` client is created inside `get_openai_client()` rather than at import, so CI tests run without OpenAI credentials.

**Cold-start-aware smoke test** — the health check retries for up to two minutes before failing, so scale-from-zero is not mistaken for a broken deploy. The AI check then proves the GPT-4o integration works on the live URL.

**Lifecycle protection** — `prevent_destroy = true` on the resource group, which also holds the Azure OpenAI resource.

---

## Troubleshooting

**Browser shows an HTTPS / "site can't be reached" error**
Check DNS first: `nslookup <hostname>`. NXDOMAIN on an `*.azurewebsites.net` or `*.azurecontainerapps.io` name means the resource no longer exists (deleted, or subscription disabled).

**First request is slow**
Expected after idle — the app is scaling from zero. Subsequent requests are fast.

**Deploy job fails at `azure/login`**
The federated credential subject must match exactly: `repo:devSharma31/devops-starter-kit:ref:refs/heads/main`. Workflows using a GitHub `environment:` send a different subject.

**Container App can't pull the image**
The GHCR package must be public, or registry credentials must be configured on the app.

**`ModuleNotFoundError: No module named 'app'` in CI**
Set `PYTHONPATH: ${{ github.workspace }}` in the pytest step.

**`requirements.txt` parse error in CI**
Re-save as UTF-8 without a UTF-16 BOM.

---

## Evidence

Screenshots in `/evidence` (v1/v2, App Service era):
- CI/CD pipeline green, deploy logs, Terraform apply, portal resources, live health check

---

## License

MIT
