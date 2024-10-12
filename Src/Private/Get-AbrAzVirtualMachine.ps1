function Get-AbrAzVirtualMachine {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Machine information from the Azure subscription
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "VirtualMachine InfoLevel set at $($InfoLevel.VirtualMachine)."
    }

    process {
        Try {
            if ($InfoLevel.VirtualMachine -gt 0) {
                $AzVMs = Get-AzVM -Status | Where-Object { $_.id.split('/')[2] -eq $AzSubscription.Id } | Sort-Object Name
                if ($AzVMs) {
                    Write-PScriboMessage "Collecting Azure VM information."
                    Section -Style Heading4 'Virtual Machines' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "Azure virtual machines are one of several types of on-demand, scalable computing resources that Azure offers. Typically, you choose a virtual machine when you need more control over the computing environment than the other choices offer. An Azure virtual machine gives you the flexibility of virtualization without having to buy and maintain the physical hardware that runs it. However, you still need to maintain the virtual machine by performing tasks, such as configuring, patching, and installing the software that runs on it."
                            BlankLine
                        }
                        $AzVMInfo = @()
                        foreach ($AzVM in $AzVMs) {
                            $AzVMSize = Get-AzVMSize -Location $AzVm.Location | Where-Object { $_.Name -eq $AzVm.HardwareProfile.VmSize }
                            $AzVmNic = Get-AzNetworkInterface | Where-Object { $_.VirtualMachine.Id -eq $AzVm.id }
                            $AzVmBackupStatus = Get-AzRecoveryServicesBackupStatus -Name $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName -Type "AzureVM" -ErrorAction SilentlyContinue
                            $AzVmExtensions = Get-AzVMExtension -VMName $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName | Sort-Object Name
                            $AzVmDiskEncryption = Get-AzVMDiskEncryptionStatus -ResourceGroupName $AzVm.ResourceGroupName -VMName $AzVm.Name
                            $InObj = [Ordered]@{
                                'Name' = $AzVM.Name
                                'Resource Group' = $AzVM.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzVm.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzVm.Id).split('/')[2]))"
                                'Status' = Switch ($AzVm.PowerState) {
                                    'Vm deallocated' { 'Deallocated' }
                                    'Vm running' { 'Running' }
                                    default { $AzVm.PowerState }
                                }
                                'Private IP Address' = $AzVmNic.IpConfigurations.PrivateIpAddress
                                'Private IP Assignment' = $AzVmNic.IpConfigurations.PrivateIpAllocationMethod
                                'Virtual Network / Subnet' = ($AzVmNic.IpConfigurations.Subnet.Id).split('/')[4] + " / " + ($AzVmNic.IpConfigurations.Subnet.Id).split('/')[-1]
                                'OS Type' = $AzVm.StorageProfile.OsDisk.OsType
                                'Size' = $AzVm.HardwareProfile.VmSize
                                'vCPUs' = $AzVMSize.NumberOfCores
                                'RAM' = "$($AzVMSize.MemoryInMB / 1024) GiB"
                                #'Operating System' = ''
                                'OS Disk' = ($AzVm.StorageProfile.OsDisk.Name)
                                'OS Disk Size' = if ($AzVm.StorageProfile.OsDisk.DiskSizeGB) {
                                    "$($AzVm.StorageProfile.OsDisk.DiskSizeGB) GiB"
                                } else {
                                    'Unknown'
                                }
                                'OS Disk Type' = Switch ($AzVm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType) {
                                    $null { '--' }
                                    'Standard_LRS' { 'Standard LRS' }
                                    'Premium_LRS' { 'Premium LRS' }
                                    'Premium_ZRS' { 'Premium ZRS' }
                                    'StandardSSD_LRS' { 'Standard SSD LRS' }
                                    'StandardSSD_ZRS' { 'Standard SSD ZRS' }
                                    'UltraSSD_LRS' { 'Ultra SSD LRS' }
                                }
                                'No. of Data Disks' = ($AzVm.StorageProfile.DataDisks).Count
                                'Azure Disk Encryption' = if ($AzVmDiskEncryption.OsVolumeEncryptionSettings.Enabled) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Boot Diagnostics' = & {
                                    if (($AzVM.DiagnosticsProfile.BootDiagnostics.Enabled) -and ($null -eq $AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri)) {
                                        'Enabled with managed storage account'
                                    } elseif (($AzVM.DiagnosticsProfile.BootDiagnostics.Enabled) -and ($AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri)) {
                                        'Enabled with custom storage account'
                                    } else {
                                        'Disabled'
                                    }
                                }
                                'Boot Diagnostics Storage Account' = if ($AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri) {
                                    $AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri.split('.')[0].trimstart('https://')
                                } else {
                                    'None'
                                }
                                'Azure Backup' = if ($AzVmBackupStatus.BackedUp) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Extensions' = & {
                                    if ($null -eq $AzVmExtensions.Name) {
                                        'None'
                                    } else { $AzVmExtensions.Name -join ', ' }
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzVm.Tags)) {
                                    'None'
                                } else {
                                    ($AzVm.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzVMInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.VirtualMachine.Status) {
                            $AzVMInfo | Where-Object { $_.'Status' -ne 'Running' } | Set-Style -Style Warning -Property 'Status'
                        }
                        if ($Healthcheck.VirtualMachine.BootDiagnostics) {
                            $AzVMInfo | Where-Object { $_.'Boot Diagnostics' -ne 'Enabled with custom storage account' } | Set-Style -Style Warning -Property 'Boot Diagnostics'
                            $AzVMInfo | Where-Object { $_.'Boot Diagnostics' -eq 'Disabled' } | Set-Style -Style Critical -Property 'Boot Diagnostics'
                        }
                        if ($Healthcheck.VirtualMachine.BackupEnabled) {
                            $AzVMInfo | Where-Object { $_.'Azure Backup' -ne 'Enabled' } | Set-Style -Style Warning -Property 'Azure Backup'
                        }
                        if ($Healthcheck.VirtualMachine.DiskEncryption) {
                            $AzVMInfo | Where-Object { $_.'Azure Disk Encryption' -ne 'Enabled' } | Set-Style -Style Warning -Property 'Azure Disk Encryption'
                        }
                        if ($InfoLevel.VirtualMachine -ge 2) {
                            Paragraph "The following sections detail the configuration of the virtual machines within the $($AzSubscription.Name) subscription."
                            foreach ($AzVM in $AzVMInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzVM.Name)" {
                                    $TableParams = @{
                                        Name = "Virtual Machine - $($AzVM.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzVM | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph "The following table summarises the configuration of the virtual machines within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "Virtual Machines - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Resource Group', 'Location', 'Status', 'Private IP Address', 'OS Type'
                                ColumnWidths = 21, 23, 15, 13, 15, 13
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVMInfo | Table @TableParams
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}