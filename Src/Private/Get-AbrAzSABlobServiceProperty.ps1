function Get-AbrAzSABlobServiceProperty {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Blob Service Property information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ResourceGroupName,
        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $StorageAccountName
    )

    begin {}

    process {
        Try {
            $AzSABlobServiceProperty = Get-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
            $AzStorageAccount = Get-AzStorageAccount -Name $AzSABlobServiceProperty.StorageAccountName -ResourceGroupName $AzSABlobServiceProperty.ResourceGroupName
            if ($AzSABlobServiceProperty -and $AzStorageAccount) {
                Write-PScriboMessage "Collecting Azure Storage Account Blob Service information [$($AzStorageAccount.StorageAccountName)]."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Blob Service' {
                    $AzSABlobServicePropertyInfo = @()
                    foreach ($AzSABlobService in $AzSABlobServiceProperty) {
                        $InObj = [Ordered]@{
                            'Hierarchical Namespace' = if ($AzStorageAccount.EnableHierarchicalNamespace) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'Default Access Tier' = if ($null -ne $AzStorageAccount.AccessTier) {
                                $AzStorageAccount.AccessTier
                            } else {
                                'Not Applicable'
                            }
                            'Blob Anonymous Access' = if ($AzStorageAccount.AllowBlobPublicAccess) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'Blob Soft Delete' = If ($AzSABlobService.DeleteRetentionPolicy.Enabled -and $AzSABlobService.DeleteRetentionPolicy.Days) {
                                "Enabled ($($AzSABlobService.DeleteRetentionPolicy.Days) days)"
                            } else {
                                'Disabled'
                            }
                            'Container Soft Delete' = If ($AzSABlobService.ContainerDeleteRetentionPolicy.Enabled -and $AzSABlobService.ContainerDeleteRetentionPolicy.Days) {
                                "Enabled ($($AzSABlobService.ContainerDeleteRetentionPolicy.Days) days)"
                            } else {
                                'Disabled'
                            }
                            'Versioning' = if ($AzSABlobService.IsVersioningEnabled) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'Change Feed' = if ($AzSABlobService.ChangeFeed.Enabled -and $AzSABlobService.ChangeFeed.RetentionInDays) {
                                "Enabled ($($AzSABlobService.ChangeFeed.RetentionInDays) days)"
                            } else {
                                'Disabled'
                            }
                            'NFS v3' = if ($AzStorageAccount.EnableNfsV3) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'SFTP' = if ($AzStorageAccount.EnableSftp) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'Allow Cross-Tenant Replication' = if ($AzStorageAccount.AllowCrossTenantReplication) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                        }
                        $AzSABlobServicePropertyInfo += [PSCustomObject]$InObj

                        if ($Healthcheck.StorageAccount.BlobAnonymousAccess) {
                            $AzSABlobServicePropertyInfo | Where-Object { $_.'Blob Anonymous Access' -eq 'Enabled' } | Set-Style -Style Warning -Property 'Blob Anonymous Access'
                        }
                    }
                    $TableParams = @{
                        Name = "Blob Service - $($AzSABlobService.StorageAccountName)"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzSABlobServicePropertyInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}