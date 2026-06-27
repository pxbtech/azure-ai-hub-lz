resource "azurerm_cognitive_account" "cs" {
  name                  = var.account_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "ContentSafety"
  sku_name              = "F0"
  custom_subdomain_name = var.account_name
  tags                  = var.tags
}
