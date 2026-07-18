variable "name" {
  description = "Name of the virtual machine scale set."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the scale set."
  type        = string
}

variable "location" {
  description = "Azure region in which to create the scale set."
  type        = string
}

variable "sku" {
  description = "SKU size of the instances in the scale set, e.g. Standard_B2s."
  type        = string
  default     = "Standard_B2s"
}

variable "instances" {
  description = "Number of virtual machine instances in the scale set."
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "Administrator username for the scale set instances."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "OpenSSH-formatted public key granted access to the admin account."
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet into which scale set instances are placed."
  type        = string
}

variable "os_disk_caching" {
  description = "Caching mode of the OS disk. One of None, ReadOnly or ReadWrite."
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Storage account type of the OS disk, e.g. Standard_LRS or Premium_LRS."
  type        = string
  default     = "Premium_LRS"
}

variable "source_image_reference" {
  description = "Marketplace image reference used to provision the instances."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "upgrade_mode" {
  description = "How instances are upgraded when the scale set model changes. One of Manual, Automatic or Rolling."
  type        = string
  default     = "Manual"
}

variable "tags" {
  description = "Map of tags applied to the scale set."
  type        = map(string)
  default     = {}
}
