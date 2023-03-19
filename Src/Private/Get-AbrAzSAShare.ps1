function Get-AbrAzSAShare {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Storage Account Share information
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
        Write-PScriboMessage "StorageAccount InfoLevel set at $($InfoLevel.StorageAccount)."
    }

    process {
        $AzSAShares = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName | Get-AzStorageShare | Sort-Object Name
        if (($InfoLevel.StorageAccount -gt 0) -and ($AzSAShares)) {
            Write-PscriboMessage "Collecting Azure Storage Account Shares information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Shares' {
                $AzSAShareInfo = @()
                foreach ($AzSAShare in $AzSAShares) {
                    $InObj = [Ordered]@{
                        'Name' = $AzSAShare.Name
                        'Quota' = Switch ([string]::IsNullOrEmpty($AzSAShare.ShareProperties.QuotaInGB)) {
                            $null { 'Unknown' }
                            default {"$($AzSAShare.ShareProperties.QuotaInGB / 1024) Tib"}
                        }
                        'Access Tier' = Switch ($AzSAShare.ShareProperties.AccessTier) {
                            'TransactionOptimized' { 'Transaction Optimized' }
                            default {$AzSAShare.ShareProperties.AccessTier}
                        }
                        'Last Modified' = $AzSAShare.LastModified.UtcDateTime.ToShortDateString()
                        'Is Snapshot' = Switch ($AzSAShare.IsSnapshot) {
                            'False' { 'Not Enabled' }
                            'True' { 'Enabled' }
                            default {$AzSAShare.IsSnapshot}
                        }

                    }
                    $AzSAShareInfo += [PSCustomObject]$InObj
                }

                $TableParams = @{
                    Name = "Shares - $($StorageAccountName)"
                    List = $false
                    Columns = 'Name', 'Access Tier', 'Quota', 'Last Modified', 'Is Snapshot'
                    ColumnWidths = 28, 27, 15, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzSAShareInfo | Table @TableParams
            }
        }
    }

    end {}
}