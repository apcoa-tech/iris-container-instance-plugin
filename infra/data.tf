# Current Azure context
data "azurerm_client_config" "current" {}

# Reference existing resource group (not managed by this plugin)
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Get ACR credentials dynamically (environment-aware)
data "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = var.resource_group_name
}

# Remote state from iris-blob-storage-plugin
# Provides: storage account names, keys, and file share details
data "terraform_remote_state" "blob_storage" {
  backend = "azurerm"

  config = {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateirisapcoa"
    container_name       = "tfstate"
    key                  = "blob-storage-plugin.${var.environment}.tfstate"
    use_oidc             = true
  }
}
