function Get-AbrAzVirtualNetworkPeering {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Peering information
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
        $LocalizedData = $reportTranslate.GetAbrAzVirtualNetworkPeering
    }

    process {
        Try {
            $AzVirtualNetworkPeerings = (Get-AzVirtualNetwork -Name $Name).VirtualNetworkPeerings | Sort-Object Name
            if ($AzVirtualNetworkPeerings) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $Count = 1
                    foreach ($AzVirtualNetworkPeering in $AzVirtualNetworkPeerings) {
                        Write-PscriboMessage ($LocalizedData.Processing -f ($AzVirtualNetworkPeering.Name),$Count,($AzVirtualNetworkPeerings.Count))
                        $Count ++
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $AzVirtualNetworkPeering.Name {
                            $AzVirtualNetworkPeeringInfo = [PSCustomObject]@{
                                $LocalizedData.Name = $AzVirtualNetworkPeering.Name
                                $LocalizedData.PeeringStatus = $AzVirtualNetworkPeering.PeeringSyncLevel
                                $LocalizedData.PeeringState = $AzVirtualNetworkPeering.PeeringState
                                $LocalizedData.Peer = ($AzVirtualNetworkPeering.RemoteVirtualNetwork.Id).split('/')[-1]
                                $LocalizedData.AddressSpace = $AzVirtualNetworkPeering.RemoteVirtualNetworkAddressSpace.AddressPrefixes -join ', '
                                $LocalizedData.GatewayTransit = if ($AzVirtualNetworkPeering.AllowGatewayTransit) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.TrafficToRemoteVNet = if ($AzVirtualNetworkPeering.AllowVirtualNetworkAccess) {
                                    $LocalizedData.Allow
                                } else {
                                    $LocalizedData.BlockRemoteVnet
                                }
                                $LocalizedData.TrafficForwardedFromRemoteVnet = if ($AzVirtualNetworkPeering.AllowForwardedTraffic) {
                                    $LocalizedData.Allow
                                } else {
                                    $LocalizedData.BlockForwardedTraffic
                                }
                                $LocalizedData.VNetGateway = if ($AzVirtualNetworkPeering.UseRemoteGateways) {
                                    $LocalizedData.UseRemoteVNetGateway
                                } elseif ($AzVirtualNetworkPeering.UseRemoteGateways -eq $false) {
                                    $LocalizedData.UseLocalVnetGateway
                                } elseif (($AzVirtualNetworkPeering.UseRemoteGateways -eq $false) -and ($null -eq $AzVirtualNetworkPeering.RemoteGateways)) {
                                    '--'
                                }

                            }
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzVirtualNetworkPeering.Name)"
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