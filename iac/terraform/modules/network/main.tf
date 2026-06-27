resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.50.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "apim" {
  name                 = "${var.env_code}-${var.workload}-snet-apim-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.50.1.0/27"]
}

resource "azurerm_subnet" "pe" {
  name                 = "${var.env_code}-${var.workload}-snet-pe-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.50.2.0/27"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "runbook" {
  name                 = "${var.env_code}-${var.workload}-snet-runbook-01"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.50.3.0/27"]
}
