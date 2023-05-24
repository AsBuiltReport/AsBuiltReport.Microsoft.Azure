<!-- ********** DO NOT EDIT THESE LINKS ********** -->
<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a>
            <img src='https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport/master/AsBuiltReport.png' width="8%" height="8%" /></a>
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
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>

<p align="center">
    <a href='https://ko-fi.com/B0B7DDGZ7' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
</p>
<!-- ********** DO NOT EDIT THESE LINKS ********** -->

# Microsoft Azure As Built Report

Microsoft Azure As Built Report is a PowerShell module which works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-sourced community project which utilises PowerShell to produce as-built documentation in multiple document formats for multiple vendors and technologies.

Please refer to the AsBuiltReport [website](https://www.asbuiltreport.com) for more detailed information about this project.

The Microsoft Azure As Built Report currently supports reporting for the following Azure resources;

* Availability Sets
* Bastion Hosts
* ExpressRoute Circuits
* Firewalls
* IP Groups
* Key Vaults
* Load Balancers
* Policies
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
## :wrench: System Requirements
<!-- ********** Update system requirements ********** -->
PowerShell 5.1 or PowerShell 7, and the following PowerShell modules are required for generating a Microsoft Azure As Built Report.

- [Microsoft Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure)
- [AsBuiltReport.Microsoft.Azure Module](https://www.powershellgallery.com/packages/AsBuiltReport.Microsoft.Azure/)

### :closed_lock_with_key: Required Privileges
<!-- ********** Define required privileges ********** -->
<!-- ********** Try to follow best practices to define least privileges ********** -->

The Microsoft Azure as built report requires an Azure AD account. This report will not work with personal Azure accounts.

The least privileged roles required to generate a Microsoft Azure As Built Report are;
* Reader
* Backup Reader

## :package: Module Installation

### PowerShell
<!-- ********** Add installation for any additional PowerShell module(s) ********** -->
Open a PowerShell terminal window and install each of the required modules.

:warning: Microsoft Az 9.4.0 or higher is required. Please ensure older Az modules have been uninstalled.

```powershell
install-module Az -MinimumVersion 9.4.0
install-module AsBuiltReport.Microsoft.Azure
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

| Sub-Schema          | Setting      | Default                         | Description                                                  |
|---------------------|--------------|---------------------------------|--------------------------------------------------------------|
| Name                | User defined | Microsoft Azure As Built Report | The name of the As Built Report                              |
| Version             | User defined | 1.0                             | The report version                                           |
| Status              | User defined | Released                        | The report release status                                    |
| ShowCoverPageImage  | true / false | true                            | Toggle to enable/disable the display of the cover page image |
| ShowTableOfContents | true / false | true                            | Toggle to enable/disable table of contents                   |
| ShowHeaderFooter    | true / false | true                            | Toggle to enable/disable document headers & footers          |
| ShowTableCaptions   | true / false | true                            | Toggle to enable/disable table captions/numbering            |

### Options
The **Options** schema allows certain options within the report to be toggled on or off.

| Sub-Schema         | Setting      | Default | Description                                                                                                                                                                              |
|--------------------|--------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| ShowSectionInfo | true / false | true | Toggle to enable/disable information relating to Azure resources within each section. |

### Filter
The **Filter** schema allows report content to be filtered to specific Azure subscriptions within a tenant.

| Sub-Schema   | Setting      | Default | Description                                                                                                                                                                  |
|--------------|--------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
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

There are 4 levels (0-3) of detail granularity for each section as follows;

| Setting | InfoLevel         | Description                                                                                        |
|:-------:|-------------------|----------------------------------------------------------------------------------------------------|
|    0    | Disabled          | Does not collect or display any information                                                        |
|    1    | Enabled / Summary | Provides summarised information for a collection of objects                                        |
|    2    | Detailed          | Provides detailed information for individual objects                                               |
|    3    | Comprehensive     | Provides comprehensive information for individual objects, such as advanced configuration settings |

The table below outlines the default and maximum **InfoLevel** settings for each section.

| Sub-Schema            | Default Setting | Maximum Setting |
|-----------------------|:---------------:|:---------------:|
| AvailabilitySet       |        1        |        1        |
| Bastion               |        1        |        2        |
| ExpressRoute          |        1        |        2        |
| Firewall              |        1        |        3        |
| IpGroup               |        1        |        2        |
| KeyVault              |        1        |        1        |
| LoadBalancer          |        1        |        2        |
| PolicyAssignment      |        1        |        1        |
| RecoveryServicesVault |        1        |        2        |
| SiteRecovery          |        1        |        1        |
| StorageAccount        |        1        |        2        |
| VirtualNetwork        |        1        |        2        |
| VirtualMachine        |        1        |        2        |

### Healthcheck
The **Healthcheck** schema is used to toggle health checks on or off.

#### ExpressRoute
The **ExpressRoute** schema is used to configure health checks for Azure ExpressRoute.

| Sub-Schema    | Setting      | Default | Description | Highlight                                                                                         |
|---------------|--------------|---------|-------------|---------------------------------------------------------------------------------------------------|
| CircuitStatus | true / false | true    | Highlights ExpressRoute circuits which are not enabled | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) ExpressRoute circuit is not enabled |

#### SiteRecovery
The **SiteRecovery** schema is used to configure health checks for Azure Site Recovery.

| Sub-Schema        | Setting      | Default | Description | Highlight                                                                                               |
|-------------------|--------------|---------|-------------|---------------------------------------------------------------------------------------------------------|
| ReplicationHealth | true / false | true    |  Highlights replicated items which are in a critical state | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) Replication health is in a critical state |
| FailoverHealth    | true / false | true    |  Highlights the failover health status of replicated items | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) A successful test failover has not been performed on the replicated item |

#### StorageAccount
The **StorageAccount** schema is used to configure health checks for Azure Storage Account.

| Sub-Schema             | Setting      | Default | Description | Highlight                                                                                          |
|------------------------|--------------|---------|-------------|----------------------------------------------------------------------------------------------------|
| ProvisioningState      | true / false | true    |             | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) Provisioning is in a critical state  |
| EnableHttpsTrafficOnly | true / false | true    |             | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png)                                       |
| PublicNetworkAccess    | true / false | true    |             | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png)                                       |
| MinimumTlsVersion      | true / false | true    |             | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png)                                       |

#### VirtualMachine
The **VirtualMachine** schema is used to configure health checks for Azure Virtual Machines.

| Sub-Schema      | Setting      | Default | Description                                                                             | Highlight                                                                                                                                                                                                               |
|-----------------|--------------|---------|-----------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Status          | true / false | true    | Highlights VMs which are not in a running state                                         | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) VM is in a deallocated state                                                                                                                               |
| DiskEncryption  | true / false | true    | Highlights VMs which do not have disk encryption enabled                                | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) Disk encryption is not enabled                                                                                                                             |
| BootDiagnostics | true / false | true    | Highlights VMs which do not have boot diagnostics enabled with a custom storage account | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) Boot diagnostics is disabled <br> ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) Boot diagnostics is enabled with a managed storage account |
| BackupEnabled   | true / false | true    | Highlights VMs which do not have Azure Backup enabled                                   | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) Backup is disabled                                                                                                                                         |
## :computer: Examples
<!-- ********** Add some examples. Use other AsBuiltReport modules as a guide. ********** -->

```powershell
# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using multifactor authentication. Export report to HTML & DOCX formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Tim\Documents'
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -MFA -Format Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -Timestamp

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using specified credentials and report configuration file. Export report to Text, HTML & DOCX formats. Use default report style. Save reports to 'C:\Users\Tim\Documents'. Display verbose messages to the console.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Username 'tim@acme.com' -Password 'MyP@ssw0rd!' -Format Text,Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -ReportConfigFilePath 'C:\Users\Tim\AsBuiltReport\AsBuiltReport.Microsoft.Azure.json' -Verbose

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Tim\Documents'.
PS C:\> $Creds = Get-Credential
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Credential $Creds -Format Html,Text -OutputFolderPath 'C:\Users\Tim\Documents' -EnableHealthCheck

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using specified credentials. Report exports to WORD format by default. Apply custom style to the report. Reports are saved to the user profile folder by default.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -Username 'joe@acme.com' -Password 'MyP@ssw0rd!' -StyleFilePath 'C:\Scripts\Styles\MyCustomStyle.ps1'

# Generate a Microsoft Azure As Built Report for Tenant ID '555fff88-777d-1234-987a-23bc67890z5' using multifactor authentication. Export report to HTML & DOCX formats. Use default report style. Reports are saved to the user profile folder by default. Attach and send reports via e-mail.
PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target '555fff88-777d-1234-987a-23bc67890z5' -MFA -Format Html,Word -OutputFolderPath 'C:\Users\Tim\Documents' -SendEmail
```
