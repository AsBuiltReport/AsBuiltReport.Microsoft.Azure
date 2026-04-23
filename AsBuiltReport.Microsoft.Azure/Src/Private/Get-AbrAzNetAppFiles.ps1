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
                        foreach ($Acct in $AzAnfAccounts) {
                            $AcctRg = $Acct.Id.Split('/')[4]
                            $AcctPools = @(Get-AzNetAppFilesPool -ResourceGroupName $AcctRg -AccountName $Acct.Name -ErrorAction SilentlyContinue | Sort-Object Name)
                            $AcctPoolVolMap = @{}
                            foreach ($P in $AcctPools) {
                                $PoolShortName = $P.Name.Split('/')[-1]
                                $AcctPoolVolMap[$PoolShortName] = @(Get-AzNetAppFilesVolume -ResourceGroupName $AcctRg -AccountName $Acct.Name -PoolName $PoolShortName -ErrorAction SilentlyContinue | Sort-Object Name)
                            }
                            $AccountMap[$Acct.Name] = @{
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
                            foreach ($Acct in $AzAnfAccounts) {
                                $KeySourceDisplay = if ($Acct.Encryption -and $Acct.Encryption.KeySource -eq 'Microsoft.KeyVault') {
                                    $LocalizedData.CustomerManaged
                                } else {
                                    $LocalizedData.PlatformManaged
                                }
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name = $Acct.Name
                                    $LocalizedData.ResourceGroup = $Acct.ResourceGroupName
                                    $LocalizedData.Location = $AzLocationLookup."$($Acct.Location)"
                                    $LocalizedData.ProvisioningState = $Acct.ProvisioningState
                                    $LocalizedData.EncryptionKeySource = $KeySourceDisplay
                                }

                                if ($Options.ShowTags) {
                                    $InObj[$LocalizedData.Tags] = if ($null -eq $Acct.Tags -or $Acct.Tags.Count -eq 0) {
                                        $LocalizedData.None
                                    } else {
                                        ($Acct.Tags.Keys | ForEach-Object { "$_`:`t$($Acct.Tags[$_])" }) -join [Environment]::NewLine
                                    }
                                }

                                $AzAccountInfo += [PSCustomObject]$InObj
                            }

                            if ($Healthcheck.NetAppFiles.CustomerManagedKey) {
                                $AzAccountInfo | Where-Object { $_.$($LocalizedData.EncryptionKeySource) -eq $LocalizedData.PlatformManaged } | Set-Style -Style Info -Property $LocalizedData.EncryptionKeySource
                            }

                            if ($InfoLevel.NetAppFiles -ge 2) {
                                # Per-account detail: AD + encryption
                                foreach ($Acct in $AzAnfAccounts) {
                                    $AcctDetail = $AzAccountInfo | Where-Object { $_.$($LocalizedData.Name) -eq $Acct.Name }
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Acct.Name)" {
                                        $TableParams = @{
                                            Name = "NetApp Account - $($Acct.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $AcctDetail | Table @TableParams

                                        # Active Directory configurations
                                        if ($Acct.ActiveDirectories -and $Acct.ActiveDirectories.Count -gt 0) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ActiveDirectoryHeading {
                                                $AdInfo = @()
                                                foreach ($Ad in $Acct.ActiveDirectories) {
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
                                                    Name = "Active Directory - $($Acct.Name)"
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
                                        if ($Acct.Encryption -and $Acct.Encryption.KeySource -eq 'Microsoft.KeyVault') {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.EncryptionHeading {
                                                $EncObj = [Ordered]@{
                                                    $LocalizedData.EncryptionKeySource = $LocalizedData.CustomerManaged
                                                    $LocalizedData.EncryptionKeyVault = if ($Acct.Encryption.KeyVaultProperties -and $Acct.Encryption.KeyVaultProperties.KeyVaultUri) { $Acct.Encryption.KeyVaultProperties.KeyVaultUri } else { '--' }
                                                    $LocalizedData.EncryptionKeyName = if ($Acct.Encryption.KeyVaultProperties -and $Acct.Encryption.KeyVaultProperties.KeyName) { $Acct.Encryption.KeyVaultProperties.KeyName } else { '--' }
                                                }
                                                $TableParams = @{
                                                    Name = "Encryption - $($Acct.Name)"
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
                        foreach ($Acct in $AzAnfAccounts) {
                            $AllPools += $AccountMap[$Acct.Name].Pools
                        }
                        if ($AllPools) {
                            Section -Style Heading5 $LocalizedData.PoolsHeading {
                                Paragraph ($LocalizedData.PoolsSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzPoolInfo = @()
                                foreach ($Acct in $AzAnfAccounts) {
                                    foreach ($P in $AccountMap[$Acct.Name].Pools) {
                                        $PoolShortName = $P.Name.Split('/')[-1]
                                        $PoolVols = $AccountMap[$Acct.Name].Volumes[$PoolShortName]
                                        $AllocatedBytes = 0
                                        if ($PoolVols) {
                                            $AllocatedBytes = ($PoolVols | Measure-Object -Property UsageThreshold -Sum).Sum
                                            if ($null -eq $AllocatedBytes) { $AllocatedBytes = 0 }
                                        }
                                        $PoolSizeGiB = [math]::Round($P.Size / 1GB, 0)
                                        $AllocatedGiB = [math]::Round($AllocatedBytes / 1GB, 0)
                                        $PercentAllocated = if ($P.Size -gt 0) { [math]::Round(($AllocatedBytes / $P.Size) * 100, 1) } else { 0 }

                                        $InObj = [Ordered]@{
                                            $LocalizedData.Name = $PoolShortName
                                            $LocalizedData.Account = $Acct.Name
                                            $LocalizedData.ResourceGroup = $P.ResourceGroupName
                                            $LocalizedData.Location = $AzLocationLookup."$($P.Location)"
                                            $LocalizedData.ServiceLevel = $P.ServiceLevel
                                            $LocalizedData.QosType = $P.QosType
                                            $LocalizedData.SizeTiB = [math]::Round($P.Size / 1TB, 2)
                                            $LocalizedData.VolumeCount = if ($PoolVols) { $PoolVols.Count } else { 0 }
                                            $LocalizedData.AllocatedGiB = $AllocatedGiB
                                            $LocalizedData.PercentAllocated = $PercentAllocated
                                            $LocalizedData.TotalThroughput = if ($null -ne $P.TotalThroughputMibps) { $P.TotalThroughputMibps } else { '--' }
                                            $LocalizedData.UtilizedThroughput = if ($null -ne $P.UtilizedThroughputMibps) { $P.UtilizedThroughputMibps } else { '--' }
                                            $LocalizedData.CoolAccess = if ($P.CoolAccess) { $LocalizedData.Yes } else { $LocalizedData.No }
                                            $LocalizedData.EncryptionType = if ($P.EncryptionType) { $P.EncryptionType } else { '--' }
                                            $LocalizedData.ProvisioningState = $P.ProvisioningState
                                        }

                                        if ($Options.ShowTags) {
                                            $InObj[$LocalizedData.Tags] = if ($null -eq $P.Tags -or $P.Tags.Count -eq 0) {
                                                $LocalizedData.None
                                            } else {
                                                ($P.Tags.Keys | ForEach-Object { "$_`:`t$($P.Tags[$_])" }) -join [Environment]::NewLine
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
                                    foreach ($Acct in $AzAnfAccounts) {
                                        foreach ($P in $AccountMap[$Acct.Name].Pools) {
                                            $PoolShortName = $P.Name.Split('/')[-1]
                                            $PoolDetail = $AzPoolInfo | Where-Object { $_.$($LocalizedData.Name) -eq $PoolShortName -and $_.$($LocalizedData.Account) -eq $Acct.Name }
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Acct.Name) / $PoolShortName" {
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
                        foreach ($Acct in $AzAnfAccounts) {
                            foreach ($PoolShortName in $AccountMap[$Acct.Name].Volumes.Keys) {
                                $AllVolumes += $AccountMap[$Acct.Name].Volumes[$PoolShortName]
                            }
                        }
                        if ($AllVolumes) {
                            Section -Style Heading5 $LocalizedData.VolumesHeading {
                                Paragraph ($LocalizedData.VolumesSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzVolInfo = @()
                                foreach ($V in $AllVolumes) {
                                    $VolShortName = $V.Name.Split('/')[-1]
                                    $ParentAccount = $V.Name.Split('/')[0]
                                    $ParentPool = $V.Name.Split('/')[1]
                                    $SnapPolName = if ($V.DataProtection -and $V.DataProtection.Snapshot -and $V.DataProtection.Snapshot.SnapshotPolicyId) {
                                        $V.DataProtection.Snapshot.SnapshotPolicyId.Split('/')[-1]
                                    } else {
                                        $LocalizedData.NoPolicy
                                    }
                                    $BackupPolName = if ($V.DataProtection -and $V.DataProtection.Backup -and $V.DataProtection.Backup.BackupPolicyId) {
                                        $V.DataProtection.Backup.BackupPolicyId.Split('/')[-1]
                                    } else {
                                        $LocalizedData.NoPolicy
                                    }

                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $VolShortName
                                        $LocalizedData.Account = $ParentAccount
                                        $LocalizedData.Pool = $ParentPool
                                        $LocalizedData.ServiceLevel = $V.ServiceLevel
                                        $LocalizedData.QuotaGiB = [math]::Round($V.UsageThreshold / 1GB, 0)
                                        $LocalizedData.Protocol = ($V.ProtocolTypes -join ', ')
                                        $LocalizedData.SnapshotPolicy = $SnapPolName
                                        $LocalizedData.BackupPolicy = $BackupPolName
                                        $LocalizedData.VolumeType = if ($V.VolumeType) { $V.VolumeType } else { 'Regular' }
                                        $LocalizedData.ProvisioningState = $V.ProvisioningState
                                    }

                                    if ($Options.ShowTags) {
                                        $InObj[$LocalizedData.Tags] = if ($null -eq $V.Tags -or $V.Tags.Count -eq 0) {
                                            $LocalizedData.None
                                        } else {
                                            ($V.Tags.Keys | ForEach-Object { "$_`:`t$($V.Tags[$_])" }) -join [Environment]::NewLine
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
                                    foreach ($V in $AllVolumes) {
                                        $VolShortName = $V.Name.Split('/')[-1]
                                        $ParentAccount = $V.Name.Split('/')[0]
                                        $ParentPool = $V.Name.Split('/')[1]
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$ParentAccount / $ParentPool / $VolShortName" {
                                            $SnapPolName = if ($V.DataProtection -and $V.DataProtection.Snapshot -and $V.DataProtection.Snapshot.SnapshotPolicyId) {
                                                $V.DataProtection.Snapshot.SnapshotPolicyId.Split('/')[-1]
                                            } else {
                                                $LocalizedData.NoPolicy
                                            }
                                            $BackupPolName = if ($V.DataProtection -and $V.DataProtection.Backup -and $V.DataProtection.Backup.BackupPolicyId) {
                                                $V.DataProtection.Backup.BackupPolicyId.Split('/')[-1]
                                            } else {
                                                $LocalizedData.NoPolicy
                                            }
                                            $SubnetShort = if ($V.SubnetId) { $V.SubnetId.Split('/')[-1] } else { '--' }
                                            $ZoneDisplay = if ($V.Zones -and $V.Zones.Count -gt 0) { $V.Zones -join ', ' } elseif ($V.ProvisionedAvailabilityZone) { $V.ProvisionedAvailabilityZone } else { '--' }

                                            $VolDetail = [Ordered]@{
                                                $LocalizedData.Name = $VolShortName
                                                $LocalizedData.Account = $ParentAccount
                                                $LocalizedData.Pool = $ParentPool
                                                $LocalizedData.Location = $AzLocationLookup."$($V.Location)"
                                                $LocalizedData.ServiceLevel = $V.ServiceLevel
                                                $LocalizedData.VolumeType = if ($V.VolumeType) { $V.VolumeType } else { 'Regular' }
                                                $LocalizedData.Protocol = ($V.ProtocolTypes -join ', ')
                                                $LocalizedData.QuotaGiB = [math]::Round($V.UsageThreshold / 1GB, 0)
                                                $LocalizedData.Throughput = if ($null -ne $V.ThroughputMibps) { $V.ThroughputMibps } else { '--' }
                                                $LocalizedData.ActualThroughput = if ($null -ne $V.ActualThroughputMibps) { $V.ActualThroughputMibps } else { '--' }
                                                $LocalizedData.Subnet = $SubnetShort
                                                $LocalizedData.NetworkFeatures = if ($V.NetworkFeatures) { $V.NetworkFeatures } else { '--' }
                                                $LocalizedData.Zone = $ZoneDisplay
                                                $LocalizedData.SecurityStyle = if ($V.SecurityStyle) { $V.SecurityStyle } else { '--' }
                                                $LocalizedData.UnixPermission = if ($V.UnixPermission) { $V.UnixPermission } else { '--' }
                                                $LocalizedData.SnapshotPolicy = $SnapPolName
                                                $LocalizedData.BackupPolicy = $BackupPolName
                                                $LocalizedData.SnapshotDirVisible = if ($V.SnapshotDirectoryVisible) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.KerberosEnabled = if ($V.KerberosEnabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.LdapEnabled = if ($V.LdapEnabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.SmbEncryption = if ($V.SmbEncryption) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.SmbContinuouslyAvailable = if ($V.SmbContinuouslyAvailable) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.SmbAccessBasedEnumeration = if ($V.SmbAccessBasedEnumeration) { $V.SmbAccessBasedEnumeration } else { '--' }
                                                $LocalizedData.CoolAccess = if ($V.CoolAccess) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                $LocalizedData.CoolnessPeriod = if ($V.CoolAccess -and $null -ne $V.CoolnessPeriod) { $V.CoolnessPeriod } else { '--' }
                                                $LocalizedData.TieringPolicy = if ($V.CoolAccess -and $V.CoolAccessTieringPolicy) { $V.CoolAccessTieringPolicy } else { '--' }
                                                $LocalizedData.RetrievalPolicy = if ($V.CoolAccess -and $V.CoolAccessRetrievalPolicy) { $V.CoolAccessRetrievalPolicy } else { '--' }
                                                $LocalizedData.FileSystemId = if ($V.FileSystemId) { $V.FileSystemId } else { '--' }
                                                $LocalizedData.ProvisioningState = $V.ProvisioningState
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
                                            if ($V.MountTargets -and $V.MountTargets.Count -gt 0) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.MountTargetsHeading {
                                                    $MtInfo = @()
                                                    foreach ($Mt in $V.MountTargets) {
                                                        $MtInfo += [PSCustomObject][Ordered]@{
                                                            $LocalizedData.IpAddress = if ($Mt.IPAddress) { $Mt.IPAddress } else { '--' }
                                                            $LocalizedData.SmbServerFqdn = if ($Mt.SmbServerFqdn) { $Mt.SmbServerFqdn } else { '--' }
                                                            $LocalizedData.FileSystemId = if ($Mt.FileSystemId) { $Mt.FileSystemId } else { '--' }
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
                                            if ($V.ExportPolicy -and $V.ExportPolicy.Rules -and $V.ExportPolicy.Rules.Count -gt 0) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ExportPolicyHeading {
                                                    $EpInfo = @()
                                                    foreach ($Rule in ($V.ExportPolicy.Rules | Sort-Object RuleIndex)) {
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
                                                $VolRg = $V.Id.Split('/')[4]
                                                $Snapshots = Get-AzNetAppFilesSnapshot -ResourceGroupName $VolRg -AccountName $ParentAccount -PoolName $ParentPool -VolumeName $VolShortName -ErrorAction SilentlyContinue | Sort-Object Created -Descending
                                                if ($Snapshots) {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SnapshotsHeading {
                                                        $SnapInfo = @()
                                                        foreach ($S in $Snapshots) {
                                                            $SnapInfo += [PSCustomObject][Ordered]@{
                                                                $LocalizedData.Name = $S.Name.Split('/')[-1]
                                                                $LocalizedData.Created = if ($S.Created) { ([datetime]$S.Created).ToString('yyyy-MM-dd HH:mm') } else { '--' }
                                                                $LocalizedData.ProvisioningState = if ($S.ProvisioningState) { $S.ProvisioningState } else { '--' }
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
                                                        foreach ($Qr in $QuotaRules) {
                                                            $QrInfo += [PSCustomObject][Ordered]@{
                                                                $LocalizedData.Name = $Qr.Name.Split('/')[-1]
                                                                $LocalizedData.Type = $Qr.QuotaType
                                                                $LocalizedData.AllowedClients = if ($Qr.QuotaTarget) { $Qr.QuotaTarget } else { '--' }
                                                                $LocalizedData.QuotaGiB = if ($Qr.QuotaSizeInKiBs) { [math]::Round($Qr.QuotaSizeInKiBs / (1024 * 1024), 2) } else { 0 }
                                                                $LocalizedData.ProvisioningState = if ($Qr.ProvisioningState) { $Qr.ProvisioningState } else { '--' }
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
                            foreach ($Acct in $AzAnfAccounts) {
                                $AcctRg = $AccountMap[$Acct.Name].ResourceGroup
                                $Pols = Get-AzNetAppFilesSnapshotPolicy -ResourceGroupName $AcctRg -AccountName $Acct.Name -ErrorAction SilentlyContinue
                                if ($Pols) {
                                    foreach ($Pol in $Pols) {
                                        $AllSnapPolicies += [PSCustomObject]@{
                                            Account = $Acct.Name
                                            Policy  = $Pol
                                        }
                                    }
                                }
                            }
                            if ($AllSnapPolicies) {
                                Section -Style Heading5 $LocalizedData.SnapshotPoliciesHeading {
                                    Paragraph ($LocalizedData.SnapshotPoliciesSummary -f $AzSubscription.Name)
                                    BlankLine

                                    foreach ($Item in $AllSnapPolicies) {
                                        $Pol = $Item.Policy
                                        $PolShortName = $Pol.Name.Split('/')[-1]
                                        $Hourly = if ($Pol.HourlySchedule -and $Pol.HourlySchedule.SnapshotsToKeep) { "Every hour at :$('{0:D2}' -f [int]$Pol.HourlySchedule.Minute), keep $($Pol.HourlySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }
                                        $Daily = if ($Pol.DailySchedule -and $Pol.DailySchedule.SnapshotsToKeep) { "At $('{0:D2}' -f [int]$Pol.DailySchedule.Hour):$('{0:D2}' -f [int]$Pol.DailySchedule.Minute), keep $($Pol.DailySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }
                                        $Weekly = if ($Pol.WeeklySchedule -and $Pol.WeeklySchedule.SnapshotsToKeep) { "$($Pol.WeeklySchedule.Day) at $('{0:D2}' -f [int]$Pol.WeeklySchedule.Hour):$('{0:D2}' -f [int]$Pol.WeeklySchedule.Minute), keep $($Pol.WeeklySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }
                                        $Monthly = if ($Pol.MonthlySchedule -and $Pol.MonthlySchedule.SnapshotsToKeep) { "Day(s) $($Pol.MonthlySchedule.DaysOfMonth) at $('{0:D2}' -f [int]$Pol.MonthlySchedule.Hour):$('{0:D2}' -f [int]$Pol.MonthlySchedule.Minute), keep $($Pol.MonthlySchedule.SnapshotsToKeep)" } else { $LocalizedData.NotConfigured }

                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Item.Account) / $PolShortName" {
                                            $SpObj = [PSCustomObject][Ordered]@{
                                                $LocalizedData.Name = $PolShortName
                                                $LocalizedData.Account = $Item.Account
                                                $LocalizedData.Enabled = if ($Pol.Enabled) { $LocalizedData.Yes } else { $LocalizedData.No }
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
                            foreach ($Acct in $AzAnfAccounts) {
                                $AcctRg = $AccountMap[$Acct.Name].ResourceGroup
                                $Pols = Get-AzNetAppFilesBackupPolicy -ResourceGroupName $AcctRg -AccountName $Acct.Name -ErrorAction SilentlyContinue
                                if ($Pols) {
                                    foreach ($Pol in $Pols) {
                                        $AllBackupPolicies += [PSCustomObject]@{
                                            Account = $Acct.Name
                                            Policy  = $Pol
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
                                        $Pol = $Item.Policy
                                        $PolShortName = $Pol.Name.Split('/')[-1]
                                        $BpInfo += [PSCustomObject][Ordered]@{
                                            $LocalizedData.Name = $PolShortName
                                            $LocalizedData.Account = $Item.Account
                                            $LocalizedData.Enabled = if ($Pol.Enabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                            $LocalizedData.DailyBackups = if ($null -ne $Pol.DailyBackupsToKeep) { $Pol.DailyBackupsToKeep } else { 0 }
                                            $LocalizedData.WeeklyBackups = if ($null -ne $Pol.WeeklyBackupsToKeep) { $Pol.WeeklyBackupsToKeep } else { 0 }
                                            $LocalizedData.MonthlyBackups = if ($null -ne $Pol.MonthlyBackupsToKeep) { $Pol.MonthlyBackupsToKeep } else { 0 }
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
