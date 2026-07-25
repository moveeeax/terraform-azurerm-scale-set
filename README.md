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

## Automated upgrades need a health probe

`upgrade_mode` defaults to `Manual`, where you decide when each instance picks
up a new model. `Automatic` and `Rolling` hand that decision to Azure, and Azure
needs a way to tell a healthy instance from a broken one. Without that signal a
bad image is rolled straight through the entire fleet, because no batch ever
reports itself unhealthy and nothing ever pauses the rollout.

So `health_probe_id` is **required** whenever `upgrade_mode` is `Automatic` or
`Rolling`. The module enforces this at plan time rather than letting the
provider fail during apply:

```hcl
module "scale_set" {
  source = "github.com/moveeeax/terraform-azurerm-scale-set"

  # ...

  upgrade_mode    = "Rolling"
  health_probe_id = azurerm_lb_probe.app.id

  rolling_upgrade_policy = {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 20
    pause_time_between_batches              = "PT5M"
  }
}
```

The probe must target a port that goes unhealthy when your application is
broken. A probe that only checks that the VM has an IP address will happily
declare a crash-looping fleet healthy.

## Security defaults

| Behaviour | Default | Notes |
|-----------|---------|-------|
| Password authentication | Disabled, not configurable | The module takes an SSH key only and exposes no password input. |
| OS disk encryption at rest | Platform-managed key | Always on for Azure managed disks. Set `os_disk_disk_encryption_set_id` for a customer-managed key. |
| Encryption at host | Off | Set `encryption_at_host_enabled = true`. Needs the `EncryptionAtHost` subscription feature and a supporting VM size. |
| Boot diagnostics | On, Azure-managed storage | Serial console output and boot screenshots. Set `boot_diagnostics_enabled = false` to opt out. |
| Overprovisioning | Provider default (`true`) | Left alone deliberately: it improves deployment success rate and the extra instances are deleted once the scale set is up. |

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.5          |
| azurerm   | >= 3.0, < 5.0   |

Every argument this module uses is present unchanged in the
`azurerm_linux_virtual_machine_scale_set` schema from azurerm 3.0.0 through
4.x, so the lower bound is honest. The upper bound keeps an unreleased 5.0
from reaching consumers before the module has been checked against it.

Running the test suite additionally requires Terraform >= 1.7 for
`mock_provider`. The module itself does not.

## Inputs

| Name                                   | Description                                                            | Type          | Default          | Required |
|----------------------------------------|------------------------------------------------------------------------|---------------|------------------|:--------:|
| `name`                                 | Name of the virtual machine scale set.                                 | `string`      | n/a              |   yes    |
| `resource_group_name`                  | Name of the resource group in which to create the scale set.           | `string`      | n/a              |   yes    |
| `location`                             | Azure region in which to create the scale set.                         | `string`      | n/a              |   yes    |
| `sku`                                  | SKU size of the instances in the scale set.                            | `string`      | `"Standard_B2s"` |    no    |
| `instances`                            | Number of virtual machine instances in the scale set.                  | `number`      | `2`              |    no    |
| `admin_username`                       | Administrator username for the scale set instances.                    | `string`      | `"azureuser"`    |    no    |
| `admin_ssh_public_key`                 | OpenSSH-formatted public key granted access to the admin account.      | `string`      | n/a              |   yes    |
| `subnet_id`                            | ID of the subnet into which scale set instances are placed.            | `string`      | n/a              |   yes    |
| `os_disk_caching`                      | Caching mode of the OS disk.                                           | `string`      | `"ReadWrite"`    |    no    |
| `os_disk_storage_account_type`         | Storage account type of the OS disk.                                   | `string`      | `"Premium_LRS"`  |    no    |
| `os_disk_disk_encryption_set_id`       | Disk encryption set for a customer-managed OS disk key.                | `string`      | `null`           |    no    |
| `encryption_at_host_enabled`           | Encrypt temp disk, disk caches and host-to-storage traffic.            | `bool`        | `false`          |    no    |
| `source_image_reference`               | Marketplace image reference used to provision the instances.           | `object`      | Ubuntu 22.04 LTS |    no    |
| `upgrade_mode`                         | How instances are upgraded when the scale set model changes.           | `string`      | `"Manual"`       |    no    |
| `health_probe_id`                      | Load Balancer probe deciding instance health. Required unless `Manual`.| `string`      | `null`           | if not `Manual` |
| `rolling_upgrade_policy`               | Batch sizing and health thresholds for automated upgrades.             | `object`      | 20% / 20% / 20% / `PT5M` |    no    |
| `boot_diagnostics_enabled`             | Capture serial console output and boot screenshots.                    | `bool`        | `true`           |    no    |
| `boot_diagnostics_storage_account_uri` | Blob endpoint for boot diagnostics; null uses Azure-managed storage.   | `string`      | `null`           |    no    |
| `tags`                                 | Map of tags applied to the scale set.                                  | `map(string)` | `{}`             |    no    |

## Outputs

| Name       | Description                                     |
|------------|-------------------------------------------------|
| `id`       | ID of the virtual machine scale set.            |
| `name`     | Name of the virtual machine scale set.          |
| `identity` | Managed identity block of the scale set, if set.|

## Development

```sh
terraform fmt -recursive
terraform init -backend=false && terraform validate
terraform test          # mocked provider, no Azure credentials needed
```

## License

[MIT](LICENSE)
