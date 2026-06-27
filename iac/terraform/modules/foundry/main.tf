resource "azurerm_cognitive_account" "aif" {
  name                  = var.account_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "AIServices"
  sku_name              = "S0"
  custom_subdomain_name = var.account_name

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_cognitive_deployment" "chat" {
  name                 = var.chat_deployment_name
  cognitive_account_id = azurerm_cognitive_account.aif.id

  model {
    format  = "OpenAI"
    name    = var.chat_model_name
    version = var.chat_model_version == "" ? null : var.chat_model_version
  }

  sku {
    name     = "GlobalStandard"
    capacity = var.chat_model_capacity
  }
}
