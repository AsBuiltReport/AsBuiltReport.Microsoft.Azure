function Get-AbrAzSABlobServiceProperty {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Blob Service Property information
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

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzSABlobServiceProperty
    }

    process {
        Try {
            $AzSABlobServiceProperty = Get-AzStorageBlobServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
            $AzStorageAccount = Get-AzStorageAccount -Name $AzSABlobServiceProperty.StorageAccountName -ResourceGroupName $AzSABlobServiceProperty.ResourceGroupName
            if ($AzSABlobServiceProperty -and $AzStorageAccount) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $AzStorageAccount.StorageAccountName)
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSABlobServicePropertyInfo = @()
                    foreach ($AzSABlobService in $AzSABlobServiceProperty) {
                        $InObj = [Ordered]@{
                            $LocalizedData.HierarchicalNamespace = if ($AzStorageAccount.EnableHierarchicalNamespace) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.DefaultAccessTier = if ($null -ne $AzStorageAccount.AccessTier) {
                                $AzStorageAccount.AccessTier
                            } else {
                                $LocalizedData.NotApplicable
                            }
                            $LocalizedData.BlobAnonymousAccess = switch ($AzStorageAccount.AllowBlobPublicAccess) {
                                $null { $LocalizedData.Enabled }
                                $true { $LocalizedData.Enabled }
                                $false { $LocalizedData.Disabled }
                                default { $AzStorageAccount.AllowBlobPublicAccess }
                            }
                            $LocalizedData.BlobSoftDelete = If ($AzSABlobService.DeleteRetentionPolicy.Enabled -and $AzSABlobService.DeleteRetentionPolicy.Days) {
                                ($LocalizedData.EnabledDays -f $AzSABlobService.DeleteRetentionPolicy.Days)
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.ContainerSoftDelete = If ($AzSABlobService.ContainerDeleteRetentionPolicy.Enabled -and $AzSABlobService.ContainerDeleteRetentionPolicy.Days) {
                                ($LocalizedData.EnabledDays -f $AzSABlobService.ContainerDeleteRetentionPolicy.Days)
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.Versioning = if ($AzSABlobService.IsVersioningEnabled) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.ChangeFeed = if ($AzSABlobService.ChangeFeed.Enabled -and $AzSABlobService.ChangeFeed.RetentionInDays) {
                                ($LocalizedData.EnabledDays -f $AzSABlobService.ChangeFeed.RetentionInDays)
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.NFSv3 = if ($AzStorageAccount.EnableNfsV3) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.SFTP = if ($AzStorageAccount.EnableSftp) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.AllowCrossTenantReplication = switch ($AzStorageAccount.AllowCrossTenantReplication) {
                                $null { $LocalizedData.Enabled }
                                $true { $LocalizedData.Enabled }
                                $false { $LocalizedData.Disabled }
                                default { $AzStorageAccount.AllowCrossTenantReplication }
                            }
                        }
                        $AzSABlobServicePropertyInfo += [PSCustomObject]$InObj

                        if ($Healthcheck.StorageAccount.BlobAnonymousAccess) {
                            $AzSABlobServicePropertyInfo | Where-Object { $_.($LocalizedData.BlobAnonymousAccess) -eq $LocalizedData.Enabled } | Set-Style -Style Warning -Property $LocalizedData.BlobAnonymousAccess
                        }
                    }
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($AzSABlobService.StorageAccountName)"
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