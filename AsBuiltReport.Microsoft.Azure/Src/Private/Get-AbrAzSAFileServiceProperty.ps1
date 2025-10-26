function Get-AbrAzSAFileServiceProperty {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account File Service Property information
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
        $LocalizedData = $reportTranslate.GetAbrAzSAFileServiceProperty
    }

    process {
        Try {
            $AzSAFileServiceProperty = Get-AzStorageFileServiceProperty -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
            $AzStorageAccount = Get-AzStorageAccount -Name $AzSAFileServiceProperty.StorageAccountName -ResourceGroupName $AzSAFileServiceProperty.ResourceGroupName
            if ($AzSAFileServiceProperty -and $AzStorageAccount) {
                Write-PscriboMessage ($LocalizedData.Collecting -f $AzStorageAccount.StorageAccountName)
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSAFileServicePropertyInfo = @()
                    foreach ($AzSAFileService in $AzSAFileServiceProperty) {
                        $InObj = [Ordered]@{
                            $LocalizedData.LargeFileShare = If ($AzStorageAccount.LargeFileSharesState) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.IdentityBasedAccess = If ($AzStorageAccount.AzureFilesIdentityBasedAuth) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.SoftDelete = if ($AzSAFileService.ShareDeleteRetentionPolicy.Enabled -and $AzSAFileService.ShareDeleteRetentionPolicy.Days) {
                                ($LocalizedData.EnabledDays -f $AzSAFileService.ShareDeleteRetentionPolicy.Days)
                            } else {
                                $LocalizedData.Disabled
                            }
                        }
                        $AzSAFileServicePropertyInfo = [PSCustomObject]$InObj
                    }
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($AzSAFileServiceProperty.StorageAccountName)"
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
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}