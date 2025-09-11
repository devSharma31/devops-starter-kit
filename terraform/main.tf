
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    project = "devops-starter"
    owner   = "your-name"
    env     = "demo"
  }
}

resource "azurerm_service_plan" "plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "webapp" {
  name                = var.webapp_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id


  site_config {
    application_stack {
      python_version = "3.11"
    }
    health_check_path = "/health"
    always_on         = false # <-- add this line for F1/D1/Free
    app_command_line  = "gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app"

  }

  app_settings = {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    SCM_DO_BUILD_DURING_DEPLOYMENT      = "true"
  }

  identity {
    type = "SystemAssigned"
  }
}

