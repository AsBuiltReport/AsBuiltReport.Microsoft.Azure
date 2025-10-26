function Get-AbrAzSAContainer {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Container information
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
        $LocalizedData = $reportTranslate.GetAbrAzSAContainer
    }

    process {
        Try {
            $AzSAContainers = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName | Get-AzStorageContainer -ErrorAction SilentlyContinue | Sort-Object Name
            if ($AzSAContainers) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSAContInfo = @()
                    foreach ($AzSAContainer in $AzSAContainers) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzSAContainer.Name
                            $LocalizedData.PublicAccess = if ($AzSAContainer.PublicAccess) {
                                $AzSAContainer.PublicAccess
                            } else {
                                $LocalizedData.Disabled
                            }
                            $LocalizedData.LastModified = $AzSAContainer.LastModified.UtcDateTime.ToShortDateString()

                        }
                        $AzSAContInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($StorageAccountName)"
                        List = $false
                        Columns = $LocalizedData.Name, $LocalizedData.PublicAccess, $LocalizedData.LastModified
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