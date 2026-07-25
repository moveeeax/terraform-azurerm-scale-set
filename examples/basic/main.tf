terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0, < 5.0"
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

  admin_username = "azureuser"

  # Placeholder only. The provider base64-decodes this field, so the previous
  # "AAAA...ExampleKeyReplaceMe" text failed at plan time with an opaque
  # "decoding admin_ssh_key.0.public_key" error. This is a real throwaway key
  # whose private half was never kept -- replace it with your own before
  # applying, or nobody will be able to log in.
  admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzU1pj4m0NMoY+k/bvEA6TAM9qj+4pZVB8PtJnAPUqo replace-me@example"

  subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg/providers/Microsoft.Network/virtualNetworks/example-vnet/subnets/example-subnet"

  tags = {
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

output "vmss_id" {
  value = module.scale_set.id
}
