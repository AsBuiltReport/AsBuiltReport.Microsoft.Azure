function Get-AbrAzAvailabilitySet {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Availability Set information
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
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzAvailabilitySet
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.AvailabilitySet)
    }

    process {
        Try {
            if ($InfoLevel.AvailabilitySet -gt 0) {
                $AzAvailabilitySets = Get-AzAvailabilitySet | Sort-Object Name
                if ($AzAvailabilitySets) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                        BlankLine
                        $AzAvailabilitySetInfo = @()
                        foreach ($AzAvailabilitySet in $AzAvailabilitySets) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzAvailabilitySet.Name
                                $LocalizedData.ResourceGroup = $AzAvailabilitySet.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzAvailabilitySet.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzAvailabilitySet.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzAvailabilitySet.Id).split('/')[2]
                                $LocalizedData.SKU = $AzAvailabilitySet.Sku
                                $LocalizedData.VirtualMachines = if ($AzAvailabilitySet.VirtualMachinesReferences.Id) {
                                    ($AzAvailabilitySet.VirtualMachinesReferences.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                } else {
                                    $LocalizedData.None
                                }
                            }
                            $AzAvailabilitySetInfo += [PSCustomObject]$InObj
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                            List = $false
                            Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.SKU, $LocalizedData.VirtualMachines
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