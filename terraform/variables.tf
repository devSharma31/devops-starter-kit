variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for Resource Group"
  type        = string
  default     = "East US"
}

variable "app_location" {
  description = "Azure region for App Service resources"
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "devops-starter-rg"
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
  description = "App Service SKU"
  type        = string
  default     = "B1"
}

variable "azure_openai_key" {
  description = "Azure OpenAI API key"
  type        = string
  sensitive   = true
}

variable "azure_openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  type        = string
}

variable "azure_openai_deployment" {
  description = "Azure OpenAI deployment name"
  type        = string
  default     = "gpt-4o"
}

variable "azure_openai_api_version" {
  description = "Azure OpenAI API version"
  type        = string
  default     = "2025-01-01-preview"
}