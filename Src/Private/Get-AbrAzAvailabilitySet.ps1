function Get-AbrAzAvailabilitySet {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Availability Set information
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
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
        Try {
            if ($InfoLevel.AvailabilitySet -gt 0) {
                $AzAvailabilitySets = Get-AzAvailabilitySet | Sort-Object Name
                if ($AzAvailabilitySets) {
                    Write-PscriboMessage "Collecting Azure Availability Set information."
                    Section -Style Heading4 'Availability Sets' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "An Availability Set (AS) is a logical construct to inform Azure that it should distribute contained virtual machine instances across multiple fault and update domains within an Azure region."
                            BlankLine
                        }
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
                                'Virtual Machines' = if ($AzAvailabilitySet.VirtualMachinesReferences.Id) {
                                    ($AzAvailabilitySet.VirtualMachinesReferences.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                } else {
                                    'None'
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
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}