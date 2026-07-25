# Runs with no Azure credentials and no network: `terraform test`.
# The mock_provider block needs Terraform >= 1.7. The module itself still
# supports >= 1.5, so do not raise required_version on account of these tests.

mock_provider "azurerm" {}

variables {
  name                = "test-vmss"
  resource_group_name = "test-rg"
  location            = "eastus"
  subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/virtualNetworks/test-vnet/subnets/test-subnet"
  # Throwaway key generated for these tests; the private half was never kept.
  # The provider base64-decodes this field even under mock_provider, so it has
  # to be a structurally real OpenSSH key.
  admin_ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzU1pj4m0NMoY+k/bvEA6TAM9qj+4pZVB8PtJnAPUqo replace-me@example"
}

run "defaults_are_safe" {
  command = plan

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.disable_password_authentication == true
    error_message = "Password authentication must stay disabled: the module exposes no password input, so an enabled password login would be an unset-password account."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.boot_diagnostics) == 1
    error_message = "Boot diagnostics must be enabled by default so a failed boot can be diagnosed."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.upgrade_mode == "Manual"
    error_message = "The default upgrade_mode must be Manual, the only mode that cannot roll a broken image through the fleet unattended."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.rolling_upgrade_policy) == 0
    error_message = "The provider rejects a rolling_upgrade_policy block when upgrade_mode is Manual, so it must not be emitted."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.os_disk[0].storage_account_type == "Premium_LRS"
    error_message = "The default OS disk storage account type changed unexpectedly."
  }
}

run "boot_diagnostics_can_be_disabled" {
  command = plan

  variables {
    boot_diagnostics_enabled = false
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.boot_diagnostics) == 0
    error_message = "boot_diagnostics_enabled = false must drop the boot_diagnostics block entirely."
  }
}

# The headline regression: an Automatic or Rolling upgrade with no health probe
# is rejected before anything reaches Azure. Without the precondition this plan
# succeeds and the failure only surfaces at apply, or worse, the fleet upgrades
# with no health signal at all.
run "automatic_upgrade_without_health_probe_is_rejected" {
  command = plan

  variables {
    upgrade_mode = "Automatic"
  }

  expect_failures = [
    azurerm_linux_virtual_machine_scale_set.this,
  ]
}

run "rolling_upgrade_without_health_probe_is_rejected" {
  command = plan

  variables {
    upgrade_mode = "Rolling"
  }

  expect_failures = [
    azurerm_linux_virtual_machine_scale_set.this,
  ]
}

run "rolling_upgrade_with_health_probe_emits_policy" {
  command = plan

  variables {
    upgrade_mode    = "Rolling"
    health_probe_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Network/loadBalancers/test-lb/probes/health"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.health_probe_id != null
    error_message = "health_probe_id must be wired through to the scale set."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.rolling_upgrade_policy) == 1
    error_message = "The provider requires a rolling_upgrade_policy block when upgrade_mode is Rolling."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.rolling_upgrade_policy[0].pause_time_between_batches == "PT5M"
    error_message = "The default pause between upgrade batches changed unexpectedly."
  }
}

run "encryption_inputs_are_wired_through" {
  command = plan

  variables {
    encryption_at_host_enabled     = true
    os_disk_disk_encryption_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.Compute/diskEncryptionSets/test-des"
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.encryption_at_host_enabled == true
    error_message = "encryption_at_host_enabled must be wired through to the scale set."
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.os_disk[0].disk_encryption_set_id != null
    error_message = "os_disk_disk_encryption_set_id must be wired through to the os_disk block."
  }
}

run "rejects_invalid_upgrade_mode" {
  command = plan

  variables {
    upgrade_mode = "Continuous"
  }

  expect_failures = [var.upgrade_mode]
}

run "rejects_invalid_os_disk_caching" {
  command = plan

  variables {
    os_disk_caching = "WriteOnly"
  }

  expect_failures = [var.os_disk_caching]
}

run "rejects_non_openssh_public_key" {
  command = plan

  variables {
    admin_ssh_public_key = "-----BEGIN OPENSSH PRIVATE KEY-----"
  }

  expect_failures = [var.admin_ssh_public_key]
}

run "rejects_out_of_range_rolling_upgrade_percentages" {
  command = plan

  variables {
    rolling_upgrade_policy = {
      max_batch_instance_percent = 150
    }
  }

  expect_failures = [var.rolling_upgrade_policy]
}
