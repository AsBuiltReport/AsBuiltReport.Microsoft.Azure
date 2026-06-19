function Get-AbrAzSAShare {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Share information
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
        $LocalizedData = $reportTranslate.GetAbrAzSAShare
    }

    process {
        Try {
            $AzSAShares = Get-AzRmStorageShare -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -ErrorAction SilentlyContinue | Where-Object { -not $_.SnapshotTime } | Sort-Object Name
            if ($AzSAShares) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSAShareInfo = @()
                    $Count = 1
                    foreach ($AzSAShare in $AzSAShares) {
                        Write-PscriboMessage ($LocalizedData.Processing -f ($AzSAShare.Name),$Count,($AzSAShares.Count))
                        $Count ++
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzSAShare.Name
                            $LocalizedData.ShareURL = "https://$StorageAccountName.file.core.windows.net/$($AzSAShare.Name)"
                            $LocalizedData.Quota = $(if ($null -eq $AzSAShare.QuotaGiB) {
                                $LocalizedData.Unknown
                            } else {
                                Convert-DataSize -Size ($AzSAShare.QuotaGiB)
                            })
                            $LocalizedData.AccessTier = Switch ($AzSAShare.AccessTier) {
                                'TransactionOptimized' { $LocalizedData.TransactionOptimized }
                                $null { $LocalizedData.None }
                                default { $AzSAShare.AccessTier }
                            }
                            $LocalizedData.LastModified = if ($AzSAShare.LastModifiedTime) {
                                $AzSAShare.LastModifiedTime.ToShortDateString()
                            } else {
                                $LocalizedData.None
                            }
                            $LocalizedData.Snapshot = $(if ($AzSAShare.SnapshotTime) {
                                $LocalizedData.Enabled
                            } else {
                                $LocalizedData.Disabled
                            })
                        }
                        $AzSAShareInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($StorageAccountName)"
                        List = $false
                        Columns = $LocalizedData.Name, $LocalizedData.AccessTier, $LocalizedData.Quota, $LocalizedData.LastModified, $LocalizedData.Snapshot
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