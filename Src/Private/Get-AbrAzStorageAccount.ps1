function Get-AbrAzStorageAccount {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Storage Account information
    .DESCRIPTION

    .NOTES
        Version:        0.1.5
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
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
        $AzStorageAccounts = Get-AzStorageAccount | Sort-Object StorageAccountName
        if (($InfoLevel.StorageAccount -gt 0) -and ($AzStorageAccounts)) {
            Write-PscriboMessage "Collecting Azure Storage Account information."
            Section -Style Heading4 'Storage Account' {
                if ($Options.ShowSectionInfo) {
                    Paragraph "Azure storage account contains all of your Azure Storage data objects, including blobs, file shares, queues, tables, and disks. The storage account provides a unique namespace for your Azure Storage data that's accessible from anywhere in the world over HTTP or HTTPS. Data in your storage account is durable and highly available, secure, and massively scalable."
                    BlankLine
                }
                $AzSAInfo = @()
                foreach ($AzStorageAccount in $AzStorageAccounts) {
                    $InObj = [Ordered]@{
                        'Name' = $AzStorageAccount.StorageAccountName
                        'Resource Group' = $AzStorageAccount.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzStorageAccount.Location)"
                        'Primary/Secondary Location' = "Primary: $($AzLocationLookup."$($AzStorageAccount.PrimaryLocation)") / Secondary: $($AzLocationLookup."$($AzStorageAccount.SecondaryLocation)")"
                        'Disk state' = "Primary: $($AzStorageAccount.StatusOfPrimary) / Secondary: $($AzStorageAccount.StatusOfSecondary)"
                        'Sku Name' = Switch ($AzStorageAccount.Sku.Name) {
                            'Standard_LRS' { 'Locally-redundant storage.' }
                            'Standard_ZRS' { 'Zone-redundant storage' }
                            'Standard_GRS' { 'Geo-redundant storage' }
                            'Standard_RAGRS' { 'Read access geo-redundant storage' }
                            'Premium_LRS' { 'Premium locally-redundant storage' }
                            'Premium_ZRS' { 'Premium zone-redundant storage' }
                            'Standard_GZRS' { 'Geo-redundant zone-redundant storage' }
                            'Standard_RAGZRS' { 'Read access geo-redundant zone-redundant storage' }
                            default {'Unknown'}
                        }
                        'Sku Tier' = $AzStorageAccount.Sku.Tier
                        'Account Kind' = Switch ($AzStorageAccount.Kind) {
                            'Storage' {'General Purpose Version'}
                            'StorageV2' {'General Purpose Version 2'}
                            'BlobStorage' {'Blob Storage'}
                            'BlockBlobStorage' {'Block Blob Storage'}
                            'FileStorage' {'File Storage'}
                            default {'Unknown'}
                        }
                        'Provisioning State' = $AzStorageAccount.ProvisioningState
                        'Enable Https Traffic Only' = Switch ($AzStorageAccount.EnableHttpsTrafficOnly) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                        'Allow Blob Public Access' = Switch ($AzStorageAccount.AllowBlobPublicAccess) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                        'Allow Shared Key Access' = Switch ($AzStorageAccount.AllowSharedKeyAccess) {
                            $true { 'Enabled' }
                            $false { 'Not Enabled' }
                            $null { 'Not Enabled' }
                        }
                        'Public Network Access' = $AzStorageAccount.PublicNetworkAccess
                        'Minimum TLS Version' = $AzStorageAccount.MinimumTlsVersion
                        'Default Access Tier' = $AzStorageAccount.AccessTier
                        'Creation Time' = $AzStorageAccount.CreationTime
                        'Tags' = Switch ([string]::IsNullOrEmpty($AzStorageAccount.Tags)) {
                            $true {"--"}
                            default {($AzStorageAccount.Tags.GetEnumerator() | ForEach-Object {"$($_.Key):$($_.Value)"}) -join ", "}
                        }
                    }
                    $AzSAInfo += [PSCustomObject]$InObj
                }

                if ($Healthcheck.StorageAccount.ProvisioningState) {
                    $AzSAInfo | Where-Object { $_.'Provisioning State' -ne 'Succeeded' } | Set-Style -Style Critical -Property 'Provisioning State'
                }

                if ($Healthcheck.StorageAccount.EnableHttpsTrafficOnly) {
                    $AzSAInfo | Where-Object { $_.'Enable Https Traffic Only' -ne 'Enabled' } | Set-Style -Style Warning -Property 'Enable Https Traffic Only'
                }

                if ($Healthcheck.StorageAccount.PublicNetworkAccess) {
                    $AzSAInfo | Where-Object { $_.'Public Network Access' -eq 'Enabled' } | Set-Style -Style Warning -Property 'Public Network Access'
                }

                if ($Healthcheck.StorageAccount.MinimumTlsVersion) {
                    $AzSAInfo | Where-Object { $_.'Minimum TLS Version' -ne 'TLS1_2' } | Set-Style -Style Warning -Property 'Minimum TLS Version'
                }

                if ($InfoLevel.StorageAccount -ge 2) {
                    Paragraph "The following sections detail the configuration of the storage account within the $($AzSubscription.Name) subscription."
                    foreach ($AzStorageAccount in $AzSAInfo) {
                        Section -Style Heading5 "$($AzStorageAccount.Name)" {
                            $TableParams = @{
                                Name = "Storage Account - $($AzStorageAccount.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzStorageAccount | Table @TableParams
                            # Blob Service Properties
                            Get-AbrAzSABlobServiceProperty -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                            Get-AbrAzSAFileServiceProperty -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                            Get-AbrAzSAContainer -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                            Get-AbrAzSAShare -ResourceGroupName $AzStorageAccount.'Resource Group' -StorageAccountName $AzStorageAccount.Name
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the storage account within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Storage Account - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'Sku Name', 'Account Kind'
                        ColumnWidths = 20, 20, 20, 20, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzSAInfo | Table @TableParams
                }
            }
        }
    }

    end {}
}