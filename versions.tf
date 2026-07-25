terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Every argument this module uses is present unchanged in the
      # azurerm_linux_virtual_machine_scale_set schema from 3.0.0 through 4.x.
      # The upper bound keeps a future 5.0 from silently reaching consumers
      # before the module has been checked against it.
      version = ">= 3.0, < 5.0"
    }
  }
}
