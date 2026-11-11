output "containerapp_url" {
  description = "Public URL of the Container App"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}
