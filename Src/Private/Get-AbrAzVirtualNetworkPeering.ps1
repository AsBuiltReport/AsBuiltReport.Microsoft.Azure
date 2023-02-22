function Get-AbrAzVirtualNetworkPeering {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Virtual Network Peering information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    begin {}

    process {
        $AzVirtualNetworkPeerings = (Get-AzVirtualNetwork -Name $Name).VirtualNetworkPeerings | Sort-Object Name
        if ($AzVirtualNetworkPeerings) {
            Write-PscriboMessage "Collecting Azure Virtual Network Peering information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Peerings' {
                foreach ($AzVirtualNetworkPeering in $AzVirtualNetworkPeerings) {
                    Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzVirtualNetworkPeering.Name) {
                        $AzVirtualNetworkPeeringInfo = [PSCustomObject]@{
                            'Name' = $AzVirtualNetworkPeering.Name
                            'Resource Group' = $AzVirtualNetworkPeering.ResourceGroupName
                            #'Location' = $AzVirtualNetworkPeering.Location
                            'Peering Status' = $AzVirtualNetworkPeering.PeeringSyncLevel
                            'Peering State' = $AzVirtualNetworkPeering.PeeringState
                            'Peer' = ($AzVirtualNetworkPeering.RemoteVirtualNetwork.Id).split('/')[-1]
                            'Address Space' = $AzVirtualNetworkPeering.RemoteVirtualNetworkAddressSpace.AddressPrefixes -join ', '
                            'Gateway Transit' = Switch ($AzVirtualNetworkPeering.AllowGatewayTransit) {
                                $true { 'Enabled' }
                                $false { 'Disabled' }
                            }
                            'Traffic to Remote VNet' = Switch ($AzVirtualNetworkPeering.AllowVirtualNetworkAccess) {
                                $true { 'Allow' }
                                $false { 'Block all traffic to the remote virtual network' }
                            }
                            'Traffic forwarded from Remote VNet' = Switch ($AzVirtualNetworkPeering.AllowForwardedTraffic) {
                                $true { 'Allow' }
                                $false { 'Block traffic that originates from outside this network' }
                            }
                            'VNet Gateway or Route Server' = & {
                                if ($AzVirtualNetworkPeering.UseRemoteGateways) {
                                    "Use the remote virtual network's gateway or Route Server"
                                } elseif ($AzVirtualNetworkPeering.UseRemoteGateways -eq $false) {
                                    "Use this virtual network's gateway or Route Server"
                                } elseif (($AzVirtualNetworkPeering.UseRemoteGateways -eq $false) -and ($null -eq $AzVirtualNetworkPeering.RemoteGateways)) {
                                    'None'
                                }
                            }

                        }
                        $TableParams = @{
                            Name = "Peering - $($AzVirtualNetworkPeering.Name)"
                            List = $true
                            ColumnWidths = 50, 50
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzVirtualNetworkPeeringInfo | Table @TableParams
                    }
                }
            }
        }
    }

    end {}
}