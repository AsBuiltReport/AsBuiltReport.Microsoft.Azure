function Get-AbrAzRouteTable {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Route Table and Routes information
    .DESCRIPTION

    .NOTES
        Version:        0.2
        Author:         Howard Hao & Tim Carman
        Twitter:        tpcarman
        Github:         howardhaooooo / tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "RouteTable InfoLevel set at $($InfoLevel.RouteTable)."
    }

    process {
        $AzRouteTables = Get-AzRouteTable | Sort-Object Name
        if (($InfoLevel.RouteTable -gt 0) -and ($AzRouteTables)) {
            Write-PscriboMessage "Collecting Azure Route Table information."
            Section -Style Heading4 'Route Tables' {
                if ($Options.ShowSectionInfo) {
                    Paragraph "Azure Route Tables are a set of custom routes that dictate how network traffic should move within a virtual network (VNet). They offer a way to control the flow of data, ensuring it reaches the correct endpoint. For instance, if a subnet in a VNet needs to communicate with a virtual appliance, an Azure Route Table can direct the traffic accordingly."
                    BlankLine
                }
                $AzRouteTableInfo = @()
                foreach ($AzRouteTable in $AzRouteTables) {
                    $InObj = [Ordered]@{
                        'Name' = $AzRouteTable.Name
                        'Resource Group' = $AzRouteTable.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzRouteTable.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzRouteTable.Id).split('/')[2]))"
                        'Provisioning State' = $AzRouteTable.ProvisioningState
                    }
                    $AzRouteTableInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.RouteTable -eq 1) {
                    Paragraph "The following table summarises the configuration of the Route Table within the $($AzSubscription.Name) subscription."
                    BlankLine
                } else {
                    Paragraph "The following sections detail the configuration of the Route Tables within the $($AzSubscription.Name) subscription."
                    BlankLine
                }
                $TableParams = @{
                    Name = "Route Tables - $($AzSubscription.Name)"
                    List = $false
                    Columns = 'Name', 'Resource Group', 'Location', 'Subscription'
                    ColumnWidths = 25, 25, 25, 25
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzRouteTableInfo | Table @TableParams

                if ($InfoLevel.RouteTable -ge 2) {
                    foreach ($AzRouteTable in $AzRouteTables) {
                        $AzRoutes = $AzRouteTable.Routes | Sort-Object Name
                        if ($AzRoutes) {
                            Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRouteTable.Name)" {
                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Routes" {
                                    $AzRouteInfo = @()
                                    foreach ($AzRoute in $AzRoutes){
                                        $InObj = [Ordered]@{
                                            'Name' = $AzRoute.Name
                                            'Address Prefix' = $AzRoute.AddressPrefix
                                            'Next Hop Type' = $AzRoute.NextHopType
                                            'Next Hop IP Address' = Switch ($AzRoute.NextHopIpAddress) {
                                                "" { '--' }
                                                default { $AzRoute.NextHopIpAddress }
                                            }
                                        }
                                        $AzRouteInfo += [PSCustomObject]$InObj
                                    }
                                    $TableParams = @{
                                        Name = "Routes - $($AzRouteTable.Name)"
                                        List = $false
                                        ColumnWidths = 25, 25, 25, 25
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRouteInfo | Table @TableParams
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    end {}
}
