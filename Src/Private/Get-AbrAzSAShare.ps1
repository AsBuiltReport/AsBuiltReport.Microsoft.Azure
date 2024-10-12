function Get-AbrAzSAShare {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Share information
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
            $AzSAShares = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName | Get-AzStorageShare -ErrorAction SilentlyContinue | Sort-Object Name
            if ($AzSAShares) {
                Write-PscriboMessage "Collecting Azure Storage Account Shares information."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Shares' {
                    $AzSAShareInfo = @()
                    foreach ($AzSAShare in $AzSAShares) {
                        $InObj = [Ordered]@{
                            'Name' = $AzSAShare.Name
                            'Share URL' = $AzSAShare.CloudFileShare.Uri.AbsoluteUri
                            'Quota' = if ([string]::IsNullOrEmpty($AzSAShare.ShareProperties.QuotaInGB)) {
                                'Unknown'
                            } else {
                                "$($AzSAShare.ShareProperties.QuotaInGB / 1024) Tib"
                            }
                            'Access Tier' = Switch ($AzSAShare.ShareProperties.AccessTier) {
                                'TransactionOptimized' { 'Transaction Optimized' }
                                default {$AzSAShare.ShareProperties.AccessTier}
                            }
                            'Last Modified' = $AzSAShare.LastModified.UtcDateTime.ToShortDateString()
                            'Snapshot' = if ($AzSAShare.IsSnapshot) {
                                'Enabled'
                            } else {
                                'Disabled'
                            }
                        }
                        $AzSAShareInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = "Shares - $($StorageAccountName)"
                        List = $false
                        Columns = 'Name', 'Access Tier', 'Quota', 'Last Modified', 'Snapshot'
                        ColumnWidths = 28, 27, 15, 15, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzSAShareInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}