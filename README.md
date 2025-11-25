# IRIS Container Instance Plugin

Azure Container Instances infrastructure for the IRIS project using Terraform.

## Overview

This repository manages Azure Container Instances for the IRIS project using declarative Terraform configuration. It follows APCOA's plugin architecture pattern for consistent, maintainable infrastructure.

The primary use case is running a dual Eclipse Mosquitto MQTT broker setup with persistent storage backed by Azure File Shares. The architecture provides redundancy through two MQTT brokers that bridge to each other and to the production broker.

## Features

- Azure Container Instances using `azurerm_container_group` resource
- Declarative container configuration in `locals.tf`
- Azure File Share volume mounts for persistent storage
- Remote state integration with iris-blob-storage-plugin
- Public IP and DNS name assignment
- GitHub Actions CI/CD workflow
- Multi-environment support (dev/uat/prd)

## Repository Structure

```
iris-container-instance-plugin/
├── dev/                    # Development environment
│   ├── backend.tf          # Remote state configuration
│   ├── data.tf             # Data sources (resource group, remote state)
│   ├── locals.tf           # Container instance configuration
│   ├── main.tf             # Container group resources
│   ├── outputs.tf          # Output values (FQDN, IPs)
│   ├── provider_set.tf     # Azure provider configuration
│   ├── terraform.tfvars    # Environment-specific values
│   ├── variables.tf        # Input variables
│   └── versions.tf         # Terraform version constraints
├── uat/                    # UAT environment (to be added)
│   └── (same structure as dev/)
├── prd/                    # Production environment (to be added)
│   └── (same structure as dev/)
├── .github/
│   └── workflows/
│       └── terraform-dev.yml   # CI/CD workflow
└── README.md
```

### Project Structure

This repository follows a **multi-environment folder structure** where each environment (dev, uat, prd) has its own:

- **Separate folder** with complete Terraform configuration
- **Independent remote state** stored in Azure Storage
- **Isolated resources** to prevent cross-environment impact
- **Environment-specific configuration** in `terraform.tfvars`

**State File Naming Convention:**
- Dev: `iris-container-instance-plugin.dev.tfstate`
- UAT: `iris-container-instance-plugin.uat.tfstate`
- Prd: `iris-container-instance-plugin.prd.tfstate`

All state files are stored in the same backend (`tfstateirisapcoa` storage account) but with different keys to ensure complete isolation between environments.

## Prerequisites

- **Terraform**: >= 1.13
- **Azure CLI**: Authenticated (`az login`)
- **Permissions**: Contributor access to `iot-dev` resource group
- **Backend Access**: Access to `tfstateirisapcoa` storage account for remote state
- **Dependencies**:
  - `iris-blob-storage-plugin` must be deployed first (provides storage account and file shares)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/apcoa-tech/iris-container-instance-plugin.git
cd iris-container-instance-plugin/dev
```

### 2. Initialize Terraform

```bash
terraform init
```

This will:
- Configure the Azure backend for remote state
- Download required providers

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply Changes

```bash
terraform apply
```

### 5. Get Container FQDNs

```bash
terraform output mqtt_broker_endpoints
```

Example output:
```
{
  "mqtt-1" = "iris-dev-mqtt-1.westeurope.azurecontainer.io:8883"
  "mqtt-2" = "iris-dev-mqtt-2.westeurope.azurecontainer.io:8883"
}
```

## Architecture

### Dual-Broker MQTT Setup

The infrastructure deploys two MQTT brokers configured for high availability and redundancy:

```
┌─────────────────┐         ┌─────────────────┐
│ MQTT Broker 1   │ ←─────→ │ MQTT Broker 2   │
│ (mqtt-1)        │  Bridge │ (mqtt-2)        │
└─────────────────┘         └─────────────────┘
        │                           │
        └───────────┬───────────────┘
                    │ Both bridge to:
                    ▼
        ┌─────────────────────┐
        │ Production Broker   │
        │ 3.121.198.76:8883   │
        └─────────────────────┘
```

**Key characteristics:**
- Two independent MQTT brokers (mqtt-1 and mqtt-2)
- Each broker bridges to the production broker at 3.121.198.76:8883
- Brokers also bridge to each other for mesh redundancy
- Separate config and data file shares for each broker
- Shared certificates (certs, bridge_certs) for both brokers

**FQDNs:**
- Broker 1: `iris-dev-mqtt-1.westeurope.azurecontainer.io:8883`
- Broker 2: `iris-dev-mqtt-2.westeurope.azurecontainer.io:8883`

## Configuration

### Container Instance Configuration

Container instances are defined declaratively in `dev/locals.tf`. Each broker gets its own configuration:

```hcl
container_instances = {
  mqtt-1 = {
    name     = "${local.name_prefix}-mqtt-1"
    location = var.location

    os_type        = "Linux"
    restart_policy = "Always"
    ip_address_type = "Public"
    dns_name_label  = "${local.name_prefix}-mqtt-1"

    containers = {
      mosquitto = {
        name   = "mosquitto"
        image  = "eclipse-mosquitto:2.0.18"
        cpu    = 1.0
        memory = 1.5

        ports = {
          mqtts = {
            port     = 8883
            protocol = "TCP"
          }
        }

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
          # ... additional mounts
        }
      }
    }

    volumes = {
      config = {
        name       = "config"
        share_name = local.file_shares.config_1  # Separate for mqtt-1
      }
      data = {
        name       = "data"
        share_name = local.file_shares.data_1    # Separate for mqtt-1
      }
      certs = {
        name       = "certs"
        share_name = local.file_shares.certs     # Shared
      }
      # ... additional volumes
    }
  }

  mqtt-2 = {
    name     = "${local.name_prefix}-mqtt-2"
    location = var.location
    # ... similar configuration with config_2, data_2, etc.
  }
}
```

### Volume Mounts

The MQTT container mounts 5 Azure File Shares:

| Mount Path | Purpose | Read-Only |
|------------|---------|-----------|
| `/mosquitto/config` | Mosquitto configuration files | No |
| `/mosquitto/data` | Persistent message storage | No |
| `/mosquitto/log` | Log files | No |
| `/mosquitto/certs` | Server certificates | Yes |
| `/mosquitto/bridge_certs` | Bridge CA certificates | Yes |

### Variables

Key variables in `terraform.tfvars`:

| Variable | Default | Description |
|----------|---------|-------------|
| `resource_group_name` | `iot-dev` | Target resource group |
| `location` | `westeurope` | Azure region |
| `environment` | `dev` | Environment name |
| `project_name` | `iris` | Project name for resource naming |
| `subscription_id` | (set) | Azure subscription ID |

## Adding a New Container

To add a new container instance, edit `dev/locals.tf`:

```hcl
container_instances = {
  mqtt = {
    # Existing MQTT container...
  }

  # Add your new container here
  my_app = {
    name     = "${local.name_prefix}-my-app"
    location = var.location

    os_type        = "Linux"
    restart_policy = "OnFailure"
    ip_address_type = "Public"
    dns_name_label  = "${local.name_prefix}-my-app"

    containers = {
      app = {
        name   = "my-app"
        image  = "myregistry.azurecr.io/my-app:latest"
        cpu    = 0.5
        memory = 1.0

        ports = {
          http = {
            port     = 80
            protocol = "TCP"
          }
        }

        volume_mounts = {}
      }
    }

    volumes = {}
  }
}
```

Then run:
```bash
terraform plan
terraform apply
```

## CI/CD Workflow

GitHub Actions workflow (`.github/workflows/terraform-dev.yml`) runs on:
- Pull requests to `main` (validates and plans)
- Pushes to `main` (validates, plans, and applies)
- Manual trigger (`workflow_dispatch`)

### Required GitHub Secrets

Set these secrets using the GitHub OIDC setup:

- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

### Workflow Steps

1. **Format Check**: Validates Terraform formatting
2. **Init**: Initializes backend with OIDC
3. **Validate**: Validates configuration
4. **Plan**: Creates execution plan
5. **Apply**: Applies changes (only on push to main)
6. **Output**: Displays container endpoints

## Outputs

After applying, the following outputs are available:

```bash
terraform output
```

| Output | Description |
|--------|-------------|
| `container_groups` | Map of all container groups with details |
| `container_fqdns` | Map of container FQDNs |
| `container_ip_addresses` | Map of container public IP addresses |
| `mqtt_broker_endpoint` | MQTT broker FQDN:port (e.g., `host:8883`) |

## Resource Naming Convention

Resources follow APCOA naming standards:

- **Container Group**: `{project}-{env}-{name}` (e.g., `iris-dev-mqtt`)
- **DNS Label**: `{project}-{env}-{name}` (e.g., `iris-dev-mqtt`)
- **FQDN**: `{dns-label}.{region}.azurecontainer.io`

## Infrastructure Details

### Current Resources

**Environment**: Development (dev)

**Container Group**: `iris-dev-mqtt`
- Container: Eclipse Mosquitto 2.0.18
- CPU: 1.0 cores
- Memory: 1.5 GB
- Port: 8883 (MQTTS)
- Restart Policy: Always
- Location: West Europe
- FQDN: `iris-dev-mqtt.westeurope.azurecontainer.io`

**Volumes**: 5 Azure File Share mounts
- config, data, log, certs, bridge_certs

## Multi-Environment Setup

To set up UAT or Production:

1. Copy `dev/` folder to `uat/` or `prd/`
2. Update `terraform.tfvars`:
   ```hcl
   resource_group_name = "iot-uat"  # or "iot-prd"
   environment         = "uat"      # or "prd"
   ```
3. Update `backend.tf` key:
   ```hcl
   key = "iris-container-instance-plugin.uat.tfstate"  # or .prd.tfstate
   ```
4. Update `data.tf` remote state key for blob storage:
   ```hcl
   key = "iris-blob-storage-plugin.uat.tfstate"  # or .prd.tfstate
   ```
5. Create corresponding GitHub workflow file

## Troubleshooting

### Common Issues

**Issue**: `Error: resource group not found`
**Solution**: The resource group must exist before running Terraform. Create it manually or ensure it's managed elsewhere.

**Issue**: `Error: storage account not found in remote state`
**Solution**: Deploy `iris-blob-storage-plugin` first. The container instances require file shares from that plugin.

**Issue**: `Container restart loop`
**Solution**:
1. Check container logs: `az container logs -g iot-dev -n iris-dev-mqtt --container-name mosquitto`
2. Verify file share contents (config files must exist)
3. Check volume mount paths match container expectations

**Issue**: `Error: backend authentication failed`
**Solution**: Run `az login` to authenticate with Azure CLI.

## MQTT Broker Deployment

### Prerequisites for MQTT Container

Before deploying the MQTT container, ensure file shares contain:

1. **config/** - `mosquitto.conf` configuration file
2. **certs/** - Server certificates (server.crt, server.key)
3. **bridge_certs/** - Bridge CA certificate (production_ca.crt)

### Connecting to MQTT Broker

After deployment, connect to the broker using:

```bash
# Get the FQDN
terraform output mqtt_broker_endpoint

# Test connection (requires mosquitto-clients)
mosquitto_pub -h iris-dev-mqtt.westeurope.azurecontainer.io -p 8883 \
  --cafile ca.crt --cert client.crt --key client.key \
  -t "test/topic" -m "Hello MQTT"
```

### Monitoring Container

View container logs:
```bash
az container logs -g iot-dev -n iris-dev-mqtt --container-name mosquitto --follow
```

Check container status:
```bash
az container show -g iot-dev -n iris-dev-mqtt --query instanceView.state
```

## Cost Estimation

Approximate monthly costs for dev environment:

| Resource | Specification | Monthly Cost (EUR) |
|----------|---------------|-------------------|
| Container Instance | 1 vCPU, 1.5 GB, Always On | €37-44 |
| Public IP | Static public IP | €3-4 |
| **Total** | | **€40-48** |

Note: Costs assume 24/7 uptime. Use UAT/Dev environments sparingly to reduce costs.

## Architecture Pattern

This repository follows the APCOA Terraform plugin architecture:

1. **Declarative Configuration**: Define WHAT to create in `locals.tf`
2. **Iteration-Based Execution**: Uses `for_each` in `main.tf`
3. **Data Sources**: Reference shared resources (resource group, remote state)
4. **Remote State**: Share outputs between plugins
5. **Native Azure Resources**: Uses `azurerm_container_group` directly (no AVM available)

## Dependencies

This plugin depends on:
- **iris-blob-storage-plugin**: Provides storage account and file shares for persistent volumes

## Security Considerations

- File shares are accessed using storage account keys from remote state
- Certificates should be stored in file shares (consider Azure Key Vault for production)
- Container runs with default security context
- Public IP is assigned (consider VNet integration for production)
- HTTPS-only traffic to storage accounts enforced
