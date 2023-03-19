function Get-AbrAzVirtualNetwork {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Virtual Network information
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
    )

    begin {
        Write-PScriboMessage "VirtualNetwork InfoLevel set at $($InfoLevel.VirtualNetwork)."
    }

    process {
        $AzVirtualNetworks = Get-AzVirtualNetwork | Sort-Object Name
        if (($InfoLevel.VirtualNetwork -gt 0) -and ($AzVirtualNetworks)) {
            Write-PscriboMessage "Collecting Azure Virtual Network information."
            Section -Style Heading4 'Virtual Networks' {
                if ($Options.ShowSectionInfo) {
                    Paragraph "Azure Virtual Network (VNet) is the fundamental building block for a private network in Azure. VNet enables many types of Azure resources, such as Azure Virtual Machines (VM), to securely communicate with each other, the internet, and on-premises networks. VNet is similar to a traditional network that would operate in a traditonal data center, but brings with it additional benefits of Azure's infrastructure such as scale, availability, and isolation."
                    BlankLine
                    if ($InfoLevel.VirtualNetwork -ge 2) {
                        Paragraph -Bold "Peerings"
                        Paragraph "Virtual network peering enables you to seamlessly connect two or more Virtual Networks in Azure. The virtual networks appear as one for connectivity purposes. The traffic between virtual machines in peered virtual networks uses the Microsoft backbone infrastructure. Like traffic between virtual machines in the same network, traffic is routed through Microsoft's private network only."
                        BlankLine
                        Paragraph -Bold "Subnets"
                        Paragraph "Subnets enable you to segment the virtual network into one or more sub-networks and allocate a portion of the virtual network's address space to each subnet. You can then deploy Azure resources in a specific subnet. Just like in a traditional network, subnets allow you to segment your VNet address space into segments that are appropriate for the organization's internal network. This also improves address allocation efficiency. You can secure resources within subnets using Network Security Groups."
                        BlankLine
                    }
                }
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
                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzVirtualNetwork.Name)" {
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