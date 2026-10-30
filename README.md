# mini CSPM - Azure lab

Deliberately insecure lab: GitHub Actions builds an old, CVE-heavy container image,
scans it and an insecure ARM template with Trivy, then deploys both to Azure anyway.

**Lab only. Use a personal Azure subscription. Run `scripts/cleanup.sh` when done.**

| Path | What it is |
|---|---|
| `app/` | Harmless Flask page on an old base image (python:3.9-slim) with old packages |
| `infra/azuredeploy.json` | ARM template: open SSH NSG rule, storage allowing HTTP and public blobs, public Key Vault, Container App with an over-privileged identity |
| `data/fake-customers.csv` | Invented records, uploaded to the public blob container by the pipeline |
| `.github/workflows/build-scan-deploy.yml` | Build -> Trivy image + config scan (report only) -> push to GHCR -> deploy |
| `scripts/setup-azure-oidc.sh` | One-time GitHub -> Azure trust (OIDC, no secrets), Contributor on one resource group |
| `scripts/cleanup.sh` | Deletes the resource group and the app registration |

What Trivy reports on the template and Dockerfile (tested with Trivy 0.76.1):
4 Critical, 3 High, 4 Medium, 4 Low.

Known gaps, on purpose (what IaC scanning alone misses):
- the public blob container (`publicAccess: Blob`)
- the container app's identity having full secret permissions on the Key Vault
- a secret value written in plain text into the template

Real attack paths this lab creates:
1. Internet -> public blob container -> fake customer data
2. Internet -> vulnerable container -> its managed identity -> Key Vault secrets
