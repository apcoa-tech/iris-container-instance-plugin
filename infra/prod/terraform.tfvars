# Prod Environment Configuration
environment         = "prod"
resource_group_name = "iot-prod"
location            = "westeurope"
project_name        = "iris"

tags = {
  Environment = "prod"
  ManagedBy   = "Terraform"
  CostCenter  = "Production"
  Criticality = "High"
}
