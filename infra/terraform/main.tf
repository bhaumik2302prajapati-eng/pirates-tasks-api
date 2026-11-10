resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

locals {
  suffix = random_string.suffix.result
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-pirates-mlops"
  location = var.location
  tags     = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = "piratesmlopsacr${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_storage_account" "mlflow" {
  name                            = "piratesmlflow${local.suffix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "artifacts" {
  name                  = "pirates-mlflow-artifacts"
  storage_account_name  = azurerm_storage_account.mlflow.name
  container_access_type = "private"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-pirates-mlops"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "pirates-mlops"
  sku_tier            = "Free"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "system"
    temporary_name_for_rotation = "tmpsystem"
    vm_size                     = var.system_vm_size
    node_count                  = var.system_node_count
    os_disk_size_gb             = 64
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count                 = var.enable_spot_pool ? 1 : 0
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.spot_vm_size
  priority              = "Spot"
  eviction_policy       = "Delete"
  spot_max_price        = -1

  auto_scaling_enabled = true
  min_count            = 0
  max_count            = 1

  node_labels = {
    "pirates/workload" = "training"
  }
  node_taints = ["pirates/training=true:NoSchedule"]

  tags = var.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
