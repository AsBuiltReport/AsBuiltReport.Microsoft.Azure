function Get-AbrAzVirtualNetwork {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network information
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
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVirtualNetwork
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.VirtualNetwork)
    }

    process {
        Try {
            if ($InfoLevel.VirtualNetwork -gt 0) {
                $AzVirtualNetworks = Get-AzVirtualNetwork | Sort-Object Name
                if ($AzVirtualNetworks) {
                    Write-PscriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                            if ($InfoLevel.VirtualNetwork -ge 2) {
                                Paragraph -Bold $LocalizedData.Peerings
                                Paragraph $LocalizedData.PeeringsInfo
                                BlankLine
                                Paragraph -Bold $LocalizedData.Subnets
                                Paragraph $LocalizedData.SubnetsInfo
                                BlankLine
                            }
                        }
                        $AzVirtualNetworkInfo = @()
                        foreach ($AzVirtualNetwork in $AzVirtualNetworks) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzVirtualNetwork.Name
                                $LocalizedData.ResourceGroup = $AzVirtualNetwork.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzVirtualNetwork.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzVirtualNetwork.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzVirtualNetwork.Id).split('/')[2]
                                $LocalizedData.ProvisioningState = $AzVirtualNetwork.ProvisioningState
                                $LocalizedData.AddressSpace = if ($AzVirtualNetwork.AddressSpace.AddressPrefixes) {
                                    $AzVirtualNetwork.AddressSpace.AddressPrefixes -join ', '
                                } else {
                                    $LocalizedData.Unknown
                                }
                                $LocalizedData.DnsServers = if ($AzVirtualNetwork.DhcpOptions.DnsServers) {
                                    $AzVirtualNetwork.DhcpOptions.DnsServers -join ', '
                                } else {
                                    $LocalizedData.Default
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzVirtualNetwork.Tag)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzVirtualNetwork.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzVirtualNetworkInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.VirtualNetwork.ProvisioningState) {
                            $AzVirtualNetworkInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.VirtualNetwork.DnsServers) {
                            $AzVirtualNetworkInfo | Where-Object { $_.$($LocalizedData.DnsServers) -eq $LocalizedData.Default } | Set-Style -Style Info -Property $LocalizedData.DnsServers
                        }

                        if ($InfoLevel.VirtualNetwork -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzVirtualNetwork in $AzVirtualNetworkInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzVirtualNetwork.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzVirtualNetwork.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzVirtualNetwork | Table @TableParams

                                    # Virtual Network Peering
                                    Get-AbrAzVirtualNetworkPeering -Name $($AzVirtualNetwork.($LocalizedData.Name))
                                    # Virtual Network Subnets
                                    Get-AbrAzVirtualNetworkSubnet -Name $($AzVirtualNetwork.($LocalizedData.Name))
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.AddressSpace
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
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}