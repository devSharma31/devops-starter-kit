resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "devops-starter"
    owner   = "devashish-sharma"
    env     = "demo"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  location            = var.app_location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "webapp" {
  name                = var.webapp_name
  location            = var.app_location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
    health_check_path = "/health"
    always_on         = false
    app_command_line  = "gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app"
  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    SCM_DO_BUILD_DURING_DEPLOYMENT      = "true"
    AZURE_OPENAI_KEY                    = var.azure_openai_key
    AZURE_OPENAI_ENDPOINT               = var.azure_openai_endpoint
    AZURE_OPENAI_DEPLOYMENT             = var.azure_openai_deployment
    AZURE_OPENAI_API_VERSION            = var.azure_openai_api_version
  }

  identity {
    type = "SystemAssigned"
  }
}