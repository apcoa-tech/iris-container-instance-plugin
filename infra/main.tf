# Container Instance Resources
# This file defines HOW to create container instances (iterates over locals.tf)

# User-Assigned Managed Identity for ACR authentication
# Required because ACI with System-Assigned identity has limitations for ACR image pulls
resource "azurerm_user_assigned_identity" "aci" {
  name                = "${var.project_name}-aci-identity-${var.environment}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = local.common_tags
}

# Grant AcrPull role to the User-Assigned Managed Identity
resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aci.principal_id
}

resource "azurerm_container_group" "this" {
  for_each = local.container_instances

  name                = each.value.name
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.this.name
  os_type             = each.value.os_type
  restart_policy      = each.value.restart_policy
  ip_address_type     = each.value.ip_address_type
  dns_name_label      = each.value.dns_name_label

  # Use User-Assigned Managed Identity for ACR authentication (security best practice)
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aci.id]
  }

  # ACR authentication using User-Assigned Managed Identity
  image_registry_credential {
    server                    = data.azurerm_container_registry.acr.login_server
    user_assigned_identity_id = azurerm_user_assigned_identity.aci.id
  }

  # Dynamic container blocks
  dynamic "container" {
    for_each = each.value.containers

    content {
      name   = container.value.name
      image  = container.value.image
      cpu    = container.value.cpu
      memory = container.value.memory

      # Dynamic ports
      dynamic "ports" {
        for_each = container.value.ports

        content {
          port     = ports.value.port
          protocol = ports.value.protocol
        }
      }

      # Dynamic volumes with Azure File Share configuration
      dynamic "volume" {
        for_each = container.value.volume_mounts

        content {
          name       = volume.value.name
          mount_path = volume.value.mount_path
          read_only  = volume.value.read_only

          # Azure File Share configuration
          share_name           = each.value.volumes[volume.key].share_name
          storage_account_name = local.storage_account_name
          storage_account_key  = local.storage_account_key
        }
      }
    }
  }

  tags = local.common_tags

  # Ensure role assignment is created before container group tries to pull images
  depends_on = [azurerm_role_assignment.aci_acr_pull]
}
