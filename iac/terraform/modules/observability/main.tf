resource "azurerm_log_analytics_workspace" "law" {
  name                       = var.law_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  sku                        = "PerGB2018"
  retention_in_days          = 30
  daily_quota_gb             = 1
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  tags                       = var.tags
}

resource "azurerm_application_insights" "appi" {
  name                = var.appi_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
  tags                = var.tags
}
