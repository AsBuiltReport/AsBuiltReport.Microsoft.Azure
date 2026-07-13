# :arrows_clockwise: Microsoft Azure As Built Report Changelog

## [0.3.0] - 2026-07-13

### Added
* Add InfoLevel 2 detail view for ASR protected items, showing per-VM sections with replication provider, health, state, active/target locations, test failover status, and A2A-specific RPO, last heartbeat, recovery VM size, and availability zone properties
* Add support for ASR Replication Policies (`AsrPolicy`) with summary table at InfoLevel 1 and per-policy detail at InfoLevel 2; `AppConsistentSnapshot` health check warns when app-consistent snapshot frequency is disabled
* Add support for ASR Recovery Plans (`AsrRecoveryPlan`) with summary table at InfoLevel 1 and per-plan detail at InfoLevel 2
* Add support for ASR Network Mappings (`AsrNetworkMapping`) with summary table at InfoLevel 1; `MappingState` health check warns on non-Paired mappings
* Add `StorageRedundancy`, `CrossRegionRestore`, `SoftDeleteState`, `SoftDeleteRetentionDays`, `ImmutabilityState`, and `PublicNetworkAccess` properties to Recovery Services Vault detail view
* Add `SoftDeleteEnabled`, `ImmutabilityEnabled`, and `PublicNetworkAccess` health checks to Recovery Services Vault
* Add support for Azure NetApp Files (NetApp Accounts, Capacity Pools, Volumes, Snapshot Policies, Backup Policies) with per-volume detail, Active Directory and encryption configuration, mount targets, export policy rules, and 5 health checks (pool allocation, AD join status, snapshot policy attachment, backup policy attachment, customer-managed key usage)
* Add support for Management Groups, displaying the full hierarchy with parent/child relationships and direct subscription counts
* Add optional Management Group hierarchy diagram (`Options.EnableDiagrams: true`) using the AsBuiltReport.Diagram module, showing management group nodes with subscription collections sized to fit a portrait page
* Add `Options.DiagramDpi` setting to control the raster output resolution of generated diagrams
* Add support for Private DNS Zones, including record set and virtual network link counts with per-zone detail and virtual network link sub-sections at InfoLevel 2
* Add support for Virtual Network Gateways, including gateway type, SKU, BGP settings, active-active mode, generation, and VPN connection detail at InfoLevel 2
* Add support for DDoS Protection Plans, including protected virtual network count and per-plan protected VNet detail at InfoLevel 2
* Add support for Application Gateways, including SKU, WAF mode, HTTP/2, and per-gateway HTTP listener, backend pool, and request routing rule detail at InfoLevel 2
* Add support for Data Collection Rules, including data source types, Log Analytics destination count, and per-rule destination and data flow detail at InfoLevel 2
* Add support for Public IP Addresses, including SKU, allocation method, IP version, DNS settings, availability zones, and associated resource, with unattached IP health check
* Add support for Network Watchers and NSG Flow Logs, including retention policy, traffic analytics enablement, and storage account, with health checks for watcher provisioning state and disabled flow logs
* Add support for VM Scale Sets, including VM size, instance count, orchestration mode, upgrade policy, availability zones, overprovision, single placement group, and identity
* Add support for Maintenance Configurations, including scope, visibility, maintenance window start time, expiration, duration, recurrence, and timezone
* Add support for DNS Forwarding Rulesets, including outbound endpoint associations, per-ruleset forwarding rules with target DNS servers, and virtual network links at InfoLevel 2
* Add Resource Locks reporting to Virtual Networks, Key Vaults, Recovery Services Vaults, Storage Accounts, Firewalls, Private DNS Zones, Route Tables, Virtual Network Gateways, Log Analytics Workspaces, and DDoS Protection Plans; lock name and level (CanNotDelete/ReadOnly) displayed at InfoLevel 2 and above
* Add support for User Assigned Managed Identities, displaying Client ID, Principal ID, and Tenant ID with per-identity detail at InfoLevel 2
* Add support for Automation Accounts, including account state health check and per-account Runbooks, Variables, Schedules, and Credentials sub-sections at InfoLevel 2
* Add support for Diagnostic Settings via cross-resource sweep, displaying Log Analytics workspace, storage account, and Event Hub destinations alongside enabled log category count and metrics status; settings with no log categories enabled flagged as a health check
* Add support for Network Virtual Appliances (`Get-AbrAzNetworkVirtualAppliance`)
  — identifies third-party NVAs (Palo Alto, Fortinet, Cisco, Check Point, F5, Barracuda,
  SonicWall, Juniper, Riverbed) via Marketplace image publisher with optional tag-based
  fallback (`Options.NvaTag`). InfoLevel 3 cross-references associated UDR route tables,
  matching against all NIC private IPs on the appliance as well as the frontend private
  IP of any Load Balancer fronting an NVA HA pair. Configurable publisher list via
  `Options.NvaPublishers`.

### Changed
* Update minimum Az module version requirement from 15.3.0 to 16.0.0

### Fixed
* Fix `Get-AbrAsrProtectedItems` - Remove A2A-only filter so all replication providers (HyperV2Azure, InMageAzureV2, etc.) are included in the report
* Fix `Get-AbrAsrProtectedItems` - Correct `FailoverHealth` health check direction: now highlights items where test failover has failed (Critical); new `NoTestFailover` health check warns on items with no test failover performed
* Fix empty per-subscription sections appearing in the report when all enabled resource types have no matching resources in a given subscription
* Fix `Get-AbrAsrProtectedItems` - Correct `ParagraghSummary` typo to `ParagraphSummary` in all language files, which caused the introductory paragraph to render empty
* Fix `Get-AbrAzSAShare` and `Get-AbrAzSAContainer` - Switch from data plane API (`Get-AzStorageShare`, `Get-AzStorageContainer`) to ARM management plane (`Get-AzRmStorageShare`, `Get-AzRmStorageContainer`) to resolve 403 Forbidden errors when storage account shared key access is disabled
* Fix `Get-AbrAzSAQueue` and `Get-AbrAzSATable` - Use `New-AzStorageContext -UseConnectedAccount` for OAuth-based data plane access to resolve 403 Forbidden errors when storage account shared key access is disabled
* Fix unhandled `Error while copying content to a stream` exception in `Invoke-AsBuiltReport.Microsoft.Azure` caused by `Get-AzTenant`, `Get-AzLocation`, and `Get-AzSubscription` being called without error handling after authentication; failures are now caught and reported as warnings
* Fix `Get-AbrAzLoadBalancer` - Correct `LoadBalancerImage` to `Image` in all language files; the mismatched localization key caused the Load Balancer architecture diagram to fail rendering and fall back to the `ImageError` message

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


