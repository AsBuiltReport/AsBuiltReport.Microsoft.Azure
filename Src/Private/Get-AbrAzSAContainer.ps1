function Get-AbrAzSAContainer {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Container information
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
            $AzSAContainers = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName | Get-AzStorageContainer -ErrorAction SilentlyContinue | Sort-Object Name
            if ($AzSAContainers) {
                Write-PscriboMessage "Collecting Azure Storage Account Containers information."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Containers' {
                    $AzSAContInfo = @()
                    foreach ($AzSAContainer in $AzSAContainers) {
                        $InObj = [Ordered]@{
                            'Name' = $AzSAContainer.Name
                            'Public Access' = if ($AzSAContainer.PublicAccess) {
                                $AzSAContainer.PublicAccess
                            } else {
                                'Disabled'
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
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}