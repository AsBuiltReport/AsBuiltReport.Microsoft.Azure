function Get-AbrAzSAQueue {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Storage Account Queue information
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
        $LocalizedData = $reportTranslate.GetAbrAzSAQueue
    }

    process {
        Try {
            $AzStorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount -ErrorAction SilentlyContinue
            $AzSAQueues = Get-AzStorageQueue -Context $AzStorageContext -ErrorAction SilentlyContinue | Sort-Object Name
            if ($AzSAQueues) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzSAQueueInfo = @()
                    $Count = 1
                    foreach ($AzSAQueue in $AzSAQueues) {
                        Write-PscriboMessage ($LocalizedData.Processing -f ($AzSAQueue.Name),$Count,($AzSAQueues.Count))
                        $Count ++
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzSAQueue.Name
                            'Url' = $AzSAQueue.uri.AbsoluteUri
                        }
                        $AzSAQueueInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($StorageAccountName)"
                        List = $false
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzSAQueueInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}