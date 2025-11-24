# Declarative container instance configuration
# This file defines WHAT container instances to create

locals {
  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Storage account details from remote state
  storage_account_name = try(
    data.terraform_remote_state.blob_storage.outputs.storage_accounts["mqtt"].name,
    null
  )

  storage_account_key = try(
    data.terraform_remote_state.blob_storage.outputs.storage_accounts["mqtt"].primary_access_key,
    null
  )

  # File share names (these should exist in iris-blob-storage-plugin)
  file_shares = {
    config_1     = "${local.name_prefix}-mqtt-1-config"
    config_2     = "${local.name_prefix}-mqtt-2-config"
    data_1       = "${local.name_prefix}-mqtt-1-data"
    data_2       = "${local.name_prefix}-mqtt-2-data"
    log_1        = "${local.name_prefix}-mqtt-1-log"
    log_2        = "${local.name_prefix}-mqtt-2-log"
    certs        = "${local.name_prefix}-mqtt-certs"        # Shared
    bridge_certs = "${local.name_prefix}-mqtt-bridge-certs" # Shared
  }

  # Container instances to create
  container_instances = {
    mqtt-1 = {
      name     = "${local.name_prefix}-mqtt-1"
      location = var.location

      # Container configuration
      os_type = "Linux"

      # Restart policy - always restart on failure
      restart_policy = "Always"

      # Network configuration
      ip_address_type = "Public"
      dns_name_label  = "${local.name_prefix}-mqtt-1"

      # Container definition
      containers = {
        mosquitto = {
          name   = "mosquitto"
          image  = "eclipse-mosquitto:2.0.18"
          cpu    = 1.0
          memory = 1.5

          # MQTTS port
          ports = {
            mqtts = {
              port     = 8883
              protocol = "TCP"
            }
          }

          # Volume mounts
          volume_mounts = {
            config = {
              name       = "config"
              mount_path = "/mosquitto/config"
              read_only  = false
            }
            data = {
              name       = "data"
              mount_path = "/mosquitto/data"
              read_only  = false
            }
            log = {
              name       = "log"
              mount_path = "/mosquitto/log"
              read_only  = false
            }
            certs = {
              name       = "certs"
              mount_path = "/mosquitto/certs"
              read_only  = true
            }
            bridge_certs = {
              name       = "bridge-certs"
              mount_path = "/mosquitto/bridge_certs"
              read_only  = true
            }
          }
        }
      }

      # Azure File Share volumes
      volumes = {
        config = {
          name       = "config"
          share_name = local.file_shares.config_1
        }
        data = {
          name       = "data"
          share_name = local.file_shares.data_1
        }
        log = {
          name       = "log"
          share_name = local.file_shares.log_1
        }
        certs = {
          name       = "certs"
          share_name = local.file_shares.certs
        }
        bridge_certs = {
          name       = "bridge-certs"
          share_name = local.file_shares.bridge_certs
        }
      }
    }

    mqtt-2 = {
      name     = "${local.name_prefix}-mqtt-2"
      location = var.location

      # Container configuration
      os_type = "Linux"

      # Restart policy - always restart on failure
      restart_policy = "Always"

      # Network configuration
      ip_address_type = "Public"
      dns_name_label  = "${local.name_prefix}-mqtt-2"

      # Container definition
      containers = {
        mosquitto = {
          name   = "mosquitto"
          image  = "eclipse-mosquitto:2.0.18"
          cpu    = 1.0
          memory = 1.5

          # MQTTS port
          ports = {
            mqtts = {
              port     = 8883
              protocol = "TCP"
            }
          }

          # Volume mounts
          volume_mounts = {
            config = {
              name       = "config"
              mount_path = "/mosquitto/config"
              read_only  = false
            }
            data = {
              name       = "data"
              mount_path = "/mosquitto/data"
              read_only  = false
            }
            log = {
              name       = "log"
              mount_path = "/mosquitto/log"
              read_only  = false
            }
            certs = {
              name       = "certs"
              mount_path = "/mosquitto/certs"
              read_only  = true
            }
            bridge_certs = {
              name       = "bridge-certs"
              mount_path = "/mosquitto/bridge_certs"
              read_only  = true
            }
          }
        }
      }

      # Azure File Share volumes
      volumes = {
        config = {
          name       = "config"
          share_name = local.file_shares.config_2
        }
        data = {
          name       = "data"
          share_name = local.file_shares.data_2
        }
        log = {
          name       = "log"
          share_name = local.file_shares.log_2
        }
        certs = {
          name       = "certs"
          share_name = local.file_shares.certs
        }
        bridge_certs = {
          name       = "bridge-certs"
          share_name = local.file_shares.bridge_certs
        }
      }
    }
  }

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Plugin      = "iris-container-instance-plugin"
    }
  )
}
