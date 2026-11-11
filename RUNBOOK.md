# RUNBOOK — DevOps Starter Kit (v3, Azure Container Apps)

## Service overview

| Item | Value |
|---|---|
| Container App | `devops-starter-app-dev31` |
| Environment | `cae-devops-starter-kit` (Central India, Consumption profile) |
| Resource group | `rg-devops-starter-kit` (East US) |
| Azure OpenAI | `devops-starter-kit-instance` (East US), deployment `gpt-4o` |
| Image | `ghcr.io/devsharma31/devops-starter-kit:<git-sha>` (public package) |
| URL | https://devops-starter-app-dev31.jollyglacier-afc01775.centralindia.azurecontainerapps.io |
| Scaling | min 0 / max 1 replica — scales to zero after ~5 min idle |

Shell variables used below:

```powershell
$RG  = "rg-devops-starter-kit"
$APP = "devops-starter-app-dev31"
$URL = "https://" + (az containerapp show -n $APP -g $RG --query properties.configuration.ingress.fqdn -o tsv)
```

---

## Health checks

```powershell
Invoke-WebRequest "$URL/health" -TimeoutSec 60 | Select-Object StatusCode, Content   # expect 200 {"status":"ok"}

az containerapp revision list -n $APP -g $RG `
  --query "[].{name:name, active:properties.active, health:properties.healthState, running:properties.runningState}" -o table
```

`runningState` of `ScaledToZero` is normal when idle. The first request after idle takes ~5–15 s.

---

## Deploy

**Normal path:** merge or push to `main`. GitHub Actions runs build-test → image → deploy → smoke-test.

**Manual deploy of a specific image** (CI unavailable):

```powershell
az containerapp update -n $APP -g $RG --image ghcr.io/devsharma31/devops-starter-kit:<git-sha>
```

**Pipeline auth:** OIDC via app registration `gh-devops-starter-kit-deploy`. GitHub secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` are identifiers only. The federated credential trusts `repo:devSharma31/devops-starter-kit:ref:refs/heads/main`; the role is Contributor on the container app only.

---

## Rollback

Revision mode is `Single`, so roll back by redeploying a previous image tag:

```powershell
# Find the last good commit SHA in Actions (a green run), then:
az containerapp update -n $APP -g $RG --image ghcr.io/devsharma31/devops-starter-kit:<good-sha>
```

Or re-run the deploy job of the last green workflow run in GitHub Actions.

---

## Logs and debugging

No Log Analytics workspace is attached (keeps idle cost at zero), so use live streams:

```powershell
az containerapp logs show -n $APP -g $RG --type console --follow   # app stdout/stderr
az containerapp logs show -n $APP -g $RG --type system  --follow   # scaling, image pulls, probes
```

Send a request in another tab to wake the app if it is scaled to zero.

| Symptom | Likely cause | Check |
|---|---|---|
| Browser HTTPS / DNS error | Resource or subscription gone | `nslookup <fqdn>` — NXDOMAIN means the app no longer exists |
| `/summarize` returns 500 | OpenAI key, endpoint or deployment wrong | `az containerapp show -n $APP -g $RG --query properties.template.containers[0].env` |
| Revision unhealthy after deploy | Image fails to start or wrong port | System logs; container must listen on 8000 |
| Image pull failure | GHCR package private | Package settings → visibility Public |
| Deploy job fails at login | Federated credential subject mismatch | `az ad app federated-credential list --id <client-id>` |

---

## Secrets and rotation

**Rotate the Azure OpenAI key:**

```powershell
az cognitiveservices account keys regenerate -n devops-starter-kit-instance -g $RG --key-name key1
# then re-apply Terraform so the container app secret is updated
cd terraform
$env:TF_VAR_azure_openai_key = az cognitiveservices account keys list -n devops-starter-kit-instance -g $RG --query key1 -o tsv
terraform plan -out tfplan; terraform apply tfplan; Remove-Item tfplan
```

There is no stored Azure deploy credential to rotate — OIDC tokens are issued per workflow run.

---

## Terraform

Run from Azure Cloud Shell (persistent storage) or any machine with the state file:

```powershell
cd terraform
$env:TF_VAR_subscription_id       = az account show --query id -o tsv
$env:TF_VAR_azure_openai_endpoint = az cognitiveservices account show -n devops-starter-kit-instance -g rg-devops-starter-kit --query properties.endpoint -o tsv
$env:TF_VAR_azure_openai_key      = az cognitiveservices account keys list -n devops-starter-kit-instance -g rg-devops-starter-kit --query key1 -o tsv

terraform plan -out tfplan    # always review: nothing unexpected to destroy
terraform apply tfplan
Remove-Item tfplan            # plan files contain the key
```

`terraform.tfstate` and `tfplan` contain the OpenAI key in plain text and are gitignored — never commit them.

---

## Cost controls

- Idle cost is ₹0: no replicas run while idle and no Log Analytics workspace is attached.
- Azure OpenAI bills per token only; demo usage is negligible.
- Keep a subscription budget alert in Cost Management (Budgets) as a safety net.
- To take the app fully offline: `az containerapp ingress disable -n $APP -g $RG` (re-enable with `ingress enable --type external --target-port 8000`).

---

## Incident log

**2026-11-10 — Live demo returning HTTPS error**
- *Symptom:* browser error on `devops-starter-webapp-dev31.azurewebsites.net`.
- *Root cause:* original Azure subscription expired; App Service deleted; hostname returned NXDOMAIN.
- *Fix:* rebuilt on a new subscription with Terraform (imported the existing resource group). Free F1 plan rejected deploys with `Site Disabled (403)`, so temporarily ran on B1.
- *Follow-up:* migrated to Container Apps (v3) for zero idle cost and OIDC deploys; App Service removed.
