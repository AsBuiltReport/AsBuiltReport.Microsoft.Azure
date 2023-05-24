function Get-AbrAzSAContainer {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Storage Account Container information
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
        $AzSAContainers = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName | Get-AzStorageContainer | Sort-Object Name
        if (($InfoLevel.StorageAccount -gt 0) -and ($AzSAContainers)) {
            Write-PscriboMessage "Collecting Azure Storage Account Containers information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Containers' {
                $AzSAContInfo = @()
                foreach ($AzSAContainer in $AzSAContainers) {
                    $InObj = [Ordered]@{
                        'Name' = $AzSAContainer.Name
                        'Public Access' = Switch ($AzSAContainer.PublicAccess) {
                            'Off' { 'Not Enabled' }
                            $null { 'Not Enabled' }
                            default {$AzSAContainer.PublicAccess}
                        }
                        'Last Modified' = $AzSAContainer.LastModified.UtcDateTime.ToShortDateString()

                    }
                    $AzSAContInfo += [PSCustomObject]$InObj
                }

                $TableParams = @{
                    Name = "Container - $($StorageAccountName)"
                    List = $false
                    Columns = 'Name', 'Public Access', 'Last Modified'
                    ColumnWidths = 50, 25, 25
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzSAContInfo | Table @TableParams
            }
        }
    }

    end {}
}