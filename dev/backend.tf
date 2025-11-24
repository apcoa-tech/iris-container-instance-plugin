terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateirisapcoa"
    container_name       = "tfstate"
    key                  = "iris-container-instance-plugin.dev.tfstate"
    use_oidc             = true
  }
}
