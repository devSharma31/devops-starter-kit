# DevOps Starter Kit

![CI/CD](https://github.com/devSharma31/devops-starter-kit/actions/workflows/ci-cd.yml/badge.svg?branch=main)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green?logo=fastapi)
![Azure](https://img.shields.io/badge/Azure-App%20Service-0078D4?logo=microsoftazure)
![OpenAI](https://img.shields.io/badge/Azure%20OpenAI-GPT--4o-orange?logo=openai)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform)
![Docker](https://img.shields.io/badge/Docker-Containerised-2496ED?logo=docker)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

A production-style cloud application demonstrating real DevOps and GenAI engineering skills — built for hands-on learning and interview demonstration.

**Live demo:** https://devops-starter-webapp-dev31.azurewebsites.net

---

## What this project demonstrates

| Skill area | What was built |
|---|---|
| Cloud infrastructure | Azure App Service provisioned via Terraform |
| CI/CD pipeline | GitHub Actions — lint → test → deploy → smoke test |
| GenAI integration | Azure OpenAI GPT-4o `/summarize` endpoint |
| Security | API keys in env vars, secret scanning, `.gitignore` |
| Frontend | Dashboard UI served from FastAPI static files |
| IaC | Terraform with import, lifecycle rules, state management |
| Observability | Health check endpoint, post-deploy smoke test |

---

## Architecture

```
Browser / Client
      │
      ▼
Azure App Service (Central India)
      │
      ├── GET  /          → Dashboard UI (HTML/CSS/JS)
      ├── GET  /health    → {"status": "ok"}
      ├── POST /summarize → Azure OpenAI GPT-4o
      └── GET  /docs      → Swagger UI
            │
            ▼
    Azure OpenAI Service (East US 2)
         GPT-4o · temperature 0.3 · max_tokens 150
```

**CI/CD flow:**
```
git push → build-test (ruff + pytest) → deploy (Azure WebApp) → smoke-test (health + AI check)
```

**Infrastructure (Terraform):**
```
Azure Subscription
└── Resource Group: devops-starter-rg (East US)
    ├── App Service Plan: asp-devops-starter (Central India, B1)
    └── Linux Web App: devops-starter-webapp-dev31 (Python 3.11, gunicorn)
```

---

## Tech stack

- **Backend** — Python 3.11, FastAPI, Uvicorn, Gunicorn
- **AI** — Azure OpenAI Service (GPT-4o), openai Python SDK
- **Infrastructure** — Terraform (azurerm ~3.100), Azure App Service
- **CI/CD** — GitHub Actions (ruff lint, pytest, Azure deploy, smoke test)
- **Containerisation** — Docker, docker-compose
- **Security** — python-dotenv, GitHub Secrets, GitHub secret scanning

---

## Local development

### Prerequisites
- Python 3.11+
- Azure subscription (free trial works)
- Azure OpenAI resource with GPT-4o deployed

### 1 — Clone and set up environment

```powershell
git clone https://github.com/devSharma31/devops-starter-kit.git
cd devops-starter-kit
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2 — Configure environment variables

Copy the example file and fill in your values:

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

Visit `http://127.0.0.1:8000` — the dashboard loads in your browser.

Test the AI endpoint:

```bash
curl -X POST http://127.0.0.1:8000/summarize \
  -H "Content-Type: application/json" \
  -d '{"text": "Your text to summarise here"}'
```

### 4 — Run with Docker

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

### POST /summarize

**Request:**
```json
{
  "text": "Text you want summarised"
}
```

**Response:**
```json
{
  "summary": "AI-generated 2-3 sentence summary of your text."
}
```

**Model config:** GPT-4o · temperature `0.3` · max_tokens `150`

---

## CI/CD pipeline

Workflow file: `.github/workflows/ci-cd.yml`

```
push to main
    │
    ▼
build-test
    ├── Checkout code
    ├── Setup Python 3.11
    ├── Install dependencies
    ├── Ruff lint check
    └── Pytest unit tests
    │
    ▼
deploy (needs: build-test)
    ├── Checkout code
    ├── Validate publish profile secret
    └── Deploy to Azure Web App
    │
    ▼
smoke-test (needs: deploy)
    ├── Wait 30s for app warm-up
    ├── GET /health → assert 200
    └── POST /summarize → assert "summary" in response
```

**Required GitHub Secret:**

```
AZURE_WEBAPP_PUBLISH_PROFILE  →  XML from Azure Portal → App Service → Download publish profile
```

---

## Terraform infrastructure

```bash
cd terraform

# Copy and configure variables
copy terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription_id and Azure OpenAI credentials

terraform init
terraform plan    # review before applying
terraform apply
terraform output webapp_url
```

**Key variables in `terraform.tfvars`:**

| Variable | Description |
|---|---|
| `subscription_id` | Azure subscription ID |
| `location` | Resource group region |
| `app_location` | App Service region (can differ from RG) |
| `sku_name` | App Service tier (B1 recommended) |
| `azure_openai_key` | Azure OpenAI API key (sensitive) |
| `azure_openai_endpoint` | Azure OpenAI base endpoint URL |

> **Security:** `terraform.tfvars` is gitignored. Never commit it.

---

## Real-world engineering decisions

**Lazy client initialisation** — the `AzureOpenAI` client is initialised inside `get_openai_client()` rather than at module level. This prevents import-time crashes in CI where OpenAI credentials are not available during the test phase.

**Separate app_location variable** — Azure free trial accounts have zero VM quota in certain regions. By separating the resource group location from the App Service location, resources can be provisioned in a region with available quota without moving the resource group.

**Terraform lifecycle rules** — `prevent_destroy = true` on the resource group prevents accidental deletion via `terraform apply`. `ignore_changes = [tags]` prevents tag drift from triggering unnecessary updates.

**Post-deploy smoke test** — the CI/CD pipeline validates not just that the app deployed, but that the Azure OpenAI integration is responding correctly on the live URL. A deployment that passes unit tests but fails the AI smoke test catches integration-level regressions.

---

## Troubleshooting

**`ModuleNotFoundError: No module named 'app'` in CI**
Set `PYTHONPATH: ${{ github.workspace }}` in the pytest step environment.

**`OpenAIError: Missing credentials` on import**
The client is being initialised at module level. Move it inside a `get_openai_client()` function so it's only called at request time.

**`401 Unauthorized — quota exceeded` on Terraform apply**
Your subscription has zero VM quota in that region. Add `app_location` variable and set it to a region with available quota (e.g. `Central India`).

**Deploy fails with invalid publish profile**
Download a fresh publish profile from the new App Service in Azure Portal. Old profiles from deleted resources are invalid.

**`requirements.txt` parse error in CI**
Re-save as UTF-8 (no UTF-16 BOM). This causes `\x00` null bytes that break `pip install`.

---

## Evidence

Screenshots in `/evidence`:
- CI/CD pipeline — all three jobs green
- Terraform apply output
- Live dashboard at azurewebsites.net
- AI summariser response

---

## License

MIT