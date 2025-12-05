# Container Instance Outputs
# Export container FQDNs, IPs, and IDs for downstream usage

output "container_groups" {
  description = "Map of all container groups with their details"
  value = {
    for k, cg in azurerm_container_group.this : k => {
      id         = cg.id
      name       = cg.name
      fqdn       = cg.fqdn
      ip_address = cg.ip_address
      location   = cg.location
    }
  }
}

output "container_fqdns" {
  description = "Map of container group FQDNs for easy access"
  value = {
    for k, cg in azurerm_container_group.this : k => cg.fqdn
  }
}

output "container_ip_addresses" {
  description = "Map of container group IP addresses"
  value = {
    for k, cg in azurerm_container_group.this : k => cg.ip_address
  }
}

output "mqtt_broker_endpoints" {
  description = "Map of MQTT broker connection endpoints (FQDN:port)"
  value = {
    for k, cg in azurerm_container_group.this : k => "${cg.fqdn}:8883"
    if contains(["mqtt-1", "mqtt-2"], k)
  }
}

output "mqtt_broker_1_endpoint" {
  description = "MQTT broker 1 connection endpoint (FQDN:port)"
  value       = try("${azurerm_container_group.this["mqtt-1"].fqdn}:8883", null)
}

output "mqtt_broker_2_endpoint" {
  description = "MQTT broker 2 connection endpoint (FQDN:port)"
  value       = try("${azurerm_container_group.this["mqtt-2"].fqdn}:8883", null)
}

# Managed Identity outputs
output "aci_identity_id" {
  description = "ID of the User-Assigned Managed Identity for ACI"
  value       = azurerm_user_assigned_identity.aci.id
}

output "aci_identity_principal_id" {
  description = "Principal ID of the User-Assigned Managed Identity for ACI"
  value       = azurerm_user_assigned_identity.aci.principal_id
}

output "aci_identity_client_id" {
  description = "Client ID of the User-Assigned Managed Identity for ACI"
  value       = azurerm_user_assigned_identity.aci.client_id
}
