function Get-AbrAzSATable {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Table information
    .DESCRIPTION

    .NOTES
        Version:        0.2.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
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
        $LocalizedData = $reportTranslate.GetAbrAzSATable
    }

    process {
        Try {
            $AzStorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount -ErrorAction SilentlyContinue
            $AzSATables = Get-AzStorageTable -Context $AzStorageContext -ErrorAction SilentlyContinue | Sort-Object Name
            if ($AzSATables) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSATableInfo = @()
                    $Count = 1
                    foreach ($AzSATable in $AzSATables) {
                        Write-PscriboMessage ($LocalizedData.Processing -f ($AzSATable.Name),$Count,($AzSATables.Count))
                        $Count ++
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzSATable.Name
                            'Url' = $AzSATable.uri.AbsoluteUri
                        }
                        $AzSATableInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($StorageAccountName)"
                        List = $false
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzSATableInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}