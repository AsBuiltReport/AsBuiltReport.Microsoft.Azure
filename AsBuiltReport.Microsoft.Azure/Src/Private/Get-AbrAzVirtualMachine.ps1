function Get-AbrAzVirtualMachine {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Machine information from the Azure subscription
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
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
        $LocalizedData = $reportTranslate.GetAbrAzVirtualMachine
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.VirtualMachine)
    }

    process {
        Try {
            if ($InfoLevel.VirtualMachine -gt 0) {
                $AzVMs = Get-AzVM -Status | Where-Object { $_.id.split('/')[2] -eq $AzSubscription.Id } | Sort-Object Name
                if ($AzVMs) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo1
                            BlankLine
                            Paragraph $LocalizedData.SectionInfo2
                        }
                        $AzVMInfo = @()
                        foreach ($AzVM in $AzVMs) {
                            $AzVMSize = Get-AzVMSize -VMName $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName | Where-Object { $_.Name -eq $AzVm.HardwareProfile.VmSize }
                            $AzVmNic = Get-AzNetworkInterface | Where-Object { $_.VirtualMachine.Id -eq $AzVm.id }
                            $AzVmBackupStatus = Get-AzRecoveryServicesBackupStatus -Name $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName -Type "AzureVM" -ErrorAction SilentlyContinue
                            $AzVmExtensions = Get-AzVMExtension -VMName $AzVm.Name -ResourceGroupName $AzVm.ResourceGroupName | Sort-Object Name
                            $AzVmDiskEncryption = Get-AzVMDiskEncryptionStatus -ResourceGroupName $AzVm.ResourceGroupName -VMName $AzVm.Name
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzVM.Name
                                $LocalizedData.ResourceGroup = $AzVM.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzVm.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzVm.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzVm.Id).split('/')[2]
                                $LocalizedData.Status = Switch ($AzVm.PowerState) {
                                    'Vm deallocated' { $LocalizedData.Deallocated }
                                    'Vm running' { $LocalizedData.Running }
                                    default { $AzVm.PowerState }
                                }
                                $LocalizedData.PrivateIPAddress = $AzVmNic.IpConfigurations.PrivateIpAddress
                                $LocalizedData.PrivateIPAssignment = $AzVmNic.IpConfigurations.PrivateIpAllocationMethod
                                $LocalizedData.VirtualNetworkSubnet = ($AzVmNic.IpConfigurations.Subnet.Id).split('/')[4] + " / " + ($AzVmNic.IpConfigurations.Subnet.Id).split('/')[-1]
                                $LocalizedData.OSType = $AzVm.StorageProfile.OsDisk.OsType
                                $LocalizedData.Size = $AzVm.HardwareProfile.VmSize
                                $LocalizedData.vCPUs = $AzVMSize.NumberOfCores
                                $LocalizedData.RAM = "$($AzVMSize.MemoryInMB / 1024) GiB"
                                $LocalizedData.OperatingSystem = & {
                                    $imageRef = $AzVm.StorageProfile.ImageReference
                                    if ($imageRef.Publisher -and $imageRef.Offer -and $imageRef.Sku) {
                                        switch ($imageRef.Publisher) {
                                            'MicrosoftWindowsServer' {
                                                switch ($imageRef.Sku) {
                                                    '2025-datacenter-azure-edition' { 'Windows Server 2025 Datacenter Azure Edition' }
                                                    '2025-datacenter-azure-edition-core' { 'Windows Server 2025 Datacenter Azure Edition Core' }
                                                    '2025-datacenter' { 'Windows Server 2025 Datacenter' }
                                                    '2025-datacenter-core' { 'Windows Server 2025 Datacenter Core' }
                                                    '2022-datacenter-azure-edition' { 'Windows Server 2022 Datacenter Azure Edition' }
                                                    '2022-datacenter-azure-edition-core' { 'Windows Server 2022 Datacenter Azure Edition Core' }
                                                    '2022-datacenter' { 'Windows Server 2022 Datacenter' }
                                                    '2022-datacenter-core' { 'Windows Server 2022 Datacenter Core' }
                                                    '2019-datacenter' { 'Windows Server 2019 Datacenter' }
                                                    '2019-datacenter-core' { 'Windows Server 2019 Datacenter Core' }
                                                    '2016-datacenter' { 'Windows Server 2016 Datacenter' }
                                                    '2016-datacenter-server-core' { 'Windows Server 2016 Datacenter Core' }
                                                    '2012-r2-datacenter' { 'Windows Server 2012 R2 Datacenter' }
                                                    default { "Windows Server $($imageRef.Sku)" }
                                                }
                                            }
                                            'MicrosoftWindowsDesktop' {
                                                "Windows Desktop $($imageRef.Sku)"
                                            }
                                            'Canonical' {
                                                if ($imageRef.Offer -eq 'UbuntuServer') {
                                                    "Ubuntu Server $($imageRef.Sku)"
                                                } else {
                                                    "Ubuntu $($imageRef.Sku)"
                                                }
                                            }
                                            'RedHat' {
                                                "Red Hat Enterprise Linux $($imageRef.Sku)"
                                            }
                                            'OpenLogic' {
                                                "CentOS $($imageRef.Sku)"
                                            }
                                            'SUSE' {
                                                if ($imageRef.Offer -eq 'SLES') {
                                                    "SUSE Linux Enterprise Server $($imageRef.Sku)"
                                                } else {
                                                    "SUSE $($imageRef.Offer) $($imageRef.Sku)"
                                                }
                                            }
                                            'Oracle' {
                                                "Oracle Linux $($imageRef.Sku)"
                                            }
                                            default {
                                                "$($imageRef.Publisher) $($imageRef.Offer) $($imageRef.Sku)"
                                            }
                                        }
                                    } elseif ($imageRef.Id) {
                                        $imageName = ($imageRef.Id -split '/')[-1]
                                        "$($LocalizedData.CustomImage) $imageName"
                                    } else {
                                        $LocalizedData.Unknown
                                    }
                                }
                                $LocalizedData.OSDisk = ($AzVm.StorageProfile.OsDisk.Name)
                                $LocalizedData.OSDiskSize = if ($AzVm.StorageProfile.OsDisk.DiskSizeGB) {
                                    "$($AzVm.StorageProfile.OsDisk.DiskSizeGB) GiB"
                                } else {
                                    $LocalizedData.Unknown
                                }
                                $LocalizedData.OSDiskType = Switch ($AzVm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType) {
                                    $null { '--' }
                                    'Standard_LRS' { 'Standard LRS' }
                                    'Premium_LRS' { 'Premium LRS' }
                                    'Premium_ZRS' { 'Premium ZRS' }
                                    'StandardSSD_LRS' { 'Standard SSD LRS' }
                                    'StandardSSD_ZRS' { 'Standard SSD ZRS' }
                                    'UltraSSD_LRS' { 'Ultra SSD LRS' }
                                    default { $AzVm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType }
                                }
                                $LocalizedData.NoOfDataDisks = ($AzVm.StorageProfile.DataDisks).Count
                                $LocalizedData.AzureDiskEncryption = if ($AzVmDiskEncryption.OsVolumeEncryptionSettings.Enabled) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.BootDiagnostics = & {
                                    if (($AzVM.DiagnosticsProfile.BootDiagnostics.Enabled) -and ($null -eq $AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri)) {
                                        $LocalizedData.managedstorageaccount
                                    } elseif (($AzVM.DiagnosticsProfile.BootDiagnostics.Enabled) -and ($AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri)) {
                                        $LocalizedData.customstorageaccount
                                    } else {
                                        $LocalizedData.Disabled
                                    }
                                }
                                $LocalizedData.BootDiagnosticsStorageAccount = if ($AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri) {
                                    $AzVM.DiagnosticsProfile.BootDiagnostics.StorageUri.split('.')[0].trimstart('https://')
                                } else {
                                    '--'
                                }
                                $LocalizedData.AzureBackup = if ($AzVmBackupStatus.BackedUp) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.Extensions = & {
                                    if ($null -eq $AzVmExtensions.Name) {
                                        '--'
                                    } else { $AzVmExtensions.Name -join ', ' }
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzVm.Tags)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzVm.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzVMInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.VirtualMachine.Status) {
                            $AzVMInfo | Where-Object { $_.($LocalizedData.Status) -ne $LocalizedData.Running } | Set-Style -Style Warning -Property $LocalizedData.Status
                        }
                        if ($Healthcheck.VirtualMachine.BootDiagnostics) {
                            $AzVMInfo | Where-Object { $_.($LocalizedData.BootDiagnostics) -ne $LocalizedData.customstorageaccount } | Set-Style -Style Warning -Property $LocalizedData.BootDiagnostics
                            $AzVMInfo | Where-Object { $_.($LocalizedData.BootDiagnostics) -eq $LocalizedData.Disabled } | Set-Style -Style Critical -Property $LocalizedData.BootDiagnostics
                        }
                        if ($Healthcheck.VirtualMachine.BackupEnabled) {
                            $AzVMInfo | Where-Object { $_.($LocalizedData.AzureBackup) -ne $LocalizedData.Enabled } | Set-Style -Style Warning -Property $LocalizedData.AzureBackup
                        }
                        if ($Healthcheck.VirtualMachine.DiskEncryption) {
                            $AzVMInfo | Where-Object { $_.($LocalizedData.AzureDiskEncryption) -ne $LocalizedData.Enabled } | Set-Style -Style Warning -Property $LocalizedData.AzureDiskEncryption
                        }
                        if ($InfoLevel.VirtualMachine -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzVM in $AzVMInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzVM.Name)" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzVM.Name)"
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
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Status, $LocalizedData.PrivateIPAddress, $LocalizedData.OSType
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