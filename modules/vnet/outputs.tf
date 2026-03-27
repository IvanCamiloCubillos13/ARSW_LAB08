output "vnet_name"      { value = azurerm_virtual_network.vnet.name }
output "vnet_id"        { value = azurerm_virtual_network.vnet.id }
output "subnet_web_id"  { value = azurerm_subnet.web.id }
output "subnet_mgmt_id" { value = azurerm_subnet.mgmt.id }
output "nsg_web_id"     { value = azurerm_network_security_group.web.id } 