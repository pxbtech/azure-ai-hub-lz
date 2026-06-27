output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = var.location
}

output "log_analytics_name" {
  value = module.observability.log_analytics_name
}

output "log_analytics_id" {
  value = module.observability.log_analytics_id
}

output "application_insights_name" {
  value = module.observability.application_insights_name
}

output "application_insights_id" {
  value = module.observability.application_insights_id
}

output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "content_safety_name" {
  value = module.content_safety.account_name
}

output "content_safety_endpoint" {
  value = module.content_safety.endpoint
}

output "language_name" {
  value = module.language.account_name
}

output "language_endpoint" {
  value = module.language.endpoint
}

output "foundry_name" {
  value = module.foundry.account_name
}

output "foundry_endpoint" {
  value = module.foundry.endpoint
}

output "chat_deployment_name" {
  value = module.foundry.chat_deployment_name
}

output "apim_name" {
  value = module.apim.apim_name
}

output "apim_gateway_url" {
  value = module.apim.gateway_url
}

output "apim_principal_id" {
  value = module.apim.principal_id
}

output "action_group_id" {
  value = module.action_group.action_group_id
}

output "budget_name" {
  value = module.budget.budget_name
}
