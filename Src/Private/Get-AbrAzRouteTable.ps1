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

                if ($InfoLevel.RouteTable -ge 2) { #Comprehensive and details info,add provisioning state and subscription
                    Paragraph "The following table summarises the configuration of the Route Table within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Route Tables - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'Subscription','Provisioning State','Routes','Address','Next Hop Type','Next Hop IpAddress'
                        ColumnWidths = 11,11,11,12,11,11,11,11,11
                    }
                       if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                  }
                                $AzRouteTableInfo | Table @TableParams
                                } else {
                                       Paragraph "The following table summarises the configuration of the Route Table within the $($AzSubscription.Name) subscription."
                                       BlankLine
                                       $TableParams = @{
                                             Name = "Route Tables - $($AzSubscription.Name)"
                                             List = $false
                                             Columns = 'Name', 'Resource Group', 'Location', 'Routes','Address','Next Hop Type','Next Hop IpAddress'
                                             ColumnWidths = 14,14,15,15,14,14,14
                                            }
                                   if ($Report.ShowTableCaptions) {
                                              $TableParams['Caption'] = "- $($TableParams.Name)"
                                              }
                                    $AzRouteTableInfo |Select-Object -ExcludeProperty 'Subscription' -Property *|Select-Object -ExcludeProperty 'Provisioning State' -Property * | Table @TableParams
                }
            }
        }
    }

    end {}
}