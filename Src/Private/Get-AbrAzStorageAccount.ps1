function Get-AbrAzStorageAccount {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account information
    .DESCRIPTION

    .NOTES
        Version:        0.1.6
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
        Write-PScriboMessage "StorageAccount InfoLevel set at $($InfoLevel.StorageAccount)."
    }

    process {
        Try {
            if ($InfoLevel.StorageAccount -gt 0) {
                $AzStorageAccounts = Get-AzStorageAccount | Sort-Object StorageAccountName
                if ($AzStorageAccounts) {
                    Write-PscriboMessage "Collecting Azure Storage Account information."
                    Section -Style Heading4 'Storage Account' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "Azure storage account contains all of your Azure Storage data objects, including blobs, file shares, queues, tables, and disks. The storage account provides a unique namespace for your Azure Storage data that's accessible from anywhere in the world over HTTP or HTTPS. Data in your storage account is durable and highly available, secure, and massively scalable."
                            BlankLine
                        }
                        $AzStorageAccountInfo = @()
                        foreach ($AzStorageAccount in $AzStorageAccounts) {
                            $InObj = [Ordered]@{
                                'Name' = $AzStorageAccount.StorageAccountName
                                'Resource Group' = $AzStorageAccount.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzStorageAccount.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzStorageAccount.Id).split('/')[2]))"
                                'Primary/Secondary Location' = "Primary: $($AzLocationLookup."$($AzStorageAccount.PrimaryLocation)"), Secondary: $($AzLocationLookup."$($AzStorageAccount.SecondaryLocation)")"
                                'Disk state' = "Primary: $($AzStorageAccount.StatusOfPrimary), Secondary: $($AzStorageAccount.StatusOfSecondary)"
                                'Performance' = $AzStorageAccount.Sku.Tier
                                'Replication' = Switch ($AzStorageAccount.Sku.Name) {
                                    'Standard_LRS' { 'Locally-redundant storage (LRS)' }
                                    'Standard_ZRS' { 'Zone-redundant storage (ZRS)' }
                                    'Standard_GRS' { 'Geo-redundant storage (GRS)' }
                                    'Standard_RAGRS' { 'Read access geo-redundant storage (RA-GRS)' }
                                    'Premium_LRS' { 'Premium locally-redundant storage (Premium LRS)' }
                                    'Premium_ZRS' { 'Premium zone-redundant storage (Premium ZRS)' }
                                    'Standard_GZRS' { 'Geo-redundant zone-redundant storage (GZRS)' }
                                    'Standard_RAGZRS' { 'Read access geo-redundant zone-redundant storage (RA-GZRS)' }
                                    default {'Unknown'}
                                }
                                'Account Kind' = Switch ($AzStorageAccount.Kind) {
                                    'Storage' {'Storage (General Purpose v1)'}
                                    'StorageV2' {'Storage (General Purpose v2)'}
                                    'BlobStorage' {'Blob Storage'}
                                    'BlockBlobStorage' {'Block Blob Storage'}
                                    'FileStorage' {'File Storage'}
                                    default {'Unknown'}
                                }
                                'Provisioning State' = $AzStorageAccount.ProvisioningState
                                'Secure Transfer' = if ($AzStorageAccount.EnableHttpsTrafficOnly) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Storage Account Key Access' = if ($AzStorageAccount.AllowSharedKeyAccess) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Public Network Access' = if ($AzStorageAccount.PublicNetworkAccess) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Minimum TLS Version' = ($AzStorageAccount.MinimumTlsVersion).Replace('_','.')
                                'Infrastructure Encryption' = if ($AzStorageAccount.RequireInfrastructureEncryption) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Created' = $AzStorageAccount.CreationTime
                            }

                            if ($Options.ShowTags) {
                                $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzStorageAccount.Tags)) {
                                    'None'
                                } else {
                                    ($AzStorageAccount.Tags.GetEnumerator() | ForEach-Object {"$($_.Key):`t$($_.Value)"}) -join [Environment]::NewLine
                                }
                            }

                            $AzStorageAccountInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.StorageAccount.ProvisioningState) {
                            $AzStorageAccountInfo | Where-Object { $_.'Provisioning State' -ne 'Succeeded' } | Set-Style -Style Critical -Property 'Provisioning State'
                        }

                        if ($Healthcheck.StorageAccount.StorageAccountKeyAccess) {
                            $AzStorageAccountInfo | Where-Object { $_.'Storage Account Key Access' -eq 'Enabled' } | Set-Style -Style Warning -Property 'Storage Account Key Access'
                        }

                        if ($Healthcheck.StorageAccount.SecureTransfer) {
                            $AzStorageAccountInfo | Where-Object { $_.'Secure Transfer' -ne 'Enabled' } | Set-Style -Style Warning -Property 'Secure Transfer'
                        }

                        if ($Healthcheck.StorageAccount.PublicNetworkAccess) {
                            $AzStorageAccountInfo | Where-Object { $_.'Public Network Access' -eq 'Enabled' } | Set-Style -Style Warning -Property 'Public Network Access'
                        }

                        if ($Healthcheck.StorageAccount.MinimumTlsVersion) {
                            $AzStorageAccountInfo | Where-Object { $_.'Minimum TLS Version' -ne 'TLS1.2' } | Set-Style -Style Warning -Property 'Minimum TLS Version'
                        }

                        if ($InfoLevel.StorageAccount -ge 2) {
                            Paragraph "The following sections detail the configuration of the storage account within the $($AzSubscription.Name) subscription."
                            foreach ($AzStorageAccount in $AzStorageAccountInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzStorageAccount.Name)" {
                                    $TableParams = @{
                                        Name = "Storage Account - $($AzStorageAccount.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzStorageAccount | Table @TableParams
                                    # Blob Service Properties
                                    Get-AbrAzSABlobServiceProperty -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                                    # Container Service Properties
                                    Get-AbrAzSAContainer -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                                    # File Service Properties
                                    Get-AbrAzSAFileServiceProperty -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                                    # Share Service Properties
                                    Get-AbrAzSAShare -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                                }
                            }
                        } else {
                            Paragraph "The following table summarises the configuration of the storage account within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "Storage Account - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Resource Group', 'Location', 'Replication', 'Account Kind'
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
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}