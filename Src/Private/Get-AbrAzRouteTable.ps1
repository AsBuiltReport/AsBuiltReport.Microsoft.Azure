function Get-AbrAzRouteTable {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Route Table and Routes information
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
        Author:         Howard Hao
        Twitter:
        Github:         howardhaooooo
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
                    Paragraph "Azure Route Table is a powerful tool to control and direct traffic within a virtual network (VNet). It offers a way to control the flow of the data, ensuring it reaches the correct endpoint."
                    BlankLine
                }
                $AzRouteTableInfo = @()
                foreach ($AzRouteTable in $AzRouteTables) {
                    $routes= $AzRouteTable.routes
                    foreach ($route in $routes){
                    $InObj = [Ordered]@{
                        'Name' = $AzRouteTable.Name
                        'Resource Group' = $AzRouteTable.ResourceGroupName
                        'Location' = $AzRouteTable.Location
                        'Subscription' = $AzRouteTable.Id.split('/')[2]
                        'Provisioning State' = $AzRouteTable.ProvisioningState
                        'Routes' = $route.Name
                        'Address Prefix' = $route.AddressPrefix
                        'Next Hop Type' = $route.NextHopType
                        'Next Hop IpAddress' = $route.NextHopIpAddress
                    }
                    $AzRouteTableInfo += [PSCustomObject]$InObj
                }}

                if ($InfoLevel.RouteTable -ge 2) {
                    Paragraph "The following sections detail the configuration of the Route Tables within the $($AzSubscription.Name) subscription."
                    foreach ($AzRouteTable in $AzRouteTables) {
                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRouteTable.Name)" {
                            $TableParams = @{
                                Name = "Route Table - $($AzRouteTable.Name)"
                                List = $true
                                ColumnWidths = 30, 70
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzRouteTable | Table @TableParams
                        }
                    }
                    } else {
                        Paragraph "The following table summarises the configuration of the Route Table within the $($AzSubscription.Name) subscription."
                        BlankLine
                        $TableParams = @{
                        Name = "Route Tables - $($AzSubscription.Name)"
                        List = $false
                        Headers = 'Name','Routes','Address','Next Hop','IpAddress'
                        Columns = 'Name', 'Routes','Address Prefix','Next Hop Type','Next Hop IpAddress'
                        ColumnWidths = 14,14,15,15,14,14,14
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                        $AzRouteTableInfo|Table @TableParams
                }
            }
        }
    }

    end {}
}