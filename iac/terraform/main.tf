resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

module "observability" {
  source              = "./modules/observability"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  law_name            = local.law_name
  appi_name           = local.appi_name
  tags                = var.tags
}

module "network" {
  source              = "./modules/network"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  vnet_name           = local.vnet_name
  workload            = var.workload
  env_code            = var.env_code
  tags                = var.tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  kv_name             = local.kv_name
  tags                = var.tags
}

module "storage" {
  source              = "./modules/storage"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  storage_name        = local.storage_name
  tags                = var.tags
}

module "content_safety" {
  source              = "./modules/content-safety"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = local.content_safety_name
  tags                = var.tags
}

module "language" {
  source              = "./modules/language"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = local.language_name
  tags                = var.tags
}

module "foundry" {
  source               = "./modules/foundry"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  account_name         = local.foundry_name
  chat_deployment_name = "chat"
  chat_model_name      = var.chat_model_name
  chat_model_version   = var.chat_model_version
  chat_model_capacity  = var.chat_model_capacity
  tags                 = var.tags
}

module "apim" {
  source              = "./modules/apim"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  apim_name           = local.apim_name
  publisher_email     = var.apim_publisher_email
  publisher_name      = var.apim_publisher_name
  tags                = var.tags
}

module "action_group" {
  source              = "./modules/action-group"
  resource_group_name = azurerm_resource_group.rg.name
  action_group_name   = local.action_group_name
  alert_email         = var.alert_email
  tags                = var.tags
}

module "budget" {
  source            = "./modules/budget"
  budget_name       = local.budget_name
  amount            = var.budget_amount
  start_date        = var.budget_start_date
  alert_email       = var.alert_email
  action_group_id   = module.action_group.action_group_id
  subscription_id   = data.azurerm_subscription.current.id
}

data "azurerm_subscription" "current" {}
