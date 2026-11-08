output "id" {
  description = "ID of the virtual machine scale set."
  value       = azurerm_linux_virtual_machine_scale_set.this.id
}

output "name" {
  description = "Name of the virtual machine scale set."
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "identity" {
  description = "Managed identity block of the scale set, if configured."
  value       = azurerm_linux_virtual_machine_scale_set.this.identity
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned identity, for role assignments. null when no identity is configured. A user-assigned identity has its own principal_id on the azurerm_user_assigned_identity resource."
  value       = try(azurerm_linux_virtual_machine_scale_set.this.identity[0].principal_id, null)
}
