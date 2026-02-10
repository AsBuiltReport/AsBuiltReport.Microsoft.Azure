function Get-AbrAzVirtualNetworkSubnet {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Subnet information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVirtualNetworkSubnet
    }

    process {
        Try {
            $AzVirtualNetworkSubnets = (Get-AzVirtualNetwork -Name $Name).Subnets | Sort-Object Name
            if ($AzVirtualNetworkSubnets) {
                Write-PscriboMessage $LocalizedData.Collecting
                $Count = 1
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    foreach ($AzVirtualNetworkSubnet in $AzVirtualNetworkSubnets) {
                        Write-PscriboMessage ($LocalizedData.Processing -f ($AzVirtualNetworkSubnet.Name),$Count,($AzVirtualNetworkSubnets.Count))
                        $Count ++
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $AzVirtualNetworkSubnet.Name {
                            $AzVirtualNetworkSubnetInfo = [PSCustomObject]@{
                                $LocalizedData.Name = $AzVirtualNetworkSubnet.Name
                                $LocalizedData.AddressRange = $AzVirtualNetworkSubnet.AddressPrefix
                                $LocalizedData.NatGateway = $(if ($AzVirtualNetworkSubnet.NatGateway) {
                                    $AzVirtualNetworkSubnet.NatGateway
                                } else {
                                    $LocalizedData.None
                                })
                                $LocalizedData.NetworkSecurityGroup = $(if ($AzVirtualNetworkSubnet.NetworkSecurityGroup.Id) {
                                    ($AzVirtualNetworkSubnet.NetworkSecurityGroup.Id).Split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                })
                                $LocalizedData.RouteTable = $(if ($AzVirtualNetworkSubnet.Name -eq 'AzureBastionSubnet') {
                                    $LocalizedData.None
                                } elseif ($AzVirtualNetworkSubnet.RouteTable.Id) {
                                    ($AzVirtualNetworkSubnet.RouteTable.Id).Split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                })
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzVirtualNetworkSubnet.Name)"
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