output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "vnet_name" { value = azurerm_virtual_network.vnet.name }
output "apim_subnet_id" { value = azurerm_subnet.apim.id }
output "pe_subnet_id" { value = azurerm_subnet.pe.id }
output "runbook_subnet_id" { value = azurerm_subnet.runbook.id }
