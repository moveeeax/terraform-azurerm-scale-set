# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.0] - 2026-11-08

### Added

- `identity` input: attaches a system-assigned, user-assigned or combined
  managed identity to the scale set. Defaults to `null`, which emits no
  `identity` block, so existing scale sets plan the same. The type is checked
  against the three values the provider accepts, `identity_ids` is required
  for and only allowed with the UserAssigned types, and each ID must be a
  user-assigned identity resource ID.
- `identity_principal_id` output: principal ID of the system-assigned identity,
  for role assignments.

## [1.1.0] - 2026-11-05

### Changed

- Allow azurerm 5.x (`>= 3.0, < 6.0`) and refresh CI.

## [1.0.0]

Initial release (`v0.1.0` points at the same commit).

[Unreleased]: https://github.com/moveeeax/terraform-azurerm-scale-set/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/moveeeax/terraform-azurerm-scale-set/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/moveeeax/terraform-azurerm-scale-set/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/moveeeax/terraform-azurerm-scale-set/releases/tag/v1.0.0
