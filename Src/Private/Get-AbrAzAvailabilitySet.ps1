function Get-AbrAzAvailabilitySet {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Availability Set information
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "AvailabilitySet InfoLevel set at $($InfoLevel.AvailabilitySet)."
    }

    process {
        $AzAvailabilitySets = Get-AzAvailabilitySet | Sort-Object Name
        if (($InfoLevel.AvailabilitySet -gt 0) -and ($AzAvailabilitySets)) {
            Write-PscriboMessage "Collecting Azure Availability Set information."
            Section -Style Heading4 'Availability Sets' {
                Paragraph "The following table summarises the configuration of the availability sets within the $($AzSubscription.Name) subscription."
                BlankLine
                $AzAvailabilitySetInfo = @()
                foreach ($AzAvailabilitySet in $AzAvailabilitySets) {
                    $InObj = [Ordered]@{
                        'Name' = $AzAvailabilitySet.Name
                        'Resource Group' = $AzAvailabilitySet.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzAvailabilitySet.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzAvailabilitySet.Id).split('/')[2]))"
                        'SKU' = $AzAvailabilitySet.Sku
                        'Virtual Machines' = & {
                            if ($AzAvailabilitySet.VirtualMachinesReferences.Id) {
                                ($AzAvailabilitySet.VirtualMachinesReferences.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                'None'
                            }
                        }
                    }
                    $AzAvailabilitySetInfo += [PSCustomObject]$InObj
                }

                $TableParams = @{
                    Name = "Availability Sets - $($AzSubscription.Name)"
                    List = $false
                    Columns = 'Name', 'Resource Group', 'Location', 'SKU', 'Virtual Machines'
                    ColumnWidths = 25, 20, 20, 15, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzAvailabilitySetInfo | Table @TableParams
            }
        }
    }

    end {}
}