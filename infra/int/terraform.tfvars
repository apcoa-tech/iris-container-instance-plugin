# Int Environment Configuration
environment         = "int"
resource_group_name = "iot-int"
location            = "westeurope"
project_name        = "iris"

tags = {
  Environment = "int"
  ManagedBy   = "Terraform"
  CostCenter  = "iot-int"
}
