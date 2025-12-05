# Standard APCOA variables across all plugins

variable "resource_group_name" {
  description = "Name of the existing Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Environment name (dev, uat, prd)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "iris"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
