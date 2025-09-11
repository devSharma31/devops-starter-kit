# RUNBOOK — DevOps Starter Kit (App Service)

## Environments
- Azure Web App: `devops-starter-webapp-dev31`
- Resource group: `rg-devops-starter`
- Region: Central India
- Plan: F1 (Free), `always_on=false`

## Health & endpoints
- Health: `GET /health` → `{"status":"ok"}`
- Root: redirects to `/health`

## How to deploy (CI/CD)
- Push to `main` → GitHub Actions runs `build-test` then `deploy`.
- Secrets:
  - `AZURE_WEBAPP_PUBLISH_PROFILE` (repo secret)

## Manual deploy (fallback)
1) Download publish profile from the Web App (Portal → Overview → Get publish profile).
2) From VS Code:
   - Update code → commit → `git push`.
   - If CI is down: Portal → Deployment Center → “Sync” (uses last Good package).


## Startup command (required for FastAPI)

gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app

Check/reset:
```
az webapp show    -g rg-devops-starter -n devops-starter-webapp-dev31 --query siteConfig.appCommandLine -o tsv
az webapp config set -g rg-devops-starter -n devops-starter-webapp-dev31 --startup-file "gunicorn -w 2 -k u

Rollback
- Redeploy last green build from Actions (re-run - deploy on a previous successful run).

If app is unhealthy: Portal → Web App → Stop (emergency freeze).

Logs & debugging
- az webapp log config -g rg-devops-starter -n - - devops-starter-webapp-dev31 --application-logging filesystem

```
az webapp log tail   -g rg-devops-starter -n devops-starter-webapp-dev31
```

Terraform (infra)
```
cd terraform
terraform plan
terraform apply
# Clean-up
terraform destroy
```

Security notes

- Never commit secrets.

-  Rotate publish profile if leaked (Portal → Get publish profile).

```
Then:
```powershell
git add RUNBOOK.md
git commit -m "docs: add operational RUNBOOK"
git push
```

## 3) Add an Azure alert (proof you can operate it)

Copy-paste in PowerShell (same sub):
```
# IDs
$RG   = "rg-devops-starter"
$APP  = "devops-starter-webapp-dev31"
$APPID = az webapp show -g $RG -n $APP --query id -o tsv

# Action Group to your email
$EMAIL = "devsharma1619@gmail.com"
az monitor action-group create -g $RG -n ag-email --action email DevNotify $EMAIL
$AGID = az monitor action-group show -g $RG -n ag-email --query id -o tsv

# Alert: low CPU threshold (so it will actually trigger on F1)
az monitor metrics alert create -g $RG -n cpu-gt-5 `
  --scopes $APPID `
  --condition "avg Percentage CPU > 5" `
  --window-size 5m --evaluation-frequency 1m `
  --action $AGID
```


Trigger some load to help it fire:

```
$u = "https://devops-starter-webapp-dev31.azurewebsites.net/health"
1..400 | % { Invoke-WebRequest $u -UseBasicParsing | Out-Null }
```

Screenshot the alert rule + the email and commit as:

```
evidence/09-alert-rule.png
evidence/10-alert-email.png
```

## 4) Repo cosmetics (fast wins)

- Description: “FastAPI demo with Docker, GitHub -Actions CI/CD to Azure App Service, Terraform IaC (foundational).”

- Topics: fastapi, docker, github-actions, terraform, azure, iac.

- License: add LICENSE (MIT).

```
MIT License … (your name, year)
```
```
git add LICENSE && git commit -m "chore: add MIT license" && git push
```

## 5) CV/Interview hooks (use these exact lines)

- “Built a sandboxed CI/CD: ruff + pytest → GitHub Actions deploy to Azure Web App using publish profile secrets.”

- “Provisioned infra with Terraform (foundational): RG, Linux Plan, Web App, health check path.”

- “Set startup command (gunicorn+UvicornWorker), enabled HTTPS-only, added CPU alert with email action group.”

- “Rollback via re-deploy last green; logs via az webapp log tail.”
