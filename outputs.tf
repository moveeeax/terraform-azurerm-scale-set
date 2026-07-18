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
