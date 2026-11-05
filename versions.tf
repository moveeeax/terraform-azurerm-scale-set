terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Every argument this module uses is present unchanged in the
      # azurerm_linux_virtual_machine_scale_set schema from 3.0.0 through 5.x
      # (the 5.0 removals on this resource are arguments the module does not
      # set). Ceiling: 6.0 has not been vetted.
      version = ">= 3.0, < 6.0"
    }
  }
}
