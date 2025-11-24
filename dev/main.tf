# Container Instance Resources
# This file defines HOW to create container instances (iterates over locals.tf)

resource "azurerm_container_group" "this" {
  for_each = local.container_instances

  name                = each.value.name
  location            = each.value.location
  resource_group_name = data.azurerm_resource_group.this.name
  os_type             = each.value.os_type
  restart_policy      = each.value.restart_policy
  ip_address_type     = each.value.ip_address_type
  dns_name_label      = each.value.dns_name_label

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

      # Dynamic volume mounts
      dynamic "volume" {
        for_each = container.value.volume_mounts

        content {
          name       = volume.value.name
          mount_path = volume.value.mount_path
          read_only  = volume.value.read_only
        }
      }
    }
  }

  # Dynamic Azure File Share volumes
  dynamic "volume" {
    for_each = each.value.volumes

    content {
      name       = volume.value.name
      share_name = volume.value.share_name

      storage_account_name = local.storage_account_name
      storage_account_key  = local.storage_account_key
    }
  }

  tags = local.common_tags
}
