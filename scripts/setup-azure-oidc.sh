#!/usr/bin/env bash
# One-time setup: lets GitHub Actions deploy to ONE resource group in Azure
# using OIDC (short-lived tokens). No client secret is created or stored.
#
#   ./scripts/setup-azure-oidc.sh <github-user>/<repo>
#
# Run it after `az login` with your personal (lab) Azure account.
set -euo pipefail
export AZURE_CORE_ONLY_SHOW_ERRORS=true

GH_REPO="${1:?Usage: ./scripts/setup-azure-oidc.sh <github-user>/<repo>}"
RG="rg-mini-cspm"
LOCATION="centralindia"
APP_NAME="gh-mini-cspm-azure"

SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Subscription: $(az account show --query name -o tsv)"

echo "1/5 Resource group $RG"
az group create --name "$RG" --location "$LOCATION" -o none

echo "2/5 Registering resource providers (first time can take a few minutes)"
for ns in Microsoft.App Microsoft.Storage Microsoft.Network Microsoft.KeyVault; do
  az provider register --namespace "$ns" --wait -o none
done

echo "3/5 App registration $APP_NAME (identity for GitHub, no secret)"
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [[ -z "$APP_ID" ]]; then
  APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
fi
SP_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)
if [[ -z "$SP_ID" ]]; then
  SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
fi

echo "4/5 Contributor on $RG only (not the whole subscription)"
for i in 1 2 3 4 5 6; do   # new identities take a moment to replicate
  if az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal \
       --role Contributor --scope "/subscriptions/$SUB_ID/resourceGroups/$RG" -o none 2>/dev/null; then
    break
  fi
  echo "   waiting for the identity to replicate..."; sleep 10
done

echo "5/5 Trust GitHub: only workflows on the main branch of $GH_REPO"
if ! az ad app federated-credential list --id "$APP_ID" --query "[?name=='github-main']" -o tsv | grep -q .; then
  az ad app federated-credential create --id "$APP_ID" -o none --parameters "{
    \"name\": \"github-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GH_REPO}:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
fi

cat <<OUT

Done. Add these three values in GitHub:
  repo -> Settings -> Secrets and variables -> Actions -> Variables tab -> New repository variable

  AZURE_CLIENT_ID        $APP_ID
  AZURE_TENANT_ID        $TENANT_ID
  AZURE_SUBSCRIPTION_ID  $SUB_ID

They are identifiers, not passwords, so Variables (not Secrets) is fine.
OUT
