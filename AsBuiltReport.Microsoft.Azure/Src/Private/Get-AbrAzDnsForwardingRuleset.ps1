function Get-AbrAzDnsForwardingRuleset {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure DNS Forwarding Ruleset information
    .DESCRIPTION
        Documents the configuration of Azure DNS Forwarding Rulesets, including forwarding rules
        with target DNS servers and virtual network link associations.
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
        $LocalizedData = $reportTranslate.GetAbrAzDnsForwardingRuleset
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.DnsForwardingRuleset)
    }

    process {
        try {
            if ($InfoLevel.DnsForwardingRuleset -ge 1) {
                $AzDnsForwardingRulesets = Get-AzDnsForwardingRuleset -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzDnsForwardingRulesets) {
                    Write-PScriboMessage $LocalizedData.Collecting

                    # Pre-collect forwarding rules and VNet links per ruleset
                    $ForwardingRulesMap = @{}
                    $VNetLinksMap = @{}
                    foreach ($AzRuleset in $AzDnsForwardingRulesets) {
                        $RG = ($AzRuleset.Id).split('/')[4]
                        $ForwardingRulesMap[$AzRuleset.Name] = Get-AzDnsForwardingRule -DnsForwardingRulesetName $AzRuleset.Name -ResourceGroupName $RG -ErrorAction SilentlyContinue
                        $VNetLinksMap[$AzRuleset.Name] = Get-AzDnsForwardingRulesetVirtualNetworkLink -DnsForwardingRulesetName $AzRuleset.Name -ResourceGroupName $RG -ErrorAction SilentlyContinue
                    }

                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzRulesetInfo = @()
                        foreach ($AzRuleset in $AzDnsForwardingRulesets) {
                            $RuleCount = if ($ForwardingRulesMap[$AzRuleset.Name]) { @($ForwardingRulesMap[$AzRuleset.Name]).Count } else { 0 }
                            $LinkCount = if ($VNetLinksMap[$AzRuleset.Name]) { @($VNetLinksMap[$AzRuleset.Name]).Count } else { 0 }
                            $OutboundEndpoints = if ($AzRuleset.DnsResolverOutboundEndpoint -and $AzRuleset.DnsResolverOutboundEndpoint.Count -gt 0) {
                                ($AzRuleset.DnsResolverOutboundEndpoint | ForEach-Object { $_.Id.split('/')[-1] }) -join [Environment]::NewLine
                            } else {
                                $LocalizedData.None
                            }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name                = $AzRuleset.Name
                                $LocalizedData.ResourceGroup       = ($AzRuleset.Id).split('/')[4]
                                $LocalizedData.Location            = $AzLocationLookup."$($AzRuleset.Location)"
                                $LocalizedData.Subscription        = "$($AzSubscriptionLookup.(($AzRuleset.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID      = ($AzRuleset.Id).split('/')[2]
                                $LocalizedData.ForwardingRules     = $RuleCount
                                $LocalizedData.VirtualNetworkLinks = $LinkCount
                                $LocalizedData.OutboundEndpoints   = $OutboundEndpoints
                                $LocalizedData.ProvisioningState   = $AzRuleset.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzRuleset.Tag -or $AzRuleset.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzRuleset.Tag.Keys | ForEach-Object { "$_`:`t$($AzRuleset.Tag.AdditionalProperties[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzRulesetInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.DnsForwardingRuleset.ProvisioningState) {
                            $AzRulesetInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.DnsForwardingRuleset -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzRulesetItem in $AzRulesetInfo) {
                                $RulesetName = $AzRulesetItem.($LocalizedData.Name)
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $RulesetName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $RulesetName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRulesetItem | Table @TableParams

                                    # Forwarding Rules sub-section
                                    $Rules = $ForwardingRulesMap[$RulesetName]
                                    if ($Rules) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ForwardingRulesHeading {
                                            $RuleInfo = @()
                                            foreach ($Rule in $Rules) {
                                                $TargetServers = if ($Rule.TargetDnsServer -and $Rule.TargetDnsServer.Count -gt 0) {
                                                    ($Rule.TargetDnsServer | ForEach-Object { "$($_.IPAddress):$($_.Port)" }) -join [Environment]::NewLine
                                                } else {
                                                    $LocalizedData.None
                                                }
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.RuleName       = $Rule.Name
                                                    $LocalizedData.DomainName     = $Rule.DomainName
                                                    $LocalizedData.TargetServers  = $TargetServers
                                                    $LocalizedData.RuleState      = $Rule.DnsForwardingRuleState
                                                    $LocalizedData.ProvisioningState = $Rule.ProvisioningState
                                                }
                                                $RuleInfo += [PSCustomObject]$InObj
                                            }

                                            if ($Healthcheck.DnsForwardingRuleset.ForwardingRuleState) {
                                                $RuleInfo | Where-Object { $_.$($LocalizedData.RuleState) -ne 'Enabled' } | Set-Style -Style Warning -Property $LocalizedData.RuleState
                                            }

                                            $TableParams = @{
                                                Name         = "$($LocalizedData.ForwardingRulesHeading) - $RulesetName"
                                                List         = $false
                                                ColumnWidths = 20, 30, 30, 10, 10
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $RuleInfo | Table @TableParams
                                        }
                                    }

                                    # Virtual Network Links sub-section
                                    $VNetLinks = $VNetLinksMap[$RulesetName]
                                    if ($VNetLinks) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.VNetLinksHeading {
                                            $LinkInfo = @()
                                            foreach ($Link in $VNetLinks) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.LinkName        = $Link.Name
                                                    $LocalizedData.VirtualNetwork  = $Link.VirtualNetworkId.split('/')[-1]
                                                    $LocalizedData.ProvisioningState = $Link.ProvisioningState
                                                }
                                                $LinkInfo += [PSCustomObject]$InObj
                                            }

                                            $TableParams = @{
                                                Name         = "$($LocalizedData.VNetLinksHeading) - $RulesetName"
                                                List         = $false
                                                ColumnWidths = 30, 50, 20
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $LinkInfo | Table @TableParams
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
                                Columns      = $LocalizedData.Name, $LocalizedData.Location, $LocalizedData.ForwardingRules, $LocalizedData.VirtualNetworkLinks, $LocalizedData.OutboundEndpoints, $LocalizedData.ProvisioningState
                                ColumnWidths = 20, 15, 15, 15, 20, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzRulesetInfo | Table @TableParams
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
