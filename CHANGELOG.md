# :arrows_clockwise: Microsoft Azure As Built Report Changelog

## [0.2.0] - 2026-02-11

### Added
* Add report section order customisation
* Add language support for English (US), English (GB), French, German and Spanish
* Add support for Desktop Virtualization
* Add support for Firewall Policies
* Add support for Log Analytics Workspaces
* Add support for Private Endpoints
* Add support for token authentication methods
* Add documentation for supported authentication methods in `README.md`
* Add comprehensive Pester tests for module validation
* Add Pester workflow for automated testing across Windows, Linux, and macOS platforms
* Add Codecov integration for code coverage reporting
* Add Tests/Invoke-Tests.ps1 script for running Pester tests with code coverage support
* Add Pester tests to validate localization string consistency across all languages

### Changed
* Update minimum AsBuiltReport.Core module version from 1.5.0 to 1.6.1
* Update minimum Az module version requirement from 12.0.0 to 15.3.0
* Reorganize module structure - moved module files to AsBuiltReport.Microsoft.Azure/ subdirectory
* Update Release workflow to use windows-latest runner instead of windows-2019
* Update Bluesky post action from v0.1.0 to v0.2.0
* Update module paths in Release workflow to reflect new directory structure
* Increase stale GitHub actions workflow to 90 days
* Update broken links in `change_request.yml` and `bug_report.yml` GitHub templates

### Fixed
* Fix `Get-AbrAzDesktopVirtualization` - Add explicit `-SubscriptionId` to `Get-AzWvd*` cmdlets to resolve `SharedTokenCacheCredential` authentication errors
* Fix `Get-AbrAzDnsPrivateResolver` - Replace `Get-AzResource` call with resource group name parsed from resource ID to resolve incorrect resource group assignment with multiple DNS Private Resolvers
* Fix [#22](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/22) - Add customizable report section ordering via `SectionOrder` configuration option
* Fix [#23](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/23) - Resolve unexpected executable reference warnings during report generation
* Fix [#24](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/24) - Fix token-based authentication requiring `AccountId` via `TokenParameters`
* Fix [#24](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/24) - Fix interactive authentication (`-UseInteractiveAuth`) failing with null credential error when switch not properly passed from Core module
* Fix [#25](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/25) - Replace deprecated `Get-AzVMSize` with `Get-AzComputeResourceSku` for Az.Compute 8.x+ compatibility
* Fix [#26](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/26) - Add reporting for Azure Virtual Desktop

## [0.1.8.2] - 2024-11-15

### Fixed
* Fix issue where a report would not be generated if `Subscription` InfoLevel was set to 0

### Changed
* Change Storage Account `Minimum TLS Version` healthcheck to highlight Critical

## [0.1.8.1] - 2024-11-13

### Added
* Add support for DNS Private Resolver
* Add Tenant and Subscription InfoLevels to toggle on/off

### Changed
* Update GitHub release workflow to add post to Bluesky social platform

## [0.1.7] - 2024-10-13

### Added
* Add support for Azure Policy definitions
* Add Try/Catch blocks for improved error handling

### Fixed
* Fix issue with Azure Subscription Lookup Hashtable
* Fix issue with Azure Policy assignments (Fix [#16](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/16))

### Changed
* Performance improvements
* Update GitHub Action release workflow
* Improve reporting for Azure Tenant
* Improve reporting for Azure Policy assignments
* Improve reporting for Key Vaults
* Improve reporting for Storage Accounts
* Improve reporting for Network Security Groups

## [0.1.6] - 2023-11-14

### Added
* Add initial support for Route Tables (@howardhaooooo)

## [0.1.5] - 2023-05-24

### Added
* Add initial support for Storage Account (@rebelinux)

### Fixed
* Fix issue with Az module version check (Fix [#10](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/10))

## [0.1.4] - 2023-03-19

### Added
* Add function to check for Microsoft Azure PowerShell module
* Add `ShowSectionInfo` option to provide information about Azure resources

## [0.1.3] - 2023-03-17

### Added
* Add examples to `README.md`
* Add module information and version checks to verbose messaging
### Changed
* Further improvements to section headings & TOC structure
* Update Required Privileges information in `README.md`

### Fixed
* Fix [#4](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/4)
* Fix [#5](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/5)
* Fix [#6](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/6)

## [0.1.2] - 2023-02-23

### Changed
* Improve section heading & TOC structure
* Remove Microsoft logo from default report style due to [licensing requirements](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks)
* Change default report style font to 'Segoe Ui' to align with [Microsoft guidelines](https://learn.microsoft.com/en-us/style-guide/a-z-word-list-term-collections/f/font-font-style)
* Improve bug and feature request templates

### Fixed
* Fix [#1](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues/1)

## [0.1.1] - 2022-02-14

### Changed
* Performance improvements

## [0.1.0] - 2022-02-11

### Added
* Initial report release. Support for;
    * Availabity Sets
    * Bastion Hosts
    * Express Route Circuits
    * Firewalls
    * IP Groups
    * Key Vaults
    * Load Balancers
    * Policies
    * Subscriptions
    * Virtual Machines
    * Virtual Networks


