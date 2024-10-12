function Get-AbrAzRouteTable {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Route Table and Routes information
    .DESCRIPTION

    .NOTES
        Version:        0.3.0
        Author:         Howard Hao & Tim Carman
        Twitter:        @tpcarman
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
        Try {
            if ($InfoLevel.RouteTable -gt 0) {
                $AzRouteTables = Get-AzRouteTable | Sort-Object Name
                if ($AzRouteTables) {
                    Write-PscriboMessage "Collecting Azure Route Table information."
                    Section -Style Heading4 'Route Tables' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "Azure Route Tables are a set of custom routes that dictate how network traffic should move within a virtual network (VNet). They offer a way to control the flow of data, ensuring it reaches the correct endpoint. For instance, if a subnet in a VNet needs to communicate with a virtual appliance, an Azure Route Table can direct the traffic accordingly."
                            BlankLine
                        }

                        if ($InfoLevel.RouteTable -ge 3) {
                            Paragraph "The following sections detail the configuration of the Route Tables within the $($AzSubscription.Name) subscription."
                            BlankLine

                            foreach ($AzRouteTable in $AzRouteTables) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRouteTable.Name)" {
                                    $AzRouteTableInfo = @()
                                    $InObj = [Ordered]@{
                                        'Name' = $AzRouteTable.Name
                                        'Resource Group' = $AzRouteTable.ResourceGroupName
                                        'Location' = $AzLocationLookup."$($AzRouteTable.Location)"
                                        'Subscription' = "$($AzSubscriptionLookup.(($AzRouteTable.Id).split('/')[2]))"
                                        'Provisioning State' = $AzRouteTable.ProvisioningState
                                    }

                                    $TableParams = @{
                                        Name = "Route Table - $($AzRouteTable.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Options.ShowTags) {
                                        $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzRouteTable.Tag)) {
                                            'None'
                                        } else {
                                            ($AzRouteTable.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                        }
                                        $TableParams['Columns'] = 'Name', 'Resource Group', 'Location', 'Subscription', 'Tags'
                                    } else {
                                        $TableParams['Columns'] = 'Name', 'Resource Group', 'Location', 'Subscription'
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }

                                    $AzRouteTableInfo += [PSCustomObject]$InObj
                                    $AzRouteTableInfo | Table @TableParams
                                }

                                $AzRoutes = $AzRouteTable.Routes | Sort-Object Name
                                if ($AzRoutes) {
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
                        } else {
                            Paragraph "The following table summarises the configuration of the Route Table within the $($AzSubscription.Name) subscription."
                            BlankLine

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
