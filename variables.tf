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

  validation {
    condition     = var.instances >= 0 && floor(var.instances) == var.instances
    error_message = "The instances value must be a non-negative whole number."
  }
}

variable "admin_username" {
  description = "Administrator username for the scale set instances."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "OpenSSH-formatted public key granted access to the admin account. Password authentication is disabled unconditionally, so this key is the only way in."
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp(256|384|521)) ", var.admin_ssh_public_key))
    error_message = "The admin_ssh_public_key value must be an OpenSSH-formatted public key, e.g. \"ssh-rsa AAAA... user@host\". A private key or a PEM-encoded key will be rejected by Azure."
  }
}

variable "subnet_id" {
  description = "ID of the subnet into which scale set instances are placed."
  type        = string
}

variable "os_disk_caching" {
  description = "Caching mode of the OS disk. One of None, ReadOnly or ReadWrite."
  type        = string
  default     = "ReadWrite"

  validation {
    condition     = contains(["None", "ReadOnly", "ReadWrite"], var.os_disk_caching)
    error_message = "The os_disk_caching value must be one of None, ReadOnly or ReadWrite."
  }
}

variable "os_disk_storage_account_type" {
  description = "Storage account type of the OS disk, e.g. Standard_LRS or Premium_LRS."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition = contains(
      ["Standard_LRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS"],
      var.os_disk_storage_account_type
    )
    error_message = "The os_disk_storage_account_type value must be one of Standard_LRS, StandardSSD_LRS, StandardSSD_ZRS, Premium_LRS or Premium_ZRS."
  }
}

variable "os_disk_disk_encryption_set_id" {
  description = "ID of a disk encryption set used to encrypt the OS disk with a customer-managed key. When null the OS disk keeps Azure's default platform-managed key, which is still encryption at rest."
  type        = string
  default     = null
}

variable "encryption_at_host_enabled" {
  description = "Whether to encrypt the temp disk, the OS and data disk caches, and the flow of unencrypted data to the storage service on the host itself. Requires the EncryptionAtHost feature to be registered on the subscription and a VM size that supports it, so it defaults to off."
  type        = bool
  default     = false
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
  description = "How instances are upgraded when the scale set model changes. One of Manual, Automatic or Rolling. Automatic and Rolling both require health_probe_id to be set."
  type        = string
  default     = "Manual"

  validation {
    condition     = contains(["Manual", "Automatic", "Rolling"], var.upgrade_mode)
    error_message = "The upgrade_mode value must be one of Manual, Automatic or Rolling."
  }
}

variable "health_probe_id" {
  description = "ID of a Load Balancer probe used to decide whether an instance is healthy. Required when upgrade_mode is Automatic or Rolling; without it an automated rollout has no signal to stop on and will push a broken image to every instance."
  type        = string
  default     = null
}

variable "rolling_upgrade_policy" {
  description = "Batch sizing and health thresholds applied when upgrade_mode is Automatic or Rolling. Ignored for Manual, which the provider forbids the block on."
  type = object({
    max_batch_instance_percent              = optional(number, 20)
    max_unhealthy_instance_percent          = optional(number, 20)
    max_unhealthy_upgraded_instance_percent = optional(number, 20)
    pause_time_between_batches              = optional(string, "PT5M")
  })
  default = {}

  validation {
    condition = alltrue([
      var.rolling_upgrade_policy.max_batch_instance_percent >= 5 && var.rolling_upgrade_policy.max_batch_instance_percent <= 100,
      var.rolling_upgrade_policy.max_unhealthy_instance_percent >= 5 && var.rolling_upgrade_policy.max_unhealthy_instance_percent <= 100,
      var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent >= 0 && var.rolling_upgrade_policy.max_unhealthy_upgraded_instance_percent <= 100,
    ])
    error_message = "The rolling_upgrade_policy percentages must be between 5 and 100 (0 and 100 for max_unhealthy_upgraded_instance_percent)."
  }

  validation {
    condition     = can(regex("^PT?([0-9]+[HMS])+$", var.rolling_upgrade_policy.pause_time_between_batches))
    error_message = "The rolling_upgrade_policy pause_time_between_batches value must be an ISO 8601 duration, e.g. \"PT5M\"."
  }
}

variable "boot_diagnostics_enabled" {
  description = "Whether to enable boot diagnostics, which capture serial console output and boot screenshots. Leaving these off makes an instance that fails to boot impossible to diagnose after the fact."
  type        = bool
  default     = true
}

variable "boot_diagnostics_storage_account_uri" {
  description = "Blob endpoint of a storage account to write boot diagnostics to. Leave null to use the Azure-managed storage account, which needs no storage account of your own."
  type        = string
  default     = null
}

variable "tags" {
  description = "Map of tags applied to the scale set."
  type        = map(string)
  default     = {}
}
