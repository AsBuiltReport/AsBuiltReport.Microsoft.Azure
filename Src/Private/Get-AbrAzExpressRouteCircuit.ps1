function Get-AbrAzExpressRouteCircuit {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Express Route Circuit information
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
        Write-PScriboMessage "ExpressRoute InfoLevel set at $($InfoLevel.ExpressRoute)."
    }

    process {
        $AzExpressRouteCircuits = Get-AzExpressRouteCircuit | Sort-Object Name
        if (($InfoLevel.ExpressRoute -gt 0) -and ($AzExpressRouteCircuits)) {
            Write-PscriboMessage "Collecting Express Reoute Circuit information."
            Section -Style Heading2 'Express Route Circuit' {
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
                        'Allow Classic Operations' = Switch ($AzExpressRouteCircuit.AllowClassicOperations) {
                            $true { 'On' }
                            $false { 'Off' }
                        }
                        ##ToDo: Peerings
                    }
                    $AzExpressRouteCircuitInfo += [PSCustomObject]$InObj
                }

                if ($Healthcheck.ExpressRoute.CircuitStatus) {
                    $AzExpressRouteCircuitInfo | Where-Object { $_.'Circuit Status' -ne 'Enabled' } | Set-Style -Style Critical -Property 'Circuit Status'
                }
                if ($InfoLevel.ExpressRoute -ge 2) {
                    Paragraph "The following sections detail the configuration of the express route circuits within the $($AzSubscription.Name) subscription."
                    foreach ($AzExpressRouteCircuit in $AzExpressRouteCircuitInfo) {
                        Section -Style Heading4 "$($AzExpressRouteCircuit.Name)" {
                            $TableParams = @{
                                Name = "Express Route Circuit - $($AzExpressRouteCircuit.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzExpressRouteCircuit | Table @TableParams
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the express route circuits within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Express Route Circuits - $($AzSubscription.Name)"
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

    end {}
}