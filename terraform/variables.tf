
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-devops-starter"
}

variable "app_service_plan_name" {
  description = "App Service Plan name"
  type        = string
  default     = "asp-devops-starter"
}

variable "webapp_name" {
  description = "Web App name (must be globally unique)"
  type        = string
  default     = "devops-starter-webapp-demo"
}

variable "sku_name" {
  description = "App Service SKU (e.g., B1, P1v3)"
  type        = string
  default     = "B1"
}
