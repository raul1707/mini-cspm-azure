#!/usr/bin/env bash
# Deletes everything the lab created in Azure.
set -euo pipefail
KV=$(az keyvault list --resource-group rg-mini-cspm --query "[0].name" -o tsv 2>/dev/null || true)
echo "Deleting resource group rg-mini-cspm (storage, NSG, Key Vault, container app). Takes a few minutes..."
az group delete --name rg-mini-cspm --yes
if [[ -n "$KV" ]]; then
  # Key Vault is soft-deleted for 7 days; purge it so the lab leaves nothing behind
  echo "Purging soft-deleted Key Vault $KV..."
  az keyvault purge --name "$KV" || echo "Purge failed; it will be removed automatically after 7 days."
fi
APP_ID=$(az ad app list --display-name gh-mini-cspm-azure --query "[0].appId" -o tsv)
if [[ -n "$APP_ID" ]]; then
  echo "Deleting app registration gh-mini-cspm-azure..."
  az ad app delete --id "$APP_ID"
fi
echo "Done. Also delete the 'vulnapp' package on GitHub: your profile -> Packages -> vulnapp -> Package settings -> Delete."
