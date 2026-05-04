function Get-AbrAzNetAppFiles {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure NetApp Files information
    .DESCRIPTION
        Documents the configuration of Azure NetApp Files including NetApp Accounts,
        Capacity Pools, Volumes, Snapshots, Snapshot Policies, and Backup Policies.
    .NOTES
        Version:        0.1.0
        Author:         Scott Eno
        Github:         cse-gh
    .EXAMPLE

    .LINK

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'The Azure service is named "Azure NetApp Files" (plural); Az.NetAppFiles uses the same plural prefix.')]
    [CmdletBinding()]
    param (
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzNetAppFiles
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.NetAppFiles)
    }

    process {
        Try {
            if ($InfoLevel.NetAppFiles -gt 0) {
                $AzAnfAccounts = Get-AzNetAppFilesAccount | Sort-Object Name
                if ($AzAnfAccounts) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        # Cache pools and volumes per-account to avoid repeat API calls
                        $AccountMap = @{}
                        foreach ($NetAppAccount in $AzAnfAccounts) {
                            $AcctRg = $NetAppAccount.Id.Split('/')[4]
                            $AcctPools = @(Get-AzNetAppFilesPool -ResourceGroupName $AcctRg -AccountName $NetAppAccount.Name -ErrorAction SilentlyContinue | Sort-Object Name)
                            $AcctPoolVolMap = @{}
                            foreach ($CapacityPool in $AcctPools) {
                                $PoolShortName = $CapacityPool.Name.Split('/')[-1]
                                $AcctPoolVolMap[$PoolShortName] = @(Get-AzNetAppFilesVolume -ResourceGroupName $AcctRg -AccountName $NetAppAccount.Name -PoolName $PoolShortName -ErrorAction SilentlyContinue | Sort-Object Name)
                            }
                            $AccountMap[$NetAppAccount.Name] = @{
                                Pools = $AcctPools
                                Volumes = $AcctPoolVolMap
                                ResourceGroup = $AcctRg
                            }
                        }

                        #region NetApp Accounts
                        Section -Style Heading5 $LocalizedData.AccountsHeading {
                            Paragraph ($LocalizedData.AccountsSummary -f $AzSubscription.Name)
                            BlankLine

                            $AzAccountInfo = @()
                            foreach ($NetAppAccount in $AzAnfAccounts) {
                                $KeySourceDisplay = if ($NetAppAccount.Encryption -and $NetAppAccount.Encryption.KeySource -eq 'Microsoft.KeyVault') {
                                    $LocalizedData.CustomerManaged
                                } else {
                                    $LocalizedData.PlatformManaged
                                }
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name = $NetAppAccount.Name
                                    $LocalizedData.ResourceGroup = $NetAppAccount.ResourceGroupName
                                    $LocalizedData.Location = $AzLocationLookup."$($NetAppAccount.Location)"
                                    $LocalizedData.ProvisioningState = $NetAppAccount.ProvisioningState
                                    $LocalizedData.EncryptionKeySource = $KeySourceDisplay
                                }

                                if ($Options.ShowTags) {
                                    $InObj[$LocalizedData.Tags] = if ($null -eq $NetAppAccount.Tags -or $NetAppAccount.Tags.Count -eq 0) {
                                        $LocalizedData.None
                                    } else {
                                        ($NetAppAccount.Tags.Keys | ForEach-Object { "$_`:`t$($NetAppAccount.Tags[$_])" }) -join [Environment]::NewLine
                                    }
                                }

                                $AzAccountInfo += [PSCustomObject]$InObj
                            }

                            if ($Healthcheck.NetAppFiles.CustomerManagedKey) {
                                $AzAccountInfo | Where-Object { $_.$($LocalizedData.EncryptionKeySource) -eq $LocalizedData.PlatformManaged } | Set-Style -Style Info -Property $LocalizedData.EncryptionKeySource
                            }

                            if ($InfoLevel.NetAppFiles -ge 2) {
                                # Per-account detail: AD + encryption
                                foreach ($NetAppAccount in $AzAnfAccounts) {
                                    $AcctDetail = $AzAccountInfo | Where-Object { $_.$($LocalizedData.Name) -eq $NetAppAccount.Name }
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "$($NetAppAccount.Name)" {
                                        $TableParams = @{
                                            Name = "NetApp Account - $($NetAppAccount.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $AcctDetail | Table @TableParams

                                        # Active Directory configurations
                                        if ($NetAppAccount.ActiveDirectories -and $NetAppAccount.ActiveDirectories.Count -gt 0) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ActiveDirectoryHeading {
                                                $AdInfo = @()
                                                foreach ($Ad in $NetAppAccount.ActiveDirectories) {
                                                    $AdObj = [Ordered]@{
                                                        $LocalizedData.Domain = if ($Ad.Domain) { $Ad.Domain } else { '--' }
                                                        $LocalizedData.Username = if ($Ad.Username) { $Ad.Username } else { '--' }
                                                        $LocalizedData.Site = if ($Ad.Site) { $Ad.Site } else { '--' }
                                                        $LocalizedData.OrganizationalUnit = if ($Ad.OrganizationalUnit) { $Ad.OrganizationalUnit } else { '--' }
                                                        $LocalizedData.SmbServerName = if ($Ad.SmbServerName) { $Ad.SmbServerName } else { '--' }
                                                        $LocalizedData.DnsServers = if ($Ad.Dns) { $Ad.Dns } else { '--' }
                                                        $LocalizedData.AesEncryption = if ($Ad.AesEncryption) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                        $LocalizedData.LdapSigning = if ($Ad.LdapSigning) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                        $LocalizedData.EncryptDCConnection = if ($Ad.EncryptDCConnections) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                        $LocalizedData.AllowLocalNfsUsersWithLdap = if ($Ad.AllowLocalNfsUsersWithLdap) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                        $LocalizedData.Status = if ($Ad.Status) { $Ad.Status } else { '--' }
                                                    }
                                                    $AdInfo += [PSCustomObject]$AdObj
                                                }

                                                if ($Healthcheck.NetAppFiles.AdHealth) {
                                                    $AdInfo | Where-Object { $_.$($LocalizedData.Status) -and $_.$($LocalizedData.Status) -ne $LocalizedData.InUse } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                }

                                                $TableParams = @{
                                                    Name = "Active Directory - $($NetAppAccount.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $AdInfo | Table @TableParams
                                            }
                                        }

                                        # Encryption detail if customer-managed
                                        if ($NetAppAccount.Encryption -and $NetAppAccount.Encryption.KeySource -eq 'Microsoft.KeyVault') {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.EncryptionHeading {
                                                $EncObj = [Ordered]@{
                                                    $LocalizedData.EncryptionKeySource = $LocalizedData.CustomerManaged
                                                    $LocalizedData.EncryptionKeyVault = if ($NetAppAccount.Encryption.KeyVaultProperties -and $NetAppAccount.Encryption.KeyVaultProperties.KeyVaultUri) { $NetAppAccount.Encryption.KeyVaultProperties.KeyVaultUri } else { '--' }
                                                    $LocalizedData.EncryptionKeyName = if ($NetAppAccount.Encryption.KeyVaultProperties -and $NetAppAccount.Encryption.KeyVaultProperties.KeyName) { $NetAppAccount.Encryption.KeyVaultProperties.KeyName } else { '--' }
                                                }
                                                $TableParams = @{
                                                    Name = "Encryption - $($NetAppAccount.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                [PSCustomObject]$EncObj | Table @TableParams
                                            }
                                        }
                                    }
                                }
                            } else {
                                $TableParams = @{
                                    Name = "NetApp Accounts - $($AzSubscription.Name)"
                                    List = $false
                                    Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.ProvisioningState, $LocalizedData.EncryptionKeySource
                                    ColumnWidths = 25, 20, 15, 15, 25
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzAccountInfo | Table @TableParams
                            }
                        }
                        #endregion NetApp Accounts

                        #region Capacity Pools
                        $AllPools = @()
                        foreach ($NetAppAccount in $AzAnfAccounts) {
                            $AllPools += $AccountMap[$NetAppAccount.Name].Pools
                        }
                        if ($AllPools) {
                            Section -Style Heading5 $LocalizedData.PoolsHeading {
                                Paragraph ($LocalizedData.PoolsSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzPoolInfo = @()
                                foreach ($NetAppAccount in $AzAnfAccounts) {
                                    foreach ($CapacityPool in $AccountMap[$NetAppAccount.Name].Pools) {
                                        $PoolShortName = $CapacityPool.Name.Split('/')[-1]
                                        $PoolVols = $AccountMap[$NetAppAccount.Name].Volumes[$PoolShortName]
                                        $AllocatedBytes = 0
                                        if ($PoolVols) {
                                            $AllocatedBytes = ($PoolVols | Measure-Object -Property UsageThreshold -Sum).Sum
                                            if ($null -eq $AllocatedBytes) { $AllocatedBytes = 0 }
                                        }
                                        $PoolSizeGiB = [math]::Round($CapacityPool.Size / 1GB, 0)
                                        $AllocatedGiB = [math]::Round($AllocatedBytes / 1GB, 0)
                                        $PercentAllocated = if ($CapacityPool.Size -gt 0) { [math]::Round(($AllocatedBytes / $CapacityPool.Size) * 100, 1) } else { 0 }

                                        $InObj = [Ordered]@{
                                            $LocalizedData.Name = $PoolShortName
                                            $LocalizedData.Account = $NetAppAccount.Name
                                            $LocalizedData.ResourceGroup = $CapacityPool.ResourceGroupName
                                            $LocalizedData.Location = $AzLocationLookup."$($CapacityPool.Location)"
                                            $LocalizedData.ServiceLevel = $CapacityPool.ServiceLevel
                                            $LocalizedData.QosType = $CapacityPool.QosType
                                            $LocalizedData.SizeTiB = [math]::Round($CapacityPool.Size / 1TB, 2)
                                            $LocalizedData.VolumeCount = if ($PoolVols) { $PoolVols.Count } else { 0 }
                                            $LocalizedData.AllocatedGiB = $AllocatedGiB
                                            $LocalizedData.PercentAllocated = $PercentAllocated
                                            $LocalizedData.TotalThroughput = if ($null -ne $CapacityPool.TotalThroughputMibps) { $CapacityPool.TotalThroughputMibps } else { '--' }
                                            $LocalizedData.UtilizedThroughput = if ($null -ne $CapacityPool.UtilizedThroughputMibps) { $CapacityPool.UtilizedThroughputMibps } else { '--' }
                                            $LocalizedData.CoolAccess = if ($CapacityPool.CoolAccess) { $LocalizedData.Yes } else { $LocalizedData.No }
                                            $LocalizedData.EncryptionType = if ($CapacityPool.EncryptionType) { $CapacityPool.EncryptionType } else { '--' }
                                            $LocalizedData.ProvisioningState = $CapacityPool.ProvisioningState
                                        }

                                        if ($Options.ShowTags) {
                                            $InObj[$LocalizedData.Tags] = if ($null -eq $CapacityPool.Tags -or $CapacityPool.Tags.Count -eq 0) {
                                                $LocalizedData.None
                                            } else {
                                                ($CapacityPool.Tags.Keys | ForEach-Object { "$_`:`t$($CapacityPool.Tags[$_])" }) -join [Environment]::NewLine
                                            }
                                        }

                                        $AzPoolInfo += [PSCustomObject]$InObj

                                        # Health check: pool near allocation limit
                                        if ($Healthcheck.NetAppFiles.PoolCapacity -and $PercentAllocated -ge 85) {
                                            Paragraph ($LocalizedData.WarningPoolAllocation -f $PoolShortName, $PercentAllocated, $AllocatedGiB, $PoolSizeGiB) -Bold
                                        }
                                    }
                                }

                                if ($Healthcheck.NetAppFiles.PoolCapacity) {
                                    $AzPoolInfo | Where-Object { [double]$_.$($LocalizedData.PercentAllocated) -ge 85 } | Set-Style -Style Warning -Property $LocalizedData.PercentAllocated
                                }

                                if ($InfoLevel.NetAppFiles -ge 2) {
                                    foreach ($NetAppAccount in $AzAnfAccounts) {
                                        foreach ($CapacityPool in $AccountMap[$NetAppAccount.Name].Pools) {
                                            $PoolShortName = $CapacityPool.Name.Split('/')[-1]
                                            $PoolDetail = $AzPoolInfo | Where-Object { $_.$($LocalizedData.Name) -eq $PoolShortName -and $_.$($LocalizedData.Account) -eq $NetAppAccount.Name }
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC "$($NetAppAccount.Name) / $PoolShortName" {
                                                $TableParams = @{
                                                    Name = "Capacity Pool - $PoolShortName"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $PoolDetail | Table @TableParams
                                            }
                                        }
                                    }
                                } else {
                                    $TableParams = @{
                                        Name = "Capacity Pools - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.Account, $LocalizedData.ServiceLevel, $LocalizedData.QosType, $LocalizedData.SizeTiB, $LocalizedData.VolumeCount, $LocalizedData.PercentAllocated
                                        ColumnWidths = 18, 18, 12, 10, 12, 10, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzPoolInfo | Table @TableParams
                                }
                            }
                        }
                        #endregion Capacity Pools

                        #region Volumes
                        $AllVolumes = @()
                        foreach ($NetAppAccount in $AzAnfAccounts) {
                            foreach ($PoolShortName in $AccountMap[$NetAppAccount.Name].Volumes.Keys) {
                                $AllVolumes += $AccountMap[$NetAppAccount.Name].Volumes[$PoolShortName]
                            }
                        }
                        if ($AllVolumes) {
                            Section -Style Heading5 $LocalizedData.VolumesHeading {
                                Paragraph ($LocalizedData.VolumesSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzVolInfo = @()
                                foreach ($Volume in $AllVolumes) {
                                    $VolShortName = $Volume.Name.Split('/')[-1]
                                    $ParentAccount = $Volume.Name.Split('/')[0]
                                    $ParentPool = $Volume.Name.Split('/')[1]
                                    $SnapPolName = if ($Volume.DataProtection -and $Volume.DataProtection.Snapshot -and $Volume.DataProtection.Snapshot.SnapshotPolicyId) {
                                        $Volume.DataProtection.Snapshot.SnapshotPolicyId.Split('/')[-1]
                                    } else {
                                        $LocalizedData.NoPolicy
                                    }
                                    $BackupPolName = if ($Volume.DataProtection -and $Volume.DataProtection.Backup -and $Volume.DataProtection.Backup.BackupPolicyId) {
                                        $Volume.DataProtection.Backup.BackupPolicyId.Split('/')[-1]
                                    } else {
                                        $LocalizedData.NoPolicy
                                    }

                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $VolShortName
                                        $LocalizedData.Account = $ParentAccount
                                        $LocalizedData.Pool = $ParentPool
                                        $LocalizedData.ServiceLevel = $Volume.ServiceLevel
                                        $LocalizedData.QuotaGiB = [math]::Round($Volume.UsageThreshold / 1GB, 0)
                                        $LocalizedData.Protocol = ($Volume.ProtocolTypes -join ', ')
                                        $LocalizedData.SnapshotPolicy = $SnapPolName
                                        $LocalizedData.BackupPolicy = $BackupPolName
                                        $LocalizedData.VolumeType = if ($Volume.VolumeType) { $Volume.VolumeType } else { 'Regular' }
                                        $LocalizedData.ProvisioningState = $Volume.ProvisioningState
                                    }

                                    if ($Options.ShowTags) {
                                        $InObj[$LocalizedData.Tags] = if ($null -eq $Volume.Tags -or $Volume.Tags.Count -eq 0) {
                                            $LocalizedData.None
                                        } else {
                                            ($Volume.Tags.Keys | ForEach-Object { "$_`:`t$($Volume.Tags[$_])" }) -join [Environment]::NewLine
                                        }
                                    }

                                    $AzVolInfo += [PSCustomObject]$InObj
                                }

                                if ($Healthcheck.NetAppFiles.SnapshotPolicy) {
                                    $AzVolInfo | Where-Object { $_.$($LocalizedData.SnapshotPolicy) -eq $LocalizedData.NoPolicy } | Set-Style -Style Info -Property $LocalizedData.SnapshotPolicy
                                }
                                if ($Healthcheck.NetAppFiles.BackupProtection) {
                                    $AzVolInfo | Where-Object { $_.$($LocalizedData.BackupPolicy) -eq $LocalizedData.NoPolicy } | Set-Style -Style Info -Property $LocalizedData.BackupPolicy
                                }

                                if ($InfoLevel.NetAppFiles -ge 3) {
                                    # Per-volume vertical detail sections
                                    foreach ($Volume in $AllVolumes) {
                                        $VolShortName = $Volume.Name.Split('/')[-1]
                                        $ParentAccount = $Volume.Name.Split('/')[0]
                                        $ParentPool = $Volume.Name.Split('/')[1]
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$ParentAccount / $ParentPool / $VolShortName" {
                                            $SnapPolName = if ($Volume.DataProtection -and $Volume.DataProtection.Snapshot -and $Volume.DataProtection.Snapshot.SnapshotPolicyId) {
                                                $Volume.DataProtection.Snapshot.SnapshotPolicyId.Split('/')[-1]
                                            } else {
                                                $LocalizedData.NoPolicy
                                            }
                                            $BackupPolName = if ($Volume.DataProtection -and $Volume.DataProtection.Backup -and $Volume.DataProtection.Backup.BackupPolicyId) {
                                                $Volume.DataProtection.Backup.BackupPolicyId.Split('/')[-1]
                                            } else {
                                                $LocalizedData.NoPolicy
                                            }
                                            $SubnetShort = if ($Volume.SubnetId) { $Volume.SubnetId.Split('/')[-1] } else { '--' }
                                            $ZoneDisplay = if ($Volume.Zones -and $Volume.Zones.Count -gt 0) { $Volume.Zones -join ', ' } elseif ($Volume.ProvisionedAvailabilityZone) { $Volume.ProvisionedAvailabilityZone } else { '--' }

                                            $VolDetail = [Ordered]@{
                                                $LocalizedData.Name = $VolShortName
                                                $LocalizedData.Account = $ParentAccount
                                                $LocalizedData.Pool = $ParentPool
                                                $LocalizedData.Location = $AzLocationLookup."$($Volume.Location)"
                                                $LocalizedData.ServiceLevel = $Volume.ServiceLevel
                                                $LocalizedData.VolumeType = if ($Volume.VolumeType) { $Volume.VolumeType } else { 'Regular' }
                                                $LocalizedData.Protocol = ($Volume.ProtocolTypes -join ', ')
                                                $LocalizedData.QuotaGiB = [math]::Round($Volume.UsageThreshold / 1GB, 0)
                                                $LocalizedData.Throughput = if ($null -ne $Volume.ThroughputMibps) { $Volume.ThroughputMibps } else { '--' }
                                                $LocalizedData.ActualThroughput = if ($null -ne $Volume.ActualThroughputMibps) { $Volume.ActualThroughputMibps } else { '--' }
                                                $LocalizedData.Subnet = $SubnetShort
                                                $LocalizedData.NetworkFeatures = if ($Volume.NetworkFeatures) { $Volume.NetworkFeatures } else { '--' }
                                                $LocalizedData.Zone = $ZoneDisplay
                                                $LocalizedData.SecurityStyle = if ($Volume.SecurityStyle) { $Volume.SecurityStyle } else { '--' }
                                                $LocalizedData.UnixPermission = if ($Volume.UnixPermission) { $Volume.UnixPermission } else { '--' }
                                                $LocalizedData.SnapshotPolicy = $SnapPolName
                                                $LocalizedData.BackupPolicy = $BackupPolName
                                                $LocalizedData.SnapshotDirVisible = if ($Volume.SnapshotDirectoryVisible) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.KerberosEnabled = if ($Volume.KerberosEnabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.LdapEnabled = if ($Volume.LdapEnabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.SmbEncryption = if ($Volume.SmbEncryption) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.SmbContinuouslyAvailable = if ($Volume.SmbContinuouslyAvailable) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.SmbAccessBasedEnumeration = if ($Volume.SmbAccessBasedEnumeration) { $Volume.SmbAccessBasedEnumeration } else { '--' }
                                                $LocalizedData.CoolAccess = if ($Volume.CoolAccess) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.CoolnessPeriod = if ($Volume.CoolAccess -and $null -ne $Volume.CoolnessPeriod) { $Volume.CoolnessPeriod } else { '--' }
                                                $LocalizedData.TieringPolicy = if ($Volume.CoolAccess -and $Volume.CoolAccessTieringPolicy) { $Volume.CoolAccessTieringPolicy } else { '--' }
                                                $LocalizedData.RetrievalPolicy = if ($Volume.CoolAccess -and $Volume.CoolAccessRetrievalPolicy) { $Volume.CoolAccessRetrievalPolicy } else { '--' }
                                                $LocalizedData.FileSystemId = if ($Volume.FileSystemId) { $Volume.FileSystemId } else { '--' }
                                                $LocalizedData.ProvisioningState = $Volume.ProvisioningState
                                            }
                                            $VolObj = [PSCustomObject]$VolDetail
                                            if ($Healthcheck.NetAppFiles.SnapshotPolicy) {
                                                $VolObj | Where-Object { $_.$($LocalizedData.SnapshotPolicy) -eq $LocalizedData.NoPolicy } | Set-Style -Style Info -Property $LocalizedData.SnapshotPolicy
                                            }
                                            if ($Healthcheck.NetAppFiles.BackupProtection) {
                                                $VolObj | Where-Object { $_.$($LocalizedData.BackupPolicy) -eq $LocalizedData.NoPolicy } | Set-Style -Style Info -Property $LocalizedData.BackupPolicy
                                            }
                                            $TableParams = @{
                                                Name = "Volume - $VolShortName"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $VolObj | Table @TableParams

                                            # Mount Targets
                                            if ($Volume.MountTargets -and $Volume.MountTargets.Count -gt 0) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.MountTargetsHeading {
                                                    $MtInfo = @()
                                                    foreach ($MountTarget in $Volume.MountTargets) {
                                                        $MtInfo += [PSCustomObject][Ordered]@{
                                                            $LocalizedData.IpAddress = if ($MountTarget.IPAddress) { $MountTarget.IPAddress } else { '--' }
                                                            $LocalizedData.SmbServerFqdn = if ($MountTarget.SmbServerFqdn) { $MountTarget.SmbServerFqdn } else { '--' }
                                                            $LocalizedData.FileSystemId = if ($MountTarget.FileSystemId) { $MountTarget.FileSystemId } else { '--' }
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Mount Targets - $VolShortName"
                                                        List = $false
                                                        ColumnWidths = 25, 40, 35
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $MtInfo | Table @TableParams
                                                }
                                            }

                                            # Export Policy Rules
                                            if ($Volume.ExportPolicy -and $Volume.ExportPolicy.Rules -and $Volume.ExportPolicy.Rules.Count -gt 0) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ExportPolicyHeading {
                                                    $EpInfo = @()
                                                    foreach ($Rule in ($Volume.ExportPolicy.Rules | Sort-Object RuleIndex)) {
                                                        $EpInfo += [PSCustomObject][Ordered]@{
                                                            $LocalizedData.RuleIndex = $Rule.RuleIndex
                                                            $LocalizedData.AllowedClients = if ($Rule.AllowedClients) { $Rule.AllowedClients } else { '--' }
                                                            $LocalizedData.Nfsv3 = if ($Rule.Nfsv3) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                            $LocalizedData.Nfsv41 = if ($Rule.Nfsv41) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                            $LocalizedData.UnixReadWrite = if ($Rule.UnixReadWrite) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                            $LocalizedData.UnixReadOnly = if ($Rule.UnixReadOnly) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                            $LocalizedData.HasRootAccess = if ($Rule.HasRootAccess) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                            $LocalizedData.ChownMode = if ($Rule.ChownMode) { $Rule.ChownMode } else { '--' }
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Export Policy - $VolShortName"
                                                        List = $false
                                                        ColumnWidths = 8, 30, 10, 10, 12, 12, 10, 8
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $EpInfo | Table @TableParams
                                                }
                                            }

                                            # Snapshots and Quota Rules (InfoLevel 4)
                                            if ($InfoLevel.NetAppFiles -ge 4) {
                                                $VolRg = $Volume.Id.Split('/')[4]
                                                $Snapshots = Get-AzNetAppFilesSnapshot -ResourceGroupName $VolRg -AccountName $ParentAccount -PoolName $ParentPool -VolumeName $VolShortName -ErrorAction SilentlyContinue | Sort-Object Created -Descending
                                                if ($Snapshots) {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SnapshotsHeading {
                                                        $SnapInfo = @()
                                                        foreach ($Snapshot in $Snapshots) {
                                                            $SnapInfo += [PSCustomObject][Ordered]@{
                                                                $LocalizedData.Name = $Snapshot.Name.Split('/')[-1]
                                                                $LocalizedData.Created = if ($Snapshot.Created) { ([datetime]$Snapshot.Created).ToString('yyyy-MM-dd HH:mm') } else { '--' }
                                                                $LocalizedData.ProvisioningState = if ($Snapshot.ProvisioningState) { $Snapshot.ProvisioningState } else { '--' }
                                                            }
                                                        }
                                                        $TableParams = @{
                                                            Name = "Snapshots - $VolShortName"
                                                            List = $false
                                                            ColumnWidths = 50, 30, 20
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $SnapInfo | Table @TableParams
                                                    }
                                                }

                                                $QuotaRules = Get-AzNetAppFilesVolumeQuotaRule -ResourceGroupName $VolRg -AccountName $ParentAccount -PoolName $ParentPool -VolumeName $VolShortName -ErrorAction SilentlyContinue
                                                if ($QuotaRules) {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.QuotaRulesHeading {
                                                        $QrInfo = @()
                                                        foreach ($QuotaRule in $QuotaRules) {
                                                            $QrInfo += [PSCustomObject][Ordered]@{
                                                                $LocalizedData.Name = $QuotaRule.Name.Split('/')[-1]
                                                                $LocalizedData.Type = $QuotaRule.QuotaType
                                                                $LocalizedData.AllowedClients = if ($QuotaRule.QuotaTarget) { $QuotaRule.QuotaTarget } else { '--' }
                                                                $LocalizedData.QuotaGiB = if ($QuotaRule.QuotaSizeInKiBs) { [math]::Round($QuotaRule.QuotaSizeInKiBs / (1024 * 1024), 2) } else { 0 }
                                                                $LocalizedData.ProvisioningState = if ($QuotaRule.ProvisioningState) { $QuotaRule.ProvisioningState } else { '--' }
                                                            }
                                                        }
                                                        $TableParams = @{
                                                            Name = "Quota Rules - $VolShortName"
                                                            List = $false
                                                            ColumnWidths = 25, 15, 30, 15, 15
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $QrInfo | Table @TableParams
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    $TableParams = @{
                                        Name = "Volumes - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.Account, $LocalizedData.Pool, $LocalizedData.Protocol, $LocalizedData.QuotaGiB, $LocalizedData.SnapshotPolicy, $LocalizedData.BackupPolicy
                                        ColumnWidths = 20, 14, 14, 10, 10, 16, 16
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzVolInfo | Table @TableParams
                                }
                            }
                        }
                        #endregion Volumes

                        #region Snapshot Policies (InfoLevel >= 3)
                        if ($InfoLevel.NetAppFiles -ge 3) {
                            $AllSnapPolicies = @()
                            foreach ($NetAppAccount in $AzAnfAccounts) {
                                $AcctRg = $AccountMap[$NetAppAccount.Name].ResourceGroup
                                $Policies = Get-AzNetAppFilesSnapshotPolicy -ResourceGroupName $AcctRg -AccountName $NetAppAccount.Name -ErrorAction SilentlyContinue
                                if ($Policies) {
                                    foreach ($Policy in $Policies) {
                                        $AllSnapPolicies += [PSCustomObject]@{
                                            Account = $NetAppAccount.Name
                                            Policy  = $Policy
                                        }
                                    }
                                }
                            }
                            if ($AllSnapPolicies) {
                                Section -Style Heading5 $LocalizedData.SnapshotPoliciesHeading {
                                    Paragraph ($LocalizedData.SnapshotPoliciesSummary -f $AzSubscription.Name)
                                    BlankLine

                                    foreach ($Item in $AllSnapPolicies) {
                                        $Policy = $Item.Policy
                                        $PolShortName = $Policy.Name.Split('/')[-1]
                                        $Hourly = if ($Policy.HourlySchedule -and $Policy.HourlySchedule.SnapshotsToKeep) { "Every hour at :$('{0:D2}' -f [int]$Policy.HourlySchedule.Minute), keep $($Policy.HourlySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }
                                        $Daily = if ($Policy.DailySchedule -and $Policy.DailySchedule.SnapshotsToKeep) { "At $('{0:D2}' -f [int]$Policy.DailySchedule.Hour):$('{0:D2}' -f [int]$Policy.DailySchedule.Minute), keep $($Policy.DailySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }
                                        $Weekly = if ($Policy.WeeklySchedule -and $Policy.WeeklySchedule.SnapshotsToKeep) { "$($Policy.WeeklySchedule.Day) at $('{0:D2}' -f [int]$Policy.WeeklySchedule.Hour):$('{0:D2}' -f [int]$Policy.WeeklySchedule.Minute), keep $($Policy.WeeklySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }
                                        $Monthly = if ($Policy.MonthlySchedule -and $Policy.MonthlySchedule.SnapshotsToKeep) { "Day(s) $($Policy.MonthlySchedule.DaysOfMonth) at $('{0:D2}' -f [int]$Policy.MonthlySchedule.Hour):$('{0:D2}' -f [int]$Policy.MonthlySchedule.Minute), keep $($Policy.MonthlySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }

                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Item.Account) / $PolShortName" {
                                            $SpObj = [PSCustomObject][Ordered]@{
                                                $LocalizedData.Name = $PolShortName
                                                $LocalizedData.Account = $Item.Account
                                                $LocalizedData.Enabled = if ($Policy.Enabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.HourlySchedule = $Hourly
                                                $LocalizedData.DailySchedule = $Daily
                                                $LocalizedData.WeeklySchedule = $Weekly
                                                $LocalizedData.MonthlySchedule = $Monthly
                                            }
                                            $TableParams = @{
                                                Name = "Snapshot Policy - $PolShortName"
                                                List = $true
                                                ColumnWidths = 30, 70
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $SpObj | Table @TableParams
                                        }
                                    }
                                }
                            }
                        }
                        #endregion Snapshot Policies

                        #region Backup Policies (InfoLevel >= 3)
                        if ($InfoLevel.NetAppFiles -ge 3) {
                            $AllBackupPolicies = @()
                            foreach ($NetAppAccount in $AzAnfAccounts) {
                                $AcctRg = $AccountMap[$NetAppAccount.Name].ResourceGroup
                                $Policies = Get-AzNetAppFilesBackupPolicy -ResourceGroupName $AcctRg -AccountName $NetAppAccount.Name -ErrorAction SilentlyContinue
                                if ($Policies) {
                                    foreach ($Policy in $Policies) {
                                        $AllBackupPolicies += [PSCustomObject]@{
                                            Account = $NetAppAccount.Name
                                            Policy  = $Policy
                                        }
                                    }
                                }
                            }
                            if ($AllBackupPolicies) {
                                Section -Style Heading5 $LocalizedData.BackupPoliciesHeading {
                                    Paragraph ($LocalizedData.BackupPoliciesSummary -f $AzSubscription.Name)
                                    BlankLine

                                    $BpInfo = @()
                                    foreach ($Item in $AllBackupPolicies) {
                                        $Policy = $Item.Policy
                                        $PolShortName = $Policy.Name.Split('/')[-1]
                                        $BpInfo += [PSCustomObject][Ordered]@{
                                            $LocalizedData.Name = $PolShortName
                                            $LocalizedData.Account = $Item.Account
                                            $LocalizedData.Enabled = if ($Policy.Enabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                            $LocalizedData.DailyBackups = if ($null -ne $Policy.DailyBackupsToKeep) { $Policy.DailyBackupsToKeep } else { 0 }
                                            $LocalizedData.WeeklyBackups = if ($null -ne $Policy.WeeklyBackupsToKeep) { $Policy.WeeklyBackupsToKeep } else { 0 }
                                            $LocalizedData.MonthlyBackups = if ($null -ne $Policy.MonthlyBackupsToKeep) { $Policy.MonthlyBackupsToKeep } else { 0 }
                                        }
                                    }
                                    $TableParams = @{
                                        Name = "Backup Policies - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.Account, $LocalizedData.Enabled, $LocalizedData.DailyBackups, $LocalizedData.WeeklyBackups, $LocalizedData.MonthlyBackups
                                        ColumnWidths = 25, 20, 10, 15, 15, 15
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $BpInfo | Table @TableParams
                                }
                            }
                        }
                        #endregion Backup Policies
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}
