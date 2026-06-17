function Get-AbrAzApplicationGateway {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Application Gateway information
    .DESCRIPTION
        Documents the configuration of Azure Application Gateways including SKU, WAF settings,
        HTTP listeners, backend address pools, and request routing rules.
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
        $LocalizedData = $reportTranslate.GetAbrAzApplicationGateway
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.ApplicationGateway)
    }

    process {
        try {
            if ($InfoLevel.ApplicationGateway -ge 1) {
                $AzAppGateways = Get-AzApplicationGateway -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzAppGateways) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzAppGatewayInfo = @()
                        foreach ($AzAppGw in $AzAppGateways) {
                            $SubnetId = if ($AzAppGw.GatewayIPConfigurations -and $AzAppGw.GatewayIPConfigurations[0].Subnet.Id) {
                                $AzAppGw.GatewayIPConfigurations[0].Subnet.Id
                            } else { $null }
                            $VirtualNetwork = if ($SubnetId) { $SubnetId.split('/')[8] } else { $LocalizedData.None }
                            $Subnet         = if ($SubnetId) { $SubnetId.split('/')[-1] } else { $LocalizedData.None }

                            $Capacity = if ($AzAppGw.AutoscaleConfiguration) {
                                $MaxCap = if ($null -ne $AzAppGw.AutoscaleConfiguration.MaxCapacity) {
                                    $AzAppGw.AutoscaleConfiguration.MaxCapacity
                                } else {
                                    $LocalizedData.Unlimited
                                }
                                "$($AzAppGw.AutoscaleConfiguration.MinCapacity) - $MaxCap"
                            } else {
                                [string]$AzAppGw.Sku.Capacity
                            }

                            $WafEnabled = $AzAppGw.FirewallPolicy -or (
                                $AzAppGw.WebApplicationFirewallConfiguration -and $AzAppGw.WebApplicationFirewallConfiguration.Enabled
                            )
                            $WafMode = if ($AzAppGw.WebApplicationFirewallConfiguration) {
                                $AzAppGw.WebApplicationFirewallConfiguration.FirewallMode
                            } elseif ($AzAppGw.FirewallPolicy) {
                                'Policy'
                            } else {
                                $LocalizedData.NotApplicable
                            }

                            $FrontendIPs = ($AzAppGw.FrontendIPConfigurations | ForEach-Object {
                                if ($_.PublicIPAddress) {
                                    "Public: $(($_.PublicIPAddress.Id).split('/')[-1])"
                                } elseif ($_.PrivateIPAddress) {
                                    "Private: $($_.PrivateIPAddress)"
                                }
                            }) -join [Environment]::NewLine

                            $InObj = [Ordered]@{
                                $LocalizedData.Name              = $AzAppGw.Name
                                $LocalizedData.ResourceGroup     = $AzAppGw.ResourceGroupName
                                $LocalizedData.Location          = $AzLocationLookup."$($AzAppGw.Location)"
                                $LocalizedData.Subscription      = "$($AzSubscriptionLookup.(($AzAppGw.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID    = ($AzAppGw.Id).split('/')[2]
                                $LocalizedData.VirtualNetwork    = $VirtualNetwork
                                $LocalizedData.Subnet            = $Subnet
                                $LocalizedData.SKU               = $AzAppGw.Sku.Name
                                $LocalizedData.Tier              = $AzAppGw.Sku.Tier
                                $LocalizedData.Capacity          = $Capacity
                                $LocalizedData.WafEnabled        = $WafEnabled
                                $LocalizedData.WafMode           = $WafMode
                                $LocalizedData.Http2Enabled      = $AzAppGw.EnableHttp2
                                $LocalizedData.FrontendIPs       = if ($FrontendIPs) { $FrontendIPs } else { $LocalizedData.None }
                                $LocalizedData.OperationalState  = $AzAppGw.OperationalState
                                $LocalizedData.ProvisioningState = $AzAppGw.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzAppGw.Tags -or $AzAppGw.Tags.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzAppGw.Tags.Keys | ForEach-Object { "$_`:`t$($AzAppGw.Tags[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzAppGatewayInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.ApplicationGateway.ProvisioningState) {
                            $AzAppGatewayInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.ApplicationGateway.OperationalState) {
                            $AzAppGatewayInfo | Where-Object { $_.$($LocalizedData.OperationalState) -ne 'Running' } | Set-Style -Style Warning -Property $LocalizedData.OperationalState
                        }

                        if ($InfoLevel.ApplicationGateway -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzAppGwItem in $AzAppGatewayInfo) {
                                $GwName = $AzAppGwItem.($LocalizedData.Name)
                                $GwRg   = $AzAppGwItem.($LocalizedData.ResourceGroup)
                                $FullGw = $AzAppGateways | Where-Object { $_.Name -eq $GwName -and $_.ResourceGroupName -eq $GwRg }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $GwName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $GwName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzAppGwItem | Table @TableParams

                                    if ($FullGw.HttpListeners) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Listeners {
                                            $PortLookup = @{}
                                            foreach ($FrontendPort in $FullGw.FrontendPorts) {
                                                $PortLookup[$FrontendPort.Id] = $FrontendPort.Port
                                            }
                                            $ListenerInfo = @()
                                            foreach ($Listener in $FullGw.HttpListeners) {
                                                $Port = if ($Listener.FrontendPort.Id -and $PortLookup.ContainsKey($Listener.FrontendPort.Id)) {
                                                    $PortLookup[$Listener.FrontendPort.Id]
                                                } else {
                                                    $LocalizedData.NotApplicable
                                                }
                                                $HostNames = if ($Listener.HostNames -and $Listener.HostNames.Count -gt 0) {
                                                    $Listener.HostNames -join ', '
                                                } elseif ($Listener.HostName) {
                                                    $Listener.HostName
                                                } else {
                                                    $LocalizedData.None
                                                }
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.ListenerName = $Listener.Name
                                                    $LocalizedData.Protocol     = $Listener.Protocol
                                                    $LocalizedData.Port         = $Port
                                                    $LocalizedData.HostName     = $HostNames
                                                }
                                                $ListenerInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.Listeners) - $GwName"
                                                List         = $false
                                                ColumnWidths = 30, 15, 10, 45
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $ListenerInfo | Table @TableParams
                                        }
                                    }

                                    if ($FullGw.BackendAddressPools) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.BackendPools {
                                            $PoolInfo = @()
                                            foreach ($Pool in $FullGw.BackendAddressPools) {
                                                $Targets = if ($Pool.BackendAddresses -and $Pool.BackendAddresses.Count -gt 0) {
                                                    ($Pool.BackendAddresses | ForEach-Object {
                                                        if ($_.Fqdn) { $_.Fqdn } elseif ($_.IpAddress) { $_.IpAddress }
                                                    }) -join [Environment]::NewLine
                                                } else {
                                                    $LocalizedData.None
                                                }
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.PoolName       = $Pool.Name
                                                    $LocalizedData.BackendTargets = $Targets
                                                }
                                                $PoolInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.BackendPools) - $GwName"
                                                List         = $false
                                                ColumnWidths = 30, 70
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $PoolInfo | Table @TableParams
                                        }
                                    }

                                    if ($FullGw.RequestRoutingRules) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.RoutingRules {
                                            $RuleInfo = @()
                                            foreach ($Rule in $FullGw.RequestRoutingRules) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.RuleName            = $Rule.Name
                                                    $LocalizedData.RuleType            = $Rule.RuleType
                                                    $LocalizedData.ListenerName        = if ($Rule.HttpListener.Id) { ($Rule.HttpListener.Id).split('/')[-1] } else { $LocalizedData.None }
                                                    $LocalizedData.BackendPool         = if ($Rule.BackendAddressPool.Id) { ($Rule.BackendAddressPool.Id).split('/')[-1] } else { $LocalizedData.None }
                                                    $LocalizedData.BackendHttpSettings = if ($Rule.BackendHttpSettings.Id) { ($Rule.BackendHttpSettings.Id).split('/')[-1] } else { $LocalizedData.None }
                                                }
                                                $RuleInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.RoutingRules) - $GwName"
                                                List         = $false
                                                ColumnWidths = 20, 15, 25, 20, 20
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $RuleInfo | Table @TableParams
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
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.SKU, $LocalizedData.OperationalState, $LocalizedData.ProvisioningState
                                ColumnWidths = 20, 20, 15, 20, 10, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzAppGatewayInfo | Table @TableParams
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
