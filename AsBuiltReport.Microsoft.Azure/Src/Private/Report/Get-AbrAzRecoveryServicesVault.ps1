function Get-AbrAzRecoveryServicesVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Recovery Services Vault information
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
        $LocalizedData = $reportTranslate.GetAbrAzRecoveryServicesVault
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.RecoveryServicesVault)
    }

    process {
        Try {
            if ($InfoLevel.RecoveryServicesVault -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    Write-PscriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $LockMap = @{}
                        $AllLocks = Get-AzResourceLock -ErrorAction SilentlyContinue
                        foreach ($Lock in $AllLocks) {
                            $Key = $Lock.ResourceId.ToLower()
                            if (-not $LockMap.ContainsKey($Key)) { $LockMap[$Key] = @() }
                            $LockMap[$Key] += $Lock
                        }

                        $AzRsvInfo = @()
                        foreach ($AzRsv in $AzRsvs) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name                                = $AzRsv.Name
                                $LocalizedData.ResourceGroup                       = $AzRsv.ResourceGroupName
                                $LocalizedData.Location                            = $AzLocationLookup."$($AzRsv.Location)"
                                $LocalizedData.Subscription                        = "$($AzSubscriptionLookup.(($AzRsv.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID                      = ($AzRsv.Id).split('/')[2]
                                $LocalizedData.ProvisioningState                   = $AzRsv.Properties.ProvisioningState
                                $LocalizedData.StorageRedundancy                   = Switch ($AzRsv.Properties.RedundancySettings.StandardTierStorageRedundancy) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.RedundancySettings.StandardTierStorageRedundancy }
                                }
                                $LocalizedData.CrossRegionRestore                  = Switch ($AzRsv.Properties.RedundancySettings.CrossRegionRestore) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.RedundancySettings.CrossRegionRestore }
                                }
                                $LocalizedData.SoftDeleteState                     = Switch ($AzRsv.Properties.SoftDeleteSettings.SoftDeleteState) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.SoftDeleteSettings.SoftDeleteState }
                                }
                                $LocalizedData.SoftDeleteRetentionDays             = Switch ($AzRsv.Properties.SoftDeleteSettings.SoftDeleteRetentionPeriodInDays) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.SoftDeleteSettings.SoftDeleteRetentionPeriodInDays }
                                }
                                $LocalizedData.ImmutabilityState                   = Switch ($AzRsv.Properties.ImmutabilitySettings.ImmutabilityState) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.ImmutabilitySettings.ImmutabilityState }
                                }
                                $LocalizedData.PublicNetworkAccess                 = Switch ($AzRsv.Properties.PublicNetworkAccess) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.PublicNetworkAccess }
                                }
                                $LocalizedData.PrivateEndpointStateForBackup       = Switch ($AzRsv.Properties.PrivateEndpointStateForBackup) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.PrivateEndpointStateForBackup }
                                }
                                $LocalizedData.PrivateEndpointStateForSiteRecovery = Switch ($AzRsv.Properties.PrivateEndpointStateForSiteRecovery) {
                                    $null   { $LocalizedData.None }
                                    default { $AzRsv.Properties.PrivateEndpointStateForSiteRecovery }
                                }
                            }
                            $InObj[$LocalizedData.Locks] = $(
                                $rl = $LockMap[$AzRsv.Id.ToLower()]
                                if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                else { $LocalizedData.None }
                            )
                            $InObj[$LocalizedData.Tags] = $(
                                if ($AzRsv.Tags -and $AzRsv.Tags.Count -gt 0) {
                                    ($AzRsv.Tags.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join [Environment]::NewLine
                                } else {
                                    $LocalizedData.None
                                }
                            )

                            $AzRsvInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.RecoveryServicesVault.ProvisioningState) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.RecoveryServicesVault.PrivateEndpointStateForBackup) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.PrivateEndpointStateForBackup) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.PrivateEndpointStateForBackup
                        }
                        if ($Healthcheck.RecoveryServicesVault.SoftDeleteEnabled) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.SoftDeleteState) -eq 'Disabled' } | Set-Style -Style Warning -Property $LocalizedData.SoftDeleteState
                        }
                        if ($Healthcheck.RecoveryServicesVault.ImmutabilityEnabled) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.ImmutabilityState) -eq 'Disabled' } | Set-Style -Style Warning -Property $LocalizedData.ImmutabilityState
                        }
                        if ($Healthcheck.RecoveryServicesVault.PublicNetworkAccess) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.PublicNetworkAccess) -eq 'Enabled' } | Set-Style -Style Warning -Property $LocalizedData.PublicNetworkAccess
                        }

                        if ($InfoLevel.RecoveryServicesVault -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzRsv in $AzRsvInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRsv.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.Heading) - $($AzRsv.($LocalizedData.Name))"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRsv | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location
                                ColumnWidths = 33, 34, 33
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzRsvinfo | Table @TableParams
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
