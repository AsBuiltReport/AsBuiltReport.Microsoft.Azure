function Get-AbrAzVirtualNetwork {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Virtual Network information
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
        Write-PScriboMessage "VirtualNetwork InfoLevel set at $($InfoLevel.VirtualNetwork)."
    }

    process {
        $AzVirtualNetworks = Get-AzVirtualNetwork | Sort-Object Name
        if (($InfoLevel.VirtualNetwork -gt 0) -and ($AzVirtualNetworks)) {
            Write-PscriboMessage "Collecting Azure Virtual Network information."
            Section -Style Heading4 'Virtual Networks' {
                $AzVirtualNetworkInfo = @()
                foreach ($AzVirtualNetwork in $AzVirtualNetworks) {
                    $InObj = [Ordered]@{
                        'Name' = $AzVirtualNetwork.Name
                        'Resource Group' = $AzVirtualNetwork.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzVirtualNetwork.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzVirtualNetwork.Id).split('/')[2]))"
                        'Provisioning State' = $AzVirtualNetwork.ProvisioningState
                        'Address Space' = & {
                            if ($AzVirtualNetwork.AddressSpace.AddressPrefixes) {
                                $AzVirtualNetwork.AddressSpace.AddressPrefixes -join ', '
                            } else {
                                'None'
                            }
                        }
                        'DNS Servers' = & {
                            if ($AzVirtualNetwork.DhcpOptions.DnsServers) {
                                $AzVirtualNetwork.DhcpOptions.DnsServers -join ', '
                            } else {
                                'None'
                            }
                        }
                    }
                    $AzVirtualNetworkInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.VirtualNetwork -ge 2) {
                    Paragraph "The following sections detail the configuration of the virtual networks within the $($AzSubscription.Name) subscription."
                    foreach ($AzVirtualNetwork in $AzVirtualNetworkInfo) {
                        Section -Style Heading5 "$($AzVirtualNetwork.Name)" {
                            $TableParams = @{
                                Name = "Virtual Network - $($AzVirtualNetwork.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVirtualNetwork | Table @TableParams

                            # Virtual Network Peering
                            Get-AbrAzVirtualNetworkPeering -Name $AzVirtualNetwork.Name
                            # Virtual Network Subnets
                            Get-AbrAzVirtualNetworkSubnet -Name $AzVirtualNetwork.Name
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the virtual networks within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Virtual Networks - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'Address Space'
                        ColumnWidths = 25, 25, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzVirtualNetworkInfo | Table @TableParams
                }
            }
        }
    }

    end {}
}