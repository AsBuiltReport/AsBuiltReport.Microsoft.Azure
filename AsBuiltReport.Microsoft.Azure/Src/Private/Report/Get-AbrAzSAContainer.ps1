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
            $AzSAContainers = Get-AzRmStorageContainer -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue | Sort-Object Name
            if ($AzSAContainers) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSAContInfo = @()
                    $Count = 1
                    foreach ($AzSAContainer in $AzSAContainers) {
                        Write-PscriboMessage ($LocalizedData.Processing -f ($AzSAContainer.Name),$Count,($AzSAContainers.Count))
                        $Count ++
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzSAContainer.Name
                            $LocalizedData.LastModified = if ($AzSAContainer.LastModifiedTime) {
                                $AzSAContainer.LastModifiedTime.ToShortDateString()
                            } else {
                                $LocalizedData.None
                            }
                            $LocalizedData.AnonymousAccessLevel = switch ($AzSAContainer.PublicAccess) {
                                "None" { $LocalizedData.Private }
                                "Blob" { $LocalizedData.Blob }
                                "Container" { $LocalizedData.Container }
                                default { $AzSAContainer.PublicAccess }
                            }
                            $LocalizedData.LeaseState = $AzSAContainer.LeaseState
                        }
                        $AzSAContInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($StorageAccountName)"
                        List = $false
                        ColumnWidths = 40, 20, 20, 20
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