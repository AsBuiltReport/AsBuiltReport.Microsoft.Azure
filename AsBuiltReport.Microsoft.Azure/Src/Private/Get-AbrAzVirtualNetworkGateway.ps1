function Get-AbrAzVirtualNetworkGateway {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Gateway information
    .DESCRIPTION
        Documents the configuration of Azure Virtual Network Gateways including gateway type,
        SKU, BGP settings, active-active mode, and VPN connections.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param ()

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVirtualNetworkGateway
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.VirtualNetworkGateway)
    }

    process {
        try {
            if ($InfoLevel.VirtualNetworkGateway -ge 1) {
                $AzVNetGateways = Get-AzResource -ResourceType 'Microsoft.Network/virtualNetworkGateways' -ErrorAction SilentlyContinue |
                    ForEach-Object { Get-AzVirtualNetworkGateway -Name $_.Name -ResourceGroupName $_.ResourceGroupName } |
                    Sort-Object Name
                if ($AzVNetGateways) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        # Pre-collect all connections in the subscription for InfoLevel 2 detail
                        $ConnectionsMap = @{}
                        if ($InfoLevel.VirtualNetworkGateway -ge 2) {
                            $AllConnections = Get-AzResource -ResourceType 'Microsoft.Network/connections' -ErrorAction SilentlyContinue |
                                ForEach-Object { Get-AzVirtualNetworkGatewayConnection -Name $_.Name -ResourceGroupName $_.ResourceGroupName -ErrorAction SilentlyContinue }
                            foreach ($AzVNetGateway in $AzVNetGateways) {
                                $ConnectionsMap[$AzVNetGateway.Name] = $AllConnections | Where-Object { $_.VirtualNetworkGateway1.Id -eq $AzVNetGateway.Id }
                            }
                        }

                        $LockMap = @{}
                        $AllLocks = Get-AzResourceLock -ErrorAction SilentlyContinue
                        foreach ($Lock in $AllLocks) {
                            $Key = $Lock.ResourceId.ToLower()
                            if (-not $LockMap.ContainsKey($Key)) { $LockMap[$Key] = @() }
                            $LockMap[$Key] += $Lock
                        }

                        $AzVNetGatewayInfo = @()
                        foreach ($AzVNetGateway in $AzVNetGateways) {
                            $VirtualNetwork = if ($AzVNetGateway.IpConfigurations -and $AzVNetGateway.IpConfigurations[0].Subnet.Id) {
                                ($AzVNetGateway.IpConfigurations[0].Subnet.Id).split('/')[8]
                            } else {
                                $LocalizedData.None
                            }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name              = $AzVNetGateway.Name
                                $LocalizedData.ResourceGroup     = $AzVNetGateway.ResourceGroupName
                                $LocalizedData.Location          = $AzLocationLookup."$($AzVNetGateway.Location)"
                                $LocalizedData.Subscription      = "$($AzSubscriptionLookup.(($AzVNetGateway.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID    = ($AzVNetGateway.Id).split('/')[2]
                                $LocalizedData.VirtualNetwork    = $VirtualNetwork
                                $LocalizedData.GatewayType       = $AzVNetGateway.GatewayType
                                $LocalizedData.VpnType           = if ($AzVNetGateway.GatewayType -eq 'Vpn') { $AzVNetGateway.VpnType } else { $LocalizedData.NotApplicable }
                                $LocalizedData.SKU               = $AzVNetGateway.Sku.Name
                                $LocalizedData.Generation        = if ($AzVNetGateway.VpnGatewayGeneration -and $AzVNetGateway.VpnGatewayGeneration -ne 'None') { $AzVNetGateway.VpnGatewayGeneration } else { $LocalizedData.NotApplicable }
                                $LocalizedData.ActiveActive      = $AzVNetGateway.ActiveActive
                                $LocalizedData.EnableBgp         = $AzVNetGateway.EnableBgp
                                $LocalizedData.BgpAsn            = if ($AzVNetGateway.EnableBgp) { $AzVNetGateway.BgpSettings.Asn } else { $LocalizedData.NotApplicable }
                                $LocalizedData.BgpPeeringAddress = if ($AzVNetGateway.EnableBgp) { $AzVNetGateway.BgpSettings.BgpPeeringAddress } else { $LocalizedData.NotApplicable }
                                $LocalizedData.ProvisioningState = $AzVNetGateway.ProvisioningState
                            }

                            $InObj[$LocalizedData.Locks] = $(
                                $rl = $LockMap[$AzVNetGateway.Id.ToLower()]
                                if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                else { $LocalizedData.None }
                            )

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzVNetGateway.Tag -or $AzVNetGateway.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzVNetGateway.Tag.Keys | ForEach-Object { "$_`:`t$($AzVNetGateway.Tag[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzVNetGatewayInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.VirtualNetworkGateway.ProvisioningState) {
                            $AzVNetGatewayInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.VirtualNetworkGateway -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzVNetGateway in $AzVNetGatewayInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzVNetGateway.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $($AzVNetGateway.($LocalizedData.Name))"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzVNetGateway | Table @TableParams

                                    $AzGatewayName = $AzVNetGateway.($LocalizedData.Name)
                                    $Connections = $ConnectionsMap[$AzGatewayName]
                                    if ($Connections) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Connections {
                                            $ConnectionInfo = @()
                                            foreach ($Connection in $Connections) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.ConnectionName     = $Connection.Name
                                                    $LocalizedData.ConnectionType     = $Connection.ConnectionType
                                                    $LocalizedData.ConnectionStatus   = $Connection.ConnectionStatus
                                                    $LocalizedData.ConnectionProtocol = if ($Connection.ConnectionProtocol) { $Connection.ConnectionProtocol } else { $LocalizedData.NotApplicable }
                                                    $LocalizedData.RoutingWeight      = $Connection.RoutingWeight
                                                    $LocalizedData.EnableBgp          = $Connection.EnableBgp
                                                    $LocalizedData.ProvisioningState  = $Connection.ProvisioningState
                                                }
                                                $ConnectionInfo += [PSCustomObject]$InObj
                                            }

                                            if ($Healthcheck.VirtualNetworkGateway.ConnectionStatus) {
                                                $ConnectionInfo | Where-Object { $_.$($LocalizedData.ConnectionStatus) -ne 'Connected' } | Set-Style -Style Warning -Property $LocalizedData.ConnectionStatus
                                            }

                                            $TableParams = @{
                                                Name         = "$($LocalizedData.Connections) - $($AzGatewayName)"
                                                List         = $false
                                                ColumnWidths = 25, 15, 15, 15, 10, 10, 10
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $ConnectionInfo | Table @TableParams
                                        }
                                    }
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.GatewayType, $LocalizedData.SKU, $LocalizedData.ProvisioningState
                                ColumnWidths = 25, 20, 15, 15, 10, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVNetGatewayInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($LocalizedData.ErrorMessage) $($_.Exception.Message)"
        }
    }

    end {}
}
