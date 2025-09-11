
# DevOps Starter Kit — FastAPI • Docker • CI/CD • Azure • Terraform (foundational)

This is a **sandbox** project to help you demonstrate real DevOps skills safely and honestly for interviews.

## What you get
- **FastAPI** app with `/health`
- **Dockerfile** and `docker-compose.yml`
- **Pytest** unit test
- **GitHub Actions** CI (build + test + lint) — with commented sections for **SonarCloud** and **Azure Web App** deploy
- **Terraform (foundational)** to provision an Azure Resource Group, Linux App Service Plan, and Web App
- **README** instructions + rollback notes

> ⚠️ Auth/secrets are placeholders. Don’t commit real credentials.

---

## 1) Run locally (no Docker)
```bash
python -m venv .venv && source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
# Visit http://127.0.0.1:8000/health
```

## 2) Run with Docker
```bash
docker compose up --build
# Visit http://127.0.0.1:8000/health
```

## 3) Tests
```bash
pytest -q
```

---

## 4) GitHub Actions CI
Workflow file: `.github/workflows/ci-cd.yml`

- Runs on push/PR: setup Python → install deps → lint (ruff) → tests.
- **Optional SonarCloud** step is commented. To enable:
  1. Create a SonarCloud project.
  2. Add repo **Secrets**: `SONAR_TOKEN`.
  3. Add repo **Variables**: `SONAR_ORG`, `SONAR_PROJECT_KEY`.
  4. Uncomment the Sonar step and `sonar-project.properties` content.

- **Optional Deploy to Azure Web App** step is commented. To enable:
  1. Create an Azure Web App (Linux).
  2. In Azure Portal → Web App → **Get publish profile**.
  3. Add repo **Secret**: `AZURE_WEBAPP_PUBLISH_PROFILE` with the XML content.
  4. Set `AZURE_WEBAPP_NAME` in repo **Variables**.
  5. Uncomment the deploy step.
  6. Protect `production` environment in GitHub (requires manual approval).

---

## 5) Terraform (foundational)
**Folder:** `terraform/`

> You need an Azure subscription. This creates: Resource Group, Linux App Service Plan (B1 by default), and a Web App.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars  # edit values
terraform init
terraform plan
terraform apply
```

**Rollback:** `terraform destroy` — or in emergencies, stop the Web App (Portal → Your Web App → Stop).

---

## 6) Rollback strategy (App Service)
- If using **Deploy Slots** (recommended), swap back to last known good slot.
- If using single slot, re-deploy last **green artifact** from Actions → `Download artifact` → redeploy.
- Keep a simple **RUNBOOK.md** with exact commands (add your own screenshots).

---

## 7) What to screenshot for your portfolio
- Successful Actions run (build + test).
- SonarCloud Quality Gate (if enabled).
- Docker container running locally + `/health` response.
- Azure Web App → Deployment Center logs (if deployed).
- Terraform `plan`/`apply` output + resources in Portal.
- Azure Monitor alert rule and a fired test alert email.

---

## 8) Next steps / Extensions
- Add a staging slot and enable **slot swap** in deploy step.
- Remote state for Terraform (Azure Storage).
- Add **PostgreSQL** (Azure Flexible Server) or containerized Postgres with secrets.
- Wire **Azure Monitor** alerts for 5xx spikes and CPU > 80%.
- Add basic **cost tags** to resources.
