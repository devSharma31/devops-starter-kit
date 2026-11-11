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
