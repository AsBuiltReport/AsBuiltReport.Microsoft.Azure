function Get-AbrAzSAFileServiceProperty {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account File Service Property information
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

    begin {
    }

    process {
        Try {
            $AzSAFileServiceProperty = Get-AzStorageFileServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
            $AzStorageAccount = Get-AzStorageAccount -Name $AzSAFileServiceProperty.StorageAccountName -ResourceGroupName $AzSAFileServiceProperty.ResourceGroupName
            if ($AzSAFileServiceProperty -and $AzStorageAccount) {
                Write-PscriboMessage "Collecting Azure Storage Account File Service information [$($AzStorageAccount.StorageAccountName)]."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'File Service' {
                    $AzSAFileServicePropertyInfo = @()
                    foreach ($AzSAFileService in $AzSAFileServiceProperty) {
                        $InObj = [Ordered]@{
                            'Large File Share' = If ($AzStorageAccount.LargeFileSharesState) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'Identity-based Access' = If ($AzStorageAccount.AzureFilesIdentityBasedAuth) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                            'Soft Delete' = if ($AzSAFileService.ShareDeleteRetentionPolicy.Enabled -and $AzSAFileService.ShareDeleteRetentionPolicy.Days) {
                                "Enabled ($($AzSAFileService.ShareDeleteRetentionPolicy.Days) days)"
                            } else {
                                'Disabled'
                            }
                        }
                        $AzSAFileServicePropertyInfo = [PSCustomObject]$InObj
                    }
                    $TableParams = @{
                        Name = "File Service - $($AzSAFileServiceProperty.StorageAccountName)"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzSAFileServicePropertyInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}