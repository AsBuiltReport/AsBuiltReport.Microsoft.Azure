function Get-AbrAzVirtualHub {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual WAN hub information
    .DESCRIPTION
        Documents the configuration of Azure Virtual WAN hubs including address prefix, SKU,
        hub router settings, attached gateways and provisioning state.
    .PARAMETER VirtualHub
        The virtual hubs collected by Get-AbrAzVirtualWan.
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
        [Object[]] $VirtualHub
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVirtualHub
    }

    process {
        try {
            Write-PScriboMessage $LocalizedData.Collecting
            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                $LockMap = @{}
                $AllLocks = Get-AzResourceLock -ErrorAction SilentlyContinue
                foreach ($Lock in $AllLocks) {
                    $Key = $Lock.ResourceId.ToLower()
                    if (-not $LockMap.ContainsKey($Key)) { $LockMap[$Key] = @() }
                    $LockMap[$Key] += $Lock
                }

                $AzVirtualHubInfo = @()
                foreach ($AzVirtualHub in $VirtualHub) {
                    $InObj = [Ordered]@{
                        $LocalizedData.Name                       = $AzVirtualHub.Name
                        $LocalizedData.ResourceGroup              = $AzVirtualHub.ResourceGroupName
                        $LocalizedData.Location                   = if ($AzLocationLookup."$($AzVirtualHub.Location)") { $AzLocationLookup."$($AzVirtualHub.Location)" } else { $AzVirtualHub.Location }
                        $LocalizedData.Subscription               = "$($AzSubscriptionLookup.(($AzVirtualHub.Id).split('/')[2]))"
                        $LocalizedData.SubscriptionID             = ($AzVirtualHub.Id).split('/')[2]
                        $LocalizedData.VirtualWan                 = ($AzVirtualHub.VirtualWan.Id).split('/')[-1]
                        $LocalizedData.AddressPrefix              = $AzVirtualHub.AddressPrefix
                        $LocalizedData.SKU                        = $AzVirtualHub.Sku
                        $LocalizedData.RoutingState               = if ($AzVirtualHub.RoutingState) { $AzVirtualHub.RoutingState } else { $LocalizedData.NotApplicable }
                        $LocalizedData.HubRoutingPreference       = if ($AzVirtualHub.HubRoutingPreference) { $AzVirtualHub.HubRoutingPreference } else { $LocalizedData.NotApplicable }
                        $LocalizedData.VirtualRouterAsn           = if ($AzVirtualHub.VirtualRouterAsn) { $AzVirtualHub.VirtualRouterAsn } else { $LocalizedData.NotApplicable }
                        $LocalizedData.VirtualRouterIps           = if ($AzVirtualHub.VirtualRouterIps) { $AzVirtualHub.VirtualRouterIps -join ', ' } else { $LocalizedData.NotApplicable }
                        $LocalizedData.RoutingInfrastructureUnits = if ($null -ne $AzVirtualHub.VirtualRouterAutoScaleConfiguration.MinCapacity) { $AzVirtualHub.VirtualRouterAutoScaleConfiguration.MinCapacity } else { $LocalizedData.NotApplicable }
                        $LocalizedData.VpnGateway                 = if ($AzVirtualHub.VpnGateway.Id) { ($AzVirtualHub.VpnGateway.Id).split('/')[-1] } else { $LocalizedData.None }
                        $LocalizedData.P2SVpnGateway              = if ($AzVirtualHub.P2SVpnGateway.Id) { ($AzVirtualHub.P2SVpnGateway.Id).split('/')[-1] } else { $LocalizedData.None }
                        $LocalizedData.ExpressRouteGateway        = if ($AzVirtualHub.ExpressRouteGateway.Id) { ($AzVirtualHub.ExpressRouteGateway.Id).split('/')[-1] } else { $LocalizedData.None }
                        $LocalizedData.AzureFirewall              = if ($AzVirtualHub.AzureFirewall.Id) { ($AzVirtualHub.AzureFirewall.Id).split('/')[-1] } else { $LocalizedData.None }
                        $LocalizedData.SecurityPartnerProvider    = if ($AzVirtualHub.SecurityPartnerProvider.Id) { ($AzVirtualHub.SecurityPartnerProvider.Id).split('/')[-1] } else { $LocalizedData.None }
                        $LocalizedData.ProvisioningState          = $AzVirtualHub.ProvisioningState
                    }

                    $InObj[$LocalizedData.Locks] = $(
                        $rl = $LockMap[$AzVirtualHub.Id.ToLower()]
                        if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                        else { $LocalizedData.None }
                    )

                    if ($Options.ShowTags) {
                        $InObj[$LocalizedData.Tags] = if ($null -eq $AzVirtualHub.Tag -or $AzVirtualHub.Tag.Count -eq 0) {
                            $LocalizedData.None
                        } else {
                            ($AzVirtualHub.Tag.Keys | ForEach-Object { "$_`:`t$($AzVirtualHub.Tag[$_])" }) -join [Environment]::NewLine
                        }
                    }

                    $AzVirtualHubInfo += [PSCustomObject]$InObj
                }

                if ($Healthcheck.VirtualWan.ProvisioningState) {
                    $AzVirtualHubInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                }

                # A routing state of None is expected for hubs in a Basic Virtual WAN, which have no hub router
                if ($Healthcheck.VirtualWan.RoutingState) {
                    $AzVirtualHubInfo | Where-Object { $_.$($LocalizedData.RoutingState) -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.RoutingState
                    $AzVirtualHubInfo | Where-Object { $_.$($LocalizedData.RoutingState) -eq 'Provisioning' } | Set-Style -Style Warning -Property $LocalizedData.RoutingState
                }

                if ($InfoLevel.VirtualWan -ge 2) {
                    Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                    foreach ($AzVirtualHub in $AzVirtualHubInfo) {
                        Section -Style NOTOCHeading6 -ExcludeFromTOC "$($AzVirtualHub.($LocalizedData.Name))" {
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzVirtualHub.($LocalizedData.Name))"
                                List         = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVirtualHub | Table @TableParams
                        }
                    }
                } else {
                    Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                    BlankLine
                    $TableParams = @{
                        Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                        List         = $false
                        Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.VirtualWan, $LocalizedData.AddressPrefix, $LocalizedData.RoutingState, $LocalizedData.ProvisioningState
                        ColumnWidths = 20, 18, 12, 18, 12, 10, 10
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzVirtualHubInfo | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($LocalizedData.ErrorMessage) $($_.Exception.Message)"
        }
    }

    end {}
}
