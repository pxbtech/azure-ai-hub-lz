output "account_id" { value = azurerm_cognitive_account.aif.id }
output "account_name" { value = azurerm_cognitive_account.aif.name }
output "endpoint" { value = azurerm_cognitive_account.aif.endpoint }
output "chat_deployment_name" { value = azurerm_cognitive_deployment.chat.name }
output "principal_id" { value = azurerm_cognitive_account.aif.identity[0].principal_id }
