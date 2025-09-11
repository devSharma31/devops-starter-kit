
output "webapp_url" {
  description = "Default hostname for the Web App"
  value       = azurerm_linux_web_app.webapp.default_hostname
}
