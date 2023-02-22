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

* Availabity Sets
* Bastion Hosts
* Express Route Circuits
* Firewalls
* IP Groups
* Key Vaults
* Load Balancers
* Policies
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

### Filter
The **Filter** schema allows report content to be filtered to specific Azure subscriptions within a tenant.

| Sub-Schema   | Setting      | Default | Description                                                                                                                                                                  |
|--------------|--------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Subscription | User defined | *       | Filters report content to specific Azure subscriptions within a tenant. <br>Specifying an asterisk (*) will generate a report for all Azure subscriptions within the tenant. |

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
| VirtualNetwork        |        1        |        2        |
| VirtualMachine        |        1        |        2        |

### Healthcheck
The **Healthcheck** schema is used to toggle health checks on or off.

#### ExpressRoute
The **ExpressRoute** schema is used to configure health checks for Azure ExpressRoute.

| Sub-Schema    | Setting      | Default | Description | Highlight                                                                                         |
|---------------|--------------|---------|-------------|---------------------------------------------------------------------------------------------------|
| CircuitStatus | true / false | true    |             | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) ExpressRoute Circuit is not enabled |

#### SiteRecovery
The **SiteRecovery** schema is used to configure health checks for Azure Site Recovery.

| Sub-Schema        | Setting      | Default | Description | Highlight                                                                                               |
|-------------------|--------------|---------|-------------|---------------------------------------------------------------------------------------------------------|
| ReplicationHealth | true / false | true    |             | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) Replication Health is in a critical state |
| FailoverHealth    | true / false | true    |             | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png)                                            |

#### VirtualMachine
The **VirtualMachine** schema is used to configure health checks for Azure Virtual Machines.

| Sub-Schema      | Setting      | Default | Description                                                                             | Highlight                                                                                                                                                                                                               |
|-----------------|--------------|---------|-----------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Status          | true / false | true    | Highlights VMs which are not in a running state                                         | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) VM is in a deallocated state                                                                                                                               |
| DiskEncryption  | true / false | true    | Highlights VMs which do not have disk encryption enabled                                | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) Disk encryption is not enabled                                                                                                                             |
| BootDiagnostics | true / false | true    | Highlights VMs which do not have boot diagnostics enabled with a custom storage account | ![Critical](https://via.placeholder.com/15/FEDDD7/FEDDD7.png) Boot Diagnostics is disabled <br> ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) Boot diagnostics is enabled with a managed storage account |
| BackupEnabled   | true / false | true    | Highlights VMs which do not have Azure Backup enabled                                   | ![Warning](https://via.placeholder.com/15/FFF4C7/FFF4C7.png) Backup is disabled                                                                                                                                         |
## :computer: Examples
<!-- ********** Add some examples. Use other AsBuiltReport modules as a guide. ********** -->
