function Get-AbrAzExpressRouteCircuit {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure ExpressRoute Circuit information
    .DESCRIPTION

    .NOTES
        Version:        0.1.2
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
        Write-PScriboMessage "ExpressRoute InfoLevel set at $($InfoLevel.ExpressRoute)."
    }

    process {
        Try {
            if ($InfoLevel.ExpressRoute -gt 0) {
                $AzExpressRouteCircuits = Get-AzExpressRouteCircuit | Sort-Object Name
                if ($AzExpressRouteCircuits) {
                    Write-PScriboMessage "Collecting ExpressRoute Circuit information."
                    Section -Style Heading4 'ExpressRoute Circuit' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "An ExpressRoute circuit allows a private dedicated connection into Azure with the help of a connectivity provider."
                            BlankLine
                        }
                        $AzExpressRouteCircuitInfo = @()
                        foreach ($AzExpressRouteCircuit in $AzExpressRouteCircuits) {
                            $InObj = [Ordered]@{
                                'Name' = $AzExpressRouteCircuit.Name
                                'Resource Group' = $AzExpressRouteCircuit.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzExpressRouteCircuit.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzExpressRouteCircuit.Id).split('/')[2]))"
                                'Circuit Status' = $AzExpressRouteCircuit.CircuitProvisioningState
                                'Provider' = $AzExpressRouteCircuit.ServiceProviderProperties.ServiceProviderName
                                'Provider Status' = $AzExpressRouteCircuit.ServiceProviderProvisioningState
                                'Peering Location' = $AzExpressRouteCircuit.ServiceProviderProperties.PeeringLocation
                                'Bandwidth' = "$($AzExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps) Mbps"
                                'Service Key' = $AzExpressRouteCircuit.ServiceKey
                                'SKU' = $AzExpressRouteCircuit.Sku.Tier
                                'Billing Model' = Switch ($AzExpressRouteCircuit.Sku.Family) {
                                    'MeteredData' { 'Metered' }
                                    default { $AzExpressRouteCircuit.Sku.Family }
                                }
                                'Allow Classic Operations' = if ($AzExpressRouteCircuit.AllowClassicOperations) {
                                    'On'
                                } else {
                                    'Off'
                                }
                                ##ToDo: Peerings
                            }

                            if ($Options.ShowTags) {
                                $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzExpressRouteCircuit.Tags)) {
                                    'None'
                                } else {
                                    ($AzExpressRouteCircuit.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzExpressRouteCircuitInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.ExpressRoute.CircuitStatus) {
                            $AzExpressRouteCircuitInfo | Where-Object { $_.'Circuit Status' -ne 'Enabled' } | Set-Style -Style Critical -Property 'Circuit Status'
                        }
                        if ($InfoLevel.ExpressRoute -ge 2) {
                            Paragraph "The following sections detail the configuration of the ExpressRoute circuits within the $($AzSubscription.Name) subscription."
                            foreach ($AzExpressRouteCircuit in $AzExpressRouteCircuitInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzExpressRouteCircuit.Name)" {
                                    $TableParams = @{
                                        Name = "ExpressRoute Circuit - $($AzExpressRouteCircuit.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzExpressRouteCircuit | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph "The following table summarises the configuration of the ExpressRoute circuits within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "ExpressRoute Circuits - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Resource Group', 'Location', 'Circuit Status'
                                ColumnWidths = 25, 25, 25, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzExpressRouteCircuitInfo | Table @TableParams
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}