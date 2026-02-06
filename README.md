<!-- ********** DO NOT EDIT THESE LINKS ********** -->
<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a>
            <img src='https://github.com/AsBuiltReport.png' width="8%" height="8%" /></a>
</p>
<p align="center">
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Microsoft.Azure/" alt="PowerShell Gallery Version">
        <img src="https://img.shields.io/powershellgallery/v/AsBuiltReport.Microsoft.Azure.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Microsoft.Azure/" alt="PS Gallery Downloads">
        <img src="https://img.shields.io/powershellgallery/dt/AsBuiltReport.Microsoft.Azure.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Microsoft.Azure/" alt="PS Platform">
        <img src="https://img.shields.io/powershellgallery/p/AsBuiltReport.Microsoft.Azure.svg" /></a>
</p>
<p align="center">
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/graphs/commit-activity" alt="GitHub Last Commit">
        <img src="https://img.shields.io/github/last-commit/AsBuiltReport/AsBuiltReport.Microsoft.Azure/master.svg" /></a>
    <a href="https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/master/LICENSE" alt="GitHub License">
        <img src="https://img.shields.io/github/license/AsBuiltReport/AsBuiltReport.Microsoft.Azure.svg" /></a>
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/graphs/contributors" alt="GitHub Contributors">
        <img src="https://img.shields.io/github/contributors/AsBuiltReport/AsBuiltReport.Microsoft.Azure.svg"/></a>
</p>
<p align="center">
    <a href="https://codecov.io/gh/AsBuiltReport/AsBuiltReport.Microsoft.Azure" >
    <img src="https://codecov.io/gh/AsBuiltReport/AsBuiltReport.Microsoft.Azure/graph/badge.svg?token=VGABX486CM"/>
    </a>
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/actions/workflows/Pester.yml" alt="Pester Tests">
        <img src="https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/workflows/Pester%20Tests/badge.svg" /></a>
</p>
<p align="center">
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>

<p align="center">
    <a href='https://ko-fi.com/B0B7DDGZ7' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://ko-fi.com/img/githubbutton_sm.svg' border='0' alt='Want to keep alive this project? Support me on Ko-fi' /></a>
</p>
<!-- ********** DO NOT EDIT THESE LINKS ********** -->

# Microsoft Azure As Built Report

Microsoft Azure As Built Report is a PowerShell module which works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-sourced community project which utilises PowerShell to produce as-built documentation in multiple document formats for multiple vendors and technologies.

Please refer to the AsBuiltReport [website](https://www.asbuiltreport.com) for more detailed information about this project.

The Microsoft Azure As Built Report currently supports reporting for the following Azure resources;

* Availability Sets
* Bastion Hosts
* Desktop Virtualization
* ExpressRoute Circuits
* Firewalls
* Firewall Policies
* IP Groups
* Key Vaults
* Load Balancers
* Log Analytics Workspaces
* Policies
* Private DNS Resolvers
* Private Endpoints
* Route Tables
* Storage Accounts
* Subscriptions
* Tenants
* Virtual Machines
* Virtual Networks

# :beginner: Getting Started
Below are the instructions on how to install, configure and generate a Microsoft Azure As Built report.

### PowerShell
This report is compatible with the following PowerShell versions;

<!-- ********** Update supported PowerShell versions ********** -->
| Windows PowerShell 5.1 |    PowerShell 7    |
|:----------------------:|:------------------:|
|   :white_check_mark:   | :white_check_mark: |

## 🌐 Language Support
<!-- ********** Update supported languages ********** -->
The Microsoft Azure As Built Report supports the following languages;

| Language | Culture Code |
|----------|--------------|
| English (US) | en-US (Default) |
| English (GB) | en-GB |
| French | fr-FR |
| German | de-DE |
| Spanish | es-ES |

## :wrench: System Requirements
<!-- ********** Update system requirements ********** -->
PowerShell 5.1 or PowerShell 7, and the following PowerShell modules are required for generating a Microsoft Azure As Built Report.

- [Microsoft Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure)
- [AsBuiltReport.Microsoft.Azure Module](https://www.powershellgallery.com/packages/AsBuiltReport.Microsoft.Azure/)

### :closed_lock_with_key: Required Privileges
<!-- ********** Define required privileges ********** -->
<!-- ********** Try to follow best practices to define least privileges ********** -->

The Microsoft Azure As Built Report requires an Azure AD account. This report will not work with personal Azure accounts.

The least privileged roles required to generate a Microsoft Azure As Built Report are;
* Reader
* Backup Reader

## :key: Authentication Methods

The Microsoft Azure As Built Report supports the following authentication methods to connect to Azure tenants. Choose the method that best suits your environment and security requirements.

### 1. Organizational ID (Username/Password)

Authenticate using an Azure AD organizational account with username and password credentials.

**Example:**
```powershell
$TenantId = '555fff88-777d-1234-987a-23bc67890z5'
New-AsBuiltReport -Report Microsoft.Azure -Target $TenantId `
    -Username 'admin@contoso.com' -Password 'YourPassword' `
    -Format HTML -OutputFolderPath 'C:\Reports'
```

**Using stored credentials:**
```powershell
$Creds = Get-Credential
$TenantId = '555fff88-777d-1234-987a-23bc67890z5'
New-AsBuiltReport -Report Microsoft.Azure -Target $TenantId `
    -Credential $Creds -Format HTML -OutputFolderPath 'C:\Reports'
```

### 2. Interactive Authentication (MFA/Browser-based)

Authenticate interactively via web browser, supporting Multi-Factor Authentication (MFA) and modern authentication flows.

**Example:**
```powershell
$TenantId = '555fff88-777d-1234-987a-23bc67890z5'
New-AsBuiltReport -Report Microsoft.Azure -Target $TenantId `
    -UseInteractiveAuth -Format HTML,Word -OutputFolderPath 'C:\Reports'
```

> [!NOTE]
> The `-UseInteractiveAuth` parameter has an alias `-MFA` for backwards compatibility.

### 3. Token Authentication

Authenticate using an access token obtained from Azure AD. This method requires additional parameters to be passed via the `-TokenParameters` hashtable.

**Required Parameters:**
- `AccountId`: The Azure account/UPN associated with the access token

**Example using Azure CLI:**
```powershell
# Get access token from Azure CLI
$Token = (az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
$AccountId = (az account show --query user.name -o tsv)

# Generate report using token
$TenantId = '555fff88-777d-1234-987a-23bc67890z5'
New-AsBuiltReport -Report Microsoft.Azure -Target $TenantId `
    -Token $Token -TokenParameters @{AccountId=$AccountId} `
    -Format HTML -OutputFolderPath 'C:\Reports'
```

**Example using Az PowerShell:**
```powershell
# Connect to Azure and get access token
Connect-AzAccount
$Token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
$AccountId = (Get-AzContext).Account.Id

# Generate report using token
$TenantId = '555fff88-777d-1234-987a-23bc67890z5'
New-AsBuiltReport -Report Microsoft.Azure -Target $TenantId `
    -Token $Token -TokenParameters @{AccountId=$AccountId} `
    -Format HTML,Word -OutputFolderPath 'C:\Reports'
```

**Example with Managed Identity (Azure Automation/VM):**
```powershell
# Get token using managed identity
Connect-AzAccount -Identity
$Token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
$TenantId = (Get-AzContext).Tenant.Id

# Generate report
New-AsBuiltReport -Report Microsoft.Azure -Target $TenantId `
    -Token $Token -TokenParameters @{AccountId='managed-identity@system'} `
    -Format HTML -OutputFolderPath 'C:\Reports'
```

## :package: Module Installation

### PowerShell
<!-- ********** Add installation for any additional PowerShell module(s) ********** -->
Open a PowerShell terminal window and install each of the required modules.

> [!NOTE]
> Microsoft Az 15.2.0 or higher is required. Please ensure older Az modules have been uninstalled.

```powershell
# Install
install-module Az -Repository PSGallery -MinimumVersion 15.2.0 -Force
install-module AsBuiltReport.Microsoft.Azure -Repository PSGallery -Force

# Update
update-module Az -Force
update-module AsBuiltReport.Microsoft.Azure -Force
```

### GitHub
If you are unable to use the PowerShell Gallery, you can still install the module manually. Ensure you repeat the following steps for the [system requirements](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure#wrench-system-requirements) also.

1. Download the code package / [latest release](https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/releases/latest) zip from GitHub
2. Extract the zip file
3. Copy the folder `AsBuiltReport.Microsoft.Azure` to a path that is set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with
    ```powershell
    $path = (Get-Module -Name AsBuiltReport.Microsoft.Azure -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```
5. Close and reopen the PowerShell terminal window.

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable PSModulePath if you want to use another path._

## :pencil2: Configuration

The Microsoft Azure As Built Report utilises a JSON file to allow configuration of report information, options, detail and healthchecks.

> [!IMPORTANT]
> Please remember to generate a new report JSON configuration file after each module update to ensure the report functions correctly.

A Microsoft Azure report configuration file can be generated by executing the following command;
```powershell
New-AsBuiltReportConfig -Report Microsoft.Azure -FolderPath <User specified folder> -Filename <Optional>
```

Executing this command will copy the default Microsoft Azure report JSON configuration to a user specified folder.

All report settings can then be configured via the JSON file.

The following provides information of how to configure each schema within the report's JSON file.

<!-- ********** DO NOT CHANGE THE REPORT SCHEMA SETTINGS ********** -->
### Report
The **Report** schema provides configuration of the Microsoft Azure report information.

| Sub-Schema          | Setting      | Default                         | Description                                                                                            |
|---------------------|--------------|---------------------------------|--------------------------------------------------------------------------------------------------------|
| Name                | User defined | Microsoft Azure As Built Report | The name of the As Built Report                                                                        |
| Version             | User defined | 1.0                             | The report version                                                                                     |
| Status              | User defined | Released                        | The report release status                                                                              |
| Language            | User defined | en-US                           | The default report language. This can be customised if the report module provides multilingual support |
| ShowCoverPageImage  | true / false | true                            | Toggle to enable/disable the display of the cover page image                                           |
| ShowTableOfContents | true / false | true                            | Toggle to enable/disable table of contents                                                             |
| ShowHeaderFooter    | true / false | true                            | Toggle to enable/disable document headers & footers                                                    |
| ShowTableCaptions   | true / false | true                            | Toggle to enable/disable table captions/numbering                                                      |

### Options
The **Options** schema allows certain options within the report to be toggled on or off.

| Sub-Schema      | Setting      | Default | Description                                                                                                                                                                                                                                                                            |
|-----------------|--------------|---------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ShowSectionInfo | true / false | true    | Toggle to enable/disable information relating to Azure resources within each section.                                                                                                                                                                                                  |
| ShowTags        | true / false | true    | Toggle to enable/disable the display of Azure resource tags. <br><br> _**Note:** Reporting of tags is not currently available on all Azure resources. Tags will only be displayed for Azure resources when the relevant section [InfoLevel](#infolevel) is configured to 2 or higher._ |

### Filter
The **Filter** schema allows report content to be filtered to specific Azure subscriptions within a tenant.

| Sub-Schema   | Setting      | Default | Description                                                                                                                                                                   |
|--------------|--------------|---------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Subscription | User defined | *       | Filters report content to specific Azure subscription IDs within a tenant. <br>Specifying an asterisk (*) will generate a report for all Azure subscriptions within a tenant. |

#### Example 1: Generate a report for all Azure subscriptions within a tenant.
```json
"Filter": {
    "Subscription": ["*"]
},
```

#### Example 2: Filter report content to specific Azure subscription IDs within a tenant.
```json
"Filter": {
    "Subscription": ["555fff88-777d-1234-987a-23bc67890z5","666dfg67-654h-1234-984f-08kb67834y8"]
},
```

<!-- ********** Add/Remove the number of InfoLevels as required ********** -->
### InfoLevel
The **InfoLevel** schema allows configuration of each section of the report at a granular level. The following sections can be set.

There are 5 levels (0-4) of detail granularity for each section as follows;

| Setting | InfoLevel         | Description                                                                                         |
|:-------:|-------------------|-----------------------------------------------------------------------------------------------------|
|    0    | Disabled          | Does not collect or display any information                                                         |
|    1    | Enabled / Summary | Provides summarised information for a collection of objects                                         |
|    2    | Detailed          | Provides detailed information for individual objects                                                |
|    3    | Adv Detailed      | Provides detailed information for individual objects, as well as information for associated objects |
|    4    | Comprehensive     | Provides comprehensive information for individual objects, such as advanced configuration settings  |

The table below outlines the default and maximum **InfoLevel** settings for each section.

| Sub-Schema            | Default Setting | Maximum Setting |
|-----------------------|:---------------:|:---------------:|
| AvailabilitySet       |        1        |        1        |
| Bastion               |        1        |        2        |
| DesktopVirtualization |        1        |        4        |
| DnsPrivateResolver    |        1        |        2        |
| ExpressRoute          |        1        |        2        |
| Firewall              |        1        |        3        |
| FirewallPolicy        |        1        |        4        |
| IpGroup               |        1        |        2        |
| KeyVault              |        1        |        1        |
| LoadBalancer          |        1        |        2        |
| LogAnalyticsWorkspace |        1        |        2        |
| NetworkSecurityGroup  |        1        |        2        |
| Policy > Assignments  |        1        |        2        |
| Policy > Definitions  |        0        |        1        |
| RecoveryServicesVault |        1        |        2        |
| RouteTable            |        1        |        2        |
| SiteRecovery          |        1        |        1        |
| StorageAccount        |        1        |        2        |
| Subscription          |        1        |        1        |
| Tenant                |        1        |        1        |
| VirtualNetwork        |        1        |        2        |
| VirtualMachine        |        1        |        2        |

### Healthcheck
The **Healthcheck** schema is used to toggle health checks on or off.

#### Bastion
The **Bastion** schema is used to configure health checks for Azure Bastion.

| Sub-Schema        | Setting      | Default | Description                                                 | Highlight                                                                                   |
|-------------------|--------------|---------|-------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Bastion instances in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |

#### DesktopVirtualization
The **DesktopVirtualization** schema is used to configure health checks for Azure Virtual Desktop.

| Sub-Schema         | Setting      | Default | Description                                                        | Highlight                                                                                           |
|--------------------|--------------|---------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| SessionHostHealth  | true / false | true    | Highlights session hosts not in Available status or with failed health checks | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Session host is unavailable or unhealthy    |
| DrainMode          | true / false | true    | Highlights session hosts with drain mode enabled (not accepting new sessions) | ![Info](https://placehold.co/15x15/D4E4F7/D4E4F7) Session host is in drain mode                   |
| RegistrationExpiry | true / false | true    | Highlights host pools with expired registration tokens             | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Registration token has expired               |
| NoSessionHosts     | true / false | true    | Warns when a host pool has no session hosts configured             | Displays warning message in report                                                                  |
| HostPoolCapacity   | true / false | true    | Warns when a host pool is at maximum session capacity              | Displays warning message in report                                                                  |

#### DnsPrivateResolver
The **DnsPrivateResolver** schema is used to configure health checks for Azure DNS Private Resolver.

| Sub-Schema        | Setting      | Default | Description                                                     | Highlight                                                                                    |
|-------------------|--------------|---------|-----------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights DNS Private Resolvers in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state  |
| CurrentState      | true / false | true    | Highlights DNS Private Resolvers not in a Connected state       | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) DNS Private Resolver is not Connected |

#### ExpressRoute
The **ExpressRoute** schema is used to configure health checks for Azure ExpressRoute.

| Sub-Schema    | Setting      | Default | Description                                         | Highlight                                                                                |
|---------------|--------------|---------|-----------------------------------------------------|------------------------------------------------------------------------------------------|
| CircuitStatus | true / false | true    | Highlights ExpressRoute circuits which are disabled | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) ExpressRoute circuit is disabled |

#### Firewall
The **Firewall** schema is used to configure health checks for Azure Firewall.

| Sub-Schema        | Setting      | Default | Description                                         | Highlight                                                                                   |
|-------------------|--------------|---------|-----------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Firewalls in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |

#### FirewallPolicy
The **FirewallPolicy** schema is used to configure health checks for Azure Firewall Policy.

| Sub-Schema        | Setting      | Default | Description                                                    | Highlight                                                                                   |
|-------------------|--------------|---------|----------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Firewall Policies in a failed provisioning state    | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |
| ThreatIntelMode   | true / false | true    | Highlights Firewall Policies with Threat Intelligence disabled | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Threat Intelligence is disabled      |

#### IpGroup
The **IpGroup** schema is used to configure health checks for Azure IP Groups.

| Sub-Schema        | Setting      | Default | Description                                         | Highlight                                                                                   |
|-------------------|--------------|---------|-----------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights IP Groups in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |

#### KeyVault
The **KeyVault** schema is used to configure health checks for Azure Key Vault.

| Sub-Schema          | Setting      | Default | Description                                              | Highlight                                                                               |
|---------------------|--------------|---------|----------------------------------------------------------|-----------------------------------------------------------------------------------------|
| SoftDelete          | true / false | true    | Highlights Key Vaults without soft delete enabled        | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Soft delete is disabled         |
| PurgeProtection     | true / false | true    | Highlights Key Vaults without purge protection enabled   | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Purge protection is disabled     |
| PublicNetworkAccess | true / false | true    | Highlights Key Vaults with public network access enabled | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Public network access is enabled |
| RBACAuthorization   | true / false | true    | Highlights Key Vaults without RBAC authorization enabled | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) RBAC authorization is disabled   |

#### LoadBalancer
The **LoadBalancer** schema is used to configure health checks for Azure Load Balancer.

| Sub-Schema        | Setting      | Default | Description                                              | Highlight                                                                                   |
|-------------------|--------------|---------|----------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Load Balancers in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |

#### LogAnalyticsWorkspace
The **LogAnalyticsWorkspace** schema is used to configure health checks for Azure Log Analytics Workspace.

| Sub-Schema                      | Setting      | Default | Description                                                                  | Highlight                                                                                             |
|---------------------------------|--------------|---------|------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| ProvisioningState               | true / false | true    | Highlights workspaces which are in a critical state                          | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state           |
| PublicNetworkAccessForIngestion | true / false | true    | Highlights workspaces which have public network access enabled for ingestion | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Public network access for ingestion is enabled |
| PublicNetworkAccessForQuery     | true / false | true    | Highlights workspaces which have public network access enabled for query     | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Public network access for query is enabled     |

#### NetworkSecurityGroup
The **NetworkSecurityGroup** schema is used to configure health checks for Azure Network Security Groups.

| Sub-Schema            | Setting      | Default | Description                                                                           | Highlight                                                                                        |
|-----------------------|--------------|---------|---------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| ProvisioningState     | true / false | true    | Highlights NSGs in a failed provisioning state                                        | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state      |
| OverlyPermissiveRules | true / false | true    | Highlights NSG rules with overly permissive source addresses (*, 0.0.0.0/0, Internet) | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Rule has overly permissive source address |

#### PrivateEndpoint
The **PrivateEndpoint** schema is used to configure health checks for Azure Private Endpoints.

| Sub-Schema        | Setting      | Default | Description                                                      | Highlight                                                                                   |
|-------------------|--------------|---------|------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Private Endpoints in a failed provisioning state      | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |
| ConnectionStatus  | true / false | true    | Highlights Private Endpoints with connection status not Approved | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Connection is not Approved          |

#### RecoveryServicesVault
The **RecoveryServicesVault** schema is used to configure health checks for Azure Recovery Services Vault.

| Sub-Schema                    | Setting      | Default | Description                                                        | Highlight                                                                                            |
|-------------------------------|--------------|---------|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------------|
| ProvisioningState             | true / false | true    | Highlights Recovery Services Vaults in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state          |
| PrivateEndpointStateForBackup | true / false | true    | Highlights vaults without private endpoints configured for backup  | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Private endpoint for backup is not configured |

#### RouteTable
The **RouteTable** schema is used to configure health checks for Azure Route Tables.

| Sub-Schema        | Setting      | Default | Description                                            | Highlight                                                                                   |
|-------------------|--------------|---------|--------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Route Tables in a failed provisioning state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |

#### SiteRecovery
The **SiteRecovery** schema is used to configure health checks for Azure Site Recovery.

| Sub-Schema        | Setting      | Default | Description                                               | Highlight                                                                                                                       |
|-------------------|--------------|---------|-----------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| ReplicationHealth | true / false | true    | Highlights replicated items which are in a critical state | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Replication health is in a critical state                               |
| FailoverHealth    | true / false | true    | Highlights the failover health status of replicated items | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) A successful test failover has not been performed on the replicated item |

#### StorageAccount
The **StorageAccount** schema is used to configure health checks for Azure Storage Account.

| Sub-Schema              | Setting      | Default | Description                                                               | Highlight                                                                                    |
|-------------------------|--------------|---------|---------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| ProvisioningState       | true / false | true    | Highlights storage accounts which are in a critical state                 | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state  |
| StorageAccountKeyAccess | true / false | true    | Highlights storage accounts which have storage account key access enabled | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Storage account key access is enabled |
| SecureTransfer          | true / false | true    | Highlights storage accounts which do not have secure transfer enabled     | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Secure transfer is disabled           |
| BlobAnonymousAccess     | true / false | true    | Highlights storage accounts which have Blob anonymous read access enabled | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Anonymous read access is enabled      |
| PublicNetworkAccess     | true / false | true    | Highlights storage accounts which have public network access enabled      | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Public network access is enabled      |
| MinimumTlsVersion       | true / false | true    | Highlights storage accounts which have TLS 1.0 or TLS 1.1 configured      | ![Citical](https://placehold.co/15x15/FEDDD7/FEDDD7) TLS version 1.0 or 1.1 configured     |

#### VirtualMachine
The **VirtualMachine** schema is used to configure health checks for Azure Virtual Machines.

| Sub-Schema      | Setting      | Default | Description                                                                             | Highlight                                                                                                                                                                                                   |
|-----------------|--------------|---------|-----------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Status          | true / false | true    | Highlights VMs which are not in a running state                                         | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) VM is in a deallocated state                                                                                                                         |
| DiskEncryption  | true / false | true    | Highlights VMs which do not have disk encryption enabled                                | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Disk encryption is disabled                                                                                                                          |
| BootDiagnostics | true / false | true    | Highlights VMs which do not have boot diagnostics enabled with a custom storage account | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Boot diagnostics is disabled <br> ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Boot diagnostics is enabled with a managed storage account |
| BackupEnabled   | true / false | true    | Highlights VMs which do not have Azure Backup enabled                                   | ![Warning](https://placehold.co/15x15/FFF4C7/FFF4C7) Backup is disabled                                                                                                                                   |

#### VirtualNetwork
The **VirtualNetwork** schema is used to configure health checks for Azure Virtual Networks.

| Sub-Schema        | Setting      | Default | Description                                                  | Highlight                                                                                   |
|-------------------|--------------|---------|--------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ProvisioningState | true / false | true    | Highlights Virtual Networks in a failed provisioning state   | ![Critical](https://placehold.co/15x15/FEDDD7/FEDDD7) Provisioning is in a critical state |
| DnsServers        | true / false | true    | Highlights Virtual Networks using default Azure-provided DNS | ![Info](https://placehold.co/15x15/D4E4F7/D4E4F7) Using default Azure-provided DNS        |

## :computer: Examples
<!-- ********** Add some examples. Use other AsBuiltReport modules as a guide. ********** -->

```powershell
# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using 3rd party authentication. Export report to HTML & DOCX formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Tim\Documents'
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -UseInteractiveAuth -Format Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -Timestamp

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using specified credentials and report configuration file. Export report to Text, HTML & DOCX formats. Use default report style. Save reports to 'C:\Users\Tim\Documents'. Display verbose messages to the console.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Username 'tim@acme.com' -Password 'MyP@ssw0rd!' -Format Text,Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -ReportConfigFilePath 'C:\Users\Tim\AsBuiltReport\AsBuiltReport.Microsoft.Azure.json' -Verbose

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Tim\Documents'.
PS C:\> $Creds = Get-Credential
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Credential $Creds -Format Html,Text -OutputFolderPath 'C:\Users\Tim\Documents' -EnableHealthCheck

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using specified credentials. Report exports to WORD format by default. Apply custom style to the report. Reports are saved to the user profile folder by default.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Username 'joe@acme.com' -Password 'MyP@ssw0rd!' -StyleFilePath 'C:\Scripts\Styles\MyCustomStyle.ps1'

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using specified credentials. Report exports to WORD format by default. Generate report in Spanish. Reports are saved to the user profile folder by default.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Username 'joe@acme.com' -Password 'MyP@ssw0rd!' -ReportLanguage es-ES

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using Entra ID authentication. Export report to HTML & DOCX formats. Use default report style. Reports are saved to the user profile folder by default. Attach and send reports via e-mail.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -UseInteractiveAuth -Format Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -SendEmail

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using token authentication. Obtain token from Azure CLI and pass AccountId via TokenParameters. Export report to HTML format. Reports are saved to 'C:\Users\Tim\Documents'.
PS C:\> $Token = (az account get-access-token --resource https://management.azure.com --query accessToken -o tsv)
PS C:\> $AccountId = (az account show --query user.name -o tsv)
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Token $Token -TokenParameters @{AccountId=$AccountId} -Format Html -OutputFolderPath 'C:\Users\Tim\Documents'

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using token authentication with Az PowerShell. Enable health checks and append timestamp to filename. Export to Word & HTML formats.
PS C:\> Connect-AzAccount
PS C:\> $Token = (Get-AzAccessToken -ResourceUrl "https://management.azure.com").Token
PS C:\> $AccountId = (Get-AzContext).Account.Id
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Token $Token -TokenParameters @{AccountId=$AccountId} -Format Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -Timestamp -EnableHealthCheck
```
