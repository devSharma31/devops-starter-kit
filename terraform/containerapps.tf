# v3: Azure Container Apps (serverless containers, scale-to-zero)
# Runs the same Docker image as local dev. With min_replicas = 0 the app
# costs nothing while idle and wakes on the first HTTP request.

resource "azurerm_container_app_environment" "cae" {
  name                = var.container_env_name
  location            = var.app_location
  resource_group_name = azurerm_resource_group.rg.name
  # No Log Analytics workspace attached, to keep idle cost at zero.
}

resource "azurerm_container_app" "app" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  secret {
    name  = "azure-openai-key"
    value = var.azure_openai_key
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "web"
      image  = var.container_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "AZURE_OPENAI_KEY"
        secret_name = "azure-openai-key"
      }
      env {
        name  = "AZURE_OPENAI_ENDPOINT"
        value = var.azure_openai_endpoint
      }
      env {
        name  = "AZURE_OPENAI_DEPLOYMENT"
        value = var.azure_openai_deployment
      }
      env {
        name  = "AZURE_OPENAI_API_VERSION"
        value = var.azure_openai_api_version
      }
    }
  }

  # CI/CD rolls out new images; Terraform owns everything else.
  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}

