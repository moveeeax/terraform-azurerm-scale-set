# terraform-azurerm-scale-set

Terraform module that manages an [Azure](https://azure.microsoft.com/) Linux
virtual machine scale set. It provisions a group of identical instances from a
marketplace image with SSH-key authentication, a managed OS disk and a primary
network interface bound to a supplied subnet.

## Usage

```hcl
module "scale_set" {
  source = "github.com/moveeeax/terraform-azurerm-scale-set"

  name                = "web-vmss"
  resource_group_name = "prod-rg"
  location            = "eastus"
  sku                 = "Standard_D2s_v5"
  instances           = 3

  admin_username       = "azureuser"
  admin_ssh_public_key = file("~/.ssh/id_rsa.pub")

  subnet_id = module.subnet.id

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| azurerm   | >= 3.0   |

## Inputs

| Name                           | Description                                                            | Type          | Default          | Required |
|--------------------------------|------------------------------------------------------------------------|---------------|------------------|:--------:|
| `name`                         | Name of the virtual machine scale set.                                 | `string`      | n/a              |   yes    |
| `resource_group_name`          | Name of the resource group in which to create the scale set.           | `string`      | n/a              |   yes    |
| `location`                     | Azure region in which to create the scale set.                         | `string`      | n/a              |   yes    |
| `sku`                          | SKU size of the instances in the scale set.                            | `string`      | `"Standard_B2s"` |    no    |
| `instances`                    | Number of virtual machine instances in the scale set.                  | `number`      | `2`              |    no    |
| `admin_username`               | Administrator username for the scale set instances.                    | `string`      | `"azureuser"`    |    no    |
| `admin_ssh_public_key`         | OpenSSH-formatted public key granted access to the admin account.      | `string`      | n/a              |   yes    |
| `subnet_id`                    | ID of the subnet into which scale set instances are placed.            | `string`      | n/a              |   yes    |
| `os_disk_caching`              | Caching mode of the OS disk.                                           | `string`      | `"ReadWrite"`    |    no    |
| `os_disk_storage_account_type` | Storage account type of the OS disk.                                   | `string`      | `"Premium_LRS"`  |    no    |
| `source_image_reference`       | Marketplace image reference used to provision the instances.           | `object`      | Ubuntu 22.04 LTS |    no    |
| `upgrade_mode`                 | How instances are upgraded when the scale set model changes.           | `string`      | `"Manual"`       |    no    |
| `tags`                         | Map of tags applied to the scale set.                                  | `map(string)` | `{}`             |    no    |

## Outputs

| Name       | Description                                     |
|------------|-------------------------------------------------|
| `id`       | ID of the virtual machine scale set.            |
| `name`     | Name of the virtual machine scale set.          |
| `identity` | Managed identity block of the scale set, if set.|

## License

[MIT](LICENSE)
