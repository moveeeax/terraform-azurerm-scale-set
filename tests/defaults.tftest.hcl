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

# Managed identity (issue #3).

run "identity_is_off_by_default" {
  command = plan

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.identity) == 0
    error_message = "No identity block may be emitted unless var.identity is set, so existing scale sets plan the same."
  }

  assert {
    condition     = output.identity_principal_id == null
    error_message = "identity_principal_id must be null when no identity is configured."
  }
}

run "system_assigned_identity_is_wired_through" {
  command = plan

  variables {
    identity = {
      type = "SystemAssigned"
    }
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.identity[0].type == "SystemAssigned"
    error_message = "identity.type must be wired through to the scale set."
  }

  assert {
    condition     = length(azurerm_linux_virtual_machine_scale_set.this.identity[0].identity_ids) == 0
    error_message = "A SystemAssigned identity must not carry identity_ids."
  }
}

run "user_assigned_identity_is_wired_through" {
  command = plan

  variables {
    identity = {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uai"]
    }
  }

  assert {
    condition     = azurerm_linux_virtual_machine_scale_set.this.identity[0].type == "SystemAssigned, UserAssigned"
    error_message = "identity.type must be wired through to the scale set."
  }

  assert {
    condition     = contains(azurerm_linux_virtual_machine_scale_set.this.identity[0].identity_ids, "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uai")
    error_message = "identity.identity_ids must be wired through to the scale set."
  }
}

run "identity_principal_id_is_exported" {
  # apply against the mock so the computed principal_id gets a value.
  variables {
    identity = {
      type = "SystemAssigned"
    }
  }

  assert {
    condition     = output.identity_principal_id == azurerm_linux_virtual_machine_scale_set.this.identity[0].principal_id
    error_message = "identity_principal_id must expose the principal ID of the scale set identity."
  }

  assert {
    condition     = output.identity_principal_id != null
    error_message = "identity_principal_id must be set when an identity is configured."
  }
}

run "rejects_invalid_identity_type" {
  command = plan

  variables {
    identity = {
      type = "Managed"
    }
  }

  expect_failures = [var.identity]
}

run "rejects_user_assigned_identity_without_ids" {
  command = plan

  variables {
    identity = {
      type = "UserAssigned"
    }
  }

  expect_failures = [var.identity]
}

run "rejects_identity_ids_with_system_assigned" {
  command = plan

  variables {
    identity = {
      type         = "SystemAssigned"
      identity_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-uai"]
    }
  }

  expect_failures = [var.identity]
}

run "rejects_malformed_identity_id" {
  command = plan

  variables {
    identity = {
      type         = "UserAssigned"
      identity_ids = ["test-uai"]
    }
  }

  expect_failures = [var.identity]
}
