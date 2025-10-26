function Get-AbrAzStorageAccount {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account information
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
        Author:         Jonathan Colon / Tim Carman
        Twitter:        @jcolonfzenpr / @tpcarman
        Github:         rebelinux / tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzStorageAccount
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.StorageAccount)
    }

    process {
        try {
            if ($InfoLevel.StorageAccount -gt 0) {
                $AzStorageAccounts = Get-AzStorageAccount | Sort-Object StorageAccountName
                if ($AzStorageAccounts) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $AzStorageAccountInfo = @()
                        foreach ($AzStorageAccount in $AzStorageAccounts) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzStorageAccount.StorageAccountName
                                $LocalizedData.ResourceGroup = $AzStorageAccount.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzStorageAccount.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzStorageAccount.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzStorageAccount.Id).split('/')[2]
                                $LocalizedData.PrimarySecondaryLocation = "$($LocalizedData.Primary): $($AzLocationLookup."$($AzStorageAccount.PrimaryLocation)"), $($LocalizedData.Secondary): $($AzLocationLookup."$($AzStorageAccount.SecondaryLocation)")"
                                $LocalizedData.DiskState = "$($LocalizedData.Primary): $($AzStorageAccount.StatusOfPrimary), $($LocalizedData.Secondary): $($AzStorageAccount.StatusOfSecondary)"
                                $LocalizedData.Performance = $AzStorageAccount.Sku.Tier
                                $LocalizedData.Replication = switch ($AzStorageAccount.Sku.Name) {
                                    'Standard_LRS' { $LocalizedData.LRS }
                                    'Standard_ZRS' { $LocalizedData.ZRS }
                                    'Standard_GRS' { $LocalizedData.GRS }
                                    'Standard_RAGRS' { $LocalizedData.RAGRS }
                                    'Premium_LRS' { $LocalizedData.PremiumLRS }
                                    'Premium_ZRS' { $LocalizedData.PremiumZRS }
                                    'Standard_GZRS' { $LocalizedData.GZRS }
                                    'Standard_RAGZRS' { $LocalizedData.RAGZRS }
                                    default { $LocalizedData.Unknown }
                                }
                                $LocalizedData.AccountKind = switch ($AzStorageAccount.Kind) {
                                    'Storage' { $LocalizedData.Storage }
                                    'StorageV2' { $LocalizedData.StorageV2 }
                                    'BlobStorage' { $LocalizedData.BlobStorage }
                                    'BlockBlobStorage' { $LocalizedData.BlockBlobStorage }
                                    'FileStorage' { $LocalizedData.FileStorage }
                                    default { $LocalizedData.Unknown }
                                }
                                $LocalizedData.ProvisioningState = $AzStorageAccount.ProvisioningState
                                $LocalizedData.SecureTransfer = if ($AzStorageAccount.EnableHttpsTrafficOnly) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.StorageAccountKeyAccess = if ($AzStorageAccount.AllowSharedKeyAccess) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.PublicNetworkAccess = if ($AzStorageAccount.PublicNetworkAccess) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.MinimumTLSVersion = $AzStorageAccount.MinimumTlsVersion -replace "TLS(\d)_(\d)", 'TLS $1.$2'
                                $LocalizedData.InfrastructureEncryption = if ($AzStorageAccount.RequireInfrastructureEncryption) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.Created = $AzStorageAccount.CreationTime
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzStorageAccount.Tags)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzStorageAccount.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzStorageAccountInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.StorageAccount.ProvisioningState) {
                            $AzStorageAccountInfo | Where-Object { $_.($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($Healthcheck.StorageAccount.StorageAccountKeyAccess) {
                            $AzStorageAccountInfo | Where-Object { $_.($LocalizedData.StorageAccountKeyAccess) -eq 'Enabled' } | Set-Style -Style Warning -Property $LocalizedData.StorageAccountKeyAccess
                        }

                        if ($Healthcheck.StorageAccount.SecureTransfer) {
                            $AzStorageAccountInfo | Where-Object { $_.($LocalizedData.SecureTransfer) -ne 'Enabled' } | Set-Style -Style Warning -Property $LocalizedData.SecureTransfer
                        }

                        if ($Healthcheck.StorageAccount.PublicNetworkAccess) {
                            $AzStorageAccountInfo | Where-Object { $_.($LocalizedData.PublicNetworkAccess) -eq 'Enabled' } | Set-Style -Style Warning -Property $LocalizedData.PublicNetworkAccess
                        }

                        if ($Healthcheck.StorageAccount.MinimumTlsVersion) {
                            $AzStorageAccountInfo | Where-Object { $_.($LocalizedData.MinimumTLSVersion) -ne 'TLS 1.2' } | Set-Style -Style Critical -Property $LocalizedData.MinimumTLSVersion
                        }

                        if ($InfoLevel.StorageAccount -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzStorageAccount in $AzStorageAccountInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $AzStorageAccount.($LocalizedData.Name) {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzStorageAccount.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzStorageAccount | Table @TableParams

                                    $ResourceGroupName = "$($AzStorageAccount.($LocalizedData.ResourceGroup))"
                                    $StorageAccountName =  "$($AzStorageAccount.($LocalizedData.Name))"

                                    # Blob Service Properties
                                    Get-AbrAzSABlobServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
                                    # Container Service Properties
                                    Get-AbrAzSAContainer -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
                                    # File Service Properties
                                    Get-AbrAzSAFileServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
                                    # Share Service Properties
                                    Get-AbrAzSAShare -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
                                }
                            }
                        } else {
                            Paragraph ($($LocalizedData.ParagraphSummary) -f $($AzSubscription.Name))
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Replication, $LocalizedData.AccountKind
                                ColumnWidths = 20, 20, 20, 20, 20
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzStorageAccountInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}