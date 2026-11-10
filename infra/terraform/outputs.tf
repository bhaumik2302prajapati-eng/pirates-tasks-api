output "resource_group" { value = azurerm_resource_group.rg.name }
output "aks_name" { value = azurerm_kubernetes_cluster.aks.name }
output "acr_name" { value = azurerm_container_registry.acr.name }
output "acr_login_server" { value = azurerm_container_registry.acr.login_server }
output "storage_account" { value = azurerm_storage_account.mlflow.name }
output "artifact_container" { value = azurerm_storage_container.artifacts.name }
