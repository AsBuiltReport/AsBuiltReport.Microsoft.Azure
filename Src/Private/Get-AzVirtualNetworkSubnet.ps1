function Get-AbrAzVirtualNetworkSubnet {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Subnet information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    begin {}

    process {
        Try {
            $AzVirtualNetworkSubnets = (Get-AzVirtualNetwork -Name $Name).Subnets | Sort-Object Name
            if ($AzVirtualNetworkSubnets) {
                Write-PscriboMessage "Collecting Azure Virtual Network Subnet information."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Subnets' {
                    foreach ($AzVirtualNetworkSubnet in $AzVirtualNetworkSubnets) {
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzVirtualNetworkSubnet.Name) {
                            $AzVirtualNetworkSubnetInfo = [PSCustomObject]@{
                                'Name' = $AzVirtualNetworkSubnet.Name
                                'Address Range' = $AzVirtualNetworkSubnet.AddressPrefix
                                'NAT Gateway' = if ($AzVirtualNetworkSubnet.NatGateway) {
                                    $AzVirtualNetworkSubnet.NatGateway
                                } else {
                                    'None'
                                }
                                'Network Security Group' = if ($AzVirtualNetworkSubnet.NetworkSecurityGroup.Id) {
                                    ($AzVirtualNetworkSubnet.NetworkSecurityGroup.Id).Split('/')[-1]
                                } else {
                                    'None'
                                }
                                'Route Table' = if ($AzVirtualNetworkSubnet.Name -eq 'AzureBastionSubnet') {
                                    'None'
                                } elseif ($AzVirtualNetworkSubnet.RouteTable.Id) {
                                    ($AzVirtualNetworkSubnet.RouteTable.Id).Split('/')[-1]
                                } else {
                                    'None'
                                }
                            }

                            $TableParams = @{
                                Name = "Subnet - $($AzVirtualNetworkSubnet.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVirtualNetworkSubnetInfo | Table @TableParams
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