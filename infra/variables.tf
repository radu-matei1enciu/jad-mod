variable "resource_group_name" {
  description = "Azure resource group name."
  type        = string
  default     = "luis-agentic-demo-rg"
}

variable "aks_name" {
  description = "AKS cluster name."
  type        = string
  default     = "luis-agentic-demo-aks"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "westeurope"
}

variable "node_count" {
  description = "Number of AKS nodes."
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes."
  type        = string
  default     = "Standard_B4ms"
}
