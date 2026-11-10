variable "subscription_id" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "system_vm_size" {
  type    = string
  default = "Standard_B2ms"
}

variable "system_node_count" {
  type    = number
  default = 2
}

variable "enable_spot_pool" {
  type        = bool
  default     = true
  description = "Set false if your subscription has no Spot vCPU quota"
}

variable "spot_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "tags" {
  type = map(string)
  default = {
    project = "pirates-mlflowops"
    managed = "terraform"
  }
}
