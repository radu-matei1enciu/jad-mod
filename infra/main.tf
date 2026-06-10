terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "luis_agentic_demo" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "luis_agentic_demo" {
  name                = var.aks_name
  location            = azurerm_resource_group.luis_agentic_demo.location
  resource_group_name = azurerm_resource_group.luis_agentic_demo.name
  dns_prefix          = var.aks_name

  sku_tier = "Free"

  default_node_pool {
    name       = "nodepool1"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}
