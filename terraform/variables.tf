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
  default     = "rg-devops-starter-kit"
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

variable "container_env_name" {
  description = "Container Apps environment name"
  type        = string
  default     = "cae-devops-starter-kit"
}

variable "container_app_name" {
  description = "Container App name (lowercase, max 32 chars)"
  type        = string
  default     = "devops-starter-app-dev31"
}

variable "container_image" {
  description = "Initial container image (CI/CD updates it afterwards)"
  type        = string
  default     = "ghcr.io/devsharma31/devops-starter-kit:latest"
}
