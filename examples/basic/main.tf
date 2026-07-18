terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "scale_set" {
  source = "../.."

  name                = "example-vmss"
  resource_group_name = "example-rg"
  location            = "eastus"
  sku                 = "Standard_B2s"
  instances           = 2

  admin_username       = "azureuser"
  admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgExampleKeyReplaceMe user@host"

  subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/virtualNetworks/example-vnet/subnets/example-subnet"

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "vmss_id" {
  value = module.scale_set.id
}
