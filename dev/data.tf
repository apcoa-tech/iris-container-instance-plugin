# Current Azure context
data "azurerm_client_config" "current" {}

# Reference existing resource group (not managed by this plugin)
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

# Remote state from iris-blob-storage-plugin
# Provides: storage account names, keys, and file share details
data "terraform_remote_state" "blob_storage" {
  backend = "azurerm"

  config = {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateirisapcoa"
    container_name       = "tfstate"
    key                  = "iris-blob-storage-plugin.dev.tfstate"
    use_oidc             = true
  }
}
