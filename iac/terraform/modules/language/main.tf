resource "azurerm_cognitive_account" "lang" {
  name                  = var.account_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "TextAnalytics"
  sku_name              = "F0"
  custom_subdomain_name = var.account_name
  tags                  = var.tags
}
