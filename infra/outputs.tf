output "resource_group_name" {
  value = azurerm_resource_group.luis_agentic_demo.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.luis_agentic_demo.name
}

output "get_credentials_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.luis_agentic_demo.name} --name ${azurerm_kubernetes_cluster.luis_agentic_demo.name} --overwrite-existing"
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.luis_agentic_demo.fqdn
}
