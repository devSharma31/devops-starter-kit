
output "webapp_url" {
  description = "Default hostname for the Web App"
  value       = azurerm_linux_web_app.webapp.default_hostname
}

output "containerapp_url" {
  description = "Public URL of the Container App"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}
