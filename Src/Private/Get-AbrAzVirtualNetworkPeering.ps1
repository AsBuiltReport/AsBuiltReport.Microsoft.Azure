function Get-AbrAzVirtualNetworkPeering {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Peering information
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
            $AzVirtualNetworkPeerings = (Get-AzVirtualNetwork -Name $Name).VirtualNetworkPeerings | Sort-Object Name
            if ($AzVirtualNetworkPeerings) {
                Write-PscriboMessage "Collecting Azure Virtual Network Peering information."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Peerings' {
                    foreach ($AzVirtualNetworkPeering in $AzVirtualNetworkPeerings) {
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzVirtualNetworkPeering.Name) {
                            $AzVirtualNetworkPeeringInfo = [PSCustomObject]@{
                                'Name' = $AzVirtualNetworkPeering.Name
                                'Peering Status' = $AzVirtualNetworkPeering.PeeringSyncLevel
                                'Peering State' = $AzVirtualNetworkPeering.PeeringState
                                'Peer' = ($AzVirtualNetworkPeering.RemoteVirtualNetwork.Id).split('/')[-1]
                                'Address Space' = $AzVirtualNetworkPeering.RemoteVirtualNetworkAddressSpace.AddressPrefixes -join ', '
                                'Gateway Transit' = if ($AzVirtualNetworkPeering.AllowGatewayTransit) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Traffic to Remote VNet' = if ($AzVirtualNetworkPeering.AllowVirtualNetworkAccess) {
                                    'Allow'
                                } else {
                                    'Block all traffic to the remote virtual network'
                                }
                                'Traffic forwarded from Remote VNet' = if ($AzVirtualNetworkPeering.AllowForwardedTraffic) {
                                    'Allow'
                                } else {
                                    'Block traffic that originates from outside this network'
                                }
                                'VNet Gateway or Route Server' = if ($AzVirtualNetworkPeering.UseRemoteGateways) {
                                    "Use the remote virtual network's gateway or Route Server"
                                } elseif ($AzVirtualNetworkPeering.UseRemoteGateways -eq $false) {
                                    "Use this virtual network's gateway or Route Server"
                                } elseif (($AzVirtualNetworkPeering.UseRemoteGateways -eq $false) -and ($null -eq $AzVirtualNetworkPeering.RemoteGateways)) {
                                    'None'
                                }

                            }
                            $TableParams = @{
                                Name = "Peering - $($AzVirtualNetworkPeering.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVirtualNetworkPeeringInfo | Table @TableParams
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