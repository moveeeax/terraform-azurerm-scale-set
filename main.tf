resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  instances           = var.instances
  admin_username      = var.admin_username

  # This module authenticates with SSH keys only and deliberately exposes no
  # password input. `true` is already the provider default; pinning it here
  # keeps the guarantee explicit and immune to a future default change.
  disable_password_authentication = true

  # Encrypts the temp disk, OS/data disk caches and unencrypted in-VM traffic
  # to the storage service. Requires the subscription-level `EncryptionAtHost`
  # feature and a supporting VM size, so it is opt-in.
  encryption_at_host_enabled = var.encryption_at_host_enabled

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type

    # null keeps the platform-managed key that Azure applies to every managed
    # disk; setting it moves the OS disk to a customer-managed key.
    disk_encryption_set_id = var.os_disk_disk_encryption_set_id
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  network_interface {
    name    = "${var.name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id
    }
  }

  upgrade_mode = var.upgrade_mode

  # Required by the provider whenever `upgrade_mode` is Automatic or Rolling:
  # without it a broken image is rolled out to every instance because nothing
  # ever reports the batch as unhealthy.
  health_probe_id = var.health_probe_id

  # The provider rejects this block for Manual and requires it for the other
  # two modes, so it is emitted on exactly that condition.
  dynamic "rolling_upgrade_policy" {
    for_each = var.upgrade_mode == "Manual" ? [] : [var.rolling_upgrade_policy]

    content {
      max_batch_instance_percent              = rolling_upgrade_policy.value.max_batch_instance_percent
      max_unhealthy_instance_percent          = rolling_upgrade_policy.value.max_unhealthy_instance_percent
      max_unhealthy_upgraded_instance_percent = rolling_upgrade_policy.value.max_unhealthy_upgraded_instance_percent
      pause_time_between_batches              = rolling_upgrade_policy.value.pause_time_between_batches
    }
  }

  # Serial-console output and boot screenshots. Omitting the block leaves boot
  # diagnostics off, which makes a failed boot undiagnosable after the fact.
  # A null URI selects the Azure-managed storage account.
  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics_enabled ? [1] : []

    content {
      storage_account_uri = var.boot_diagnostics_storage_account_uri
    }
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.upgrade_mode == "Manual" || var.health_probe_id != null
      error_message = "var.health_probe_id must be set when var.upgrade_mode is \"Automatic\" or \"Rolling\": an automated rollout with no health probe will replace every instance in the scale set with a broken image without ever pausing."
    }
  }
}
