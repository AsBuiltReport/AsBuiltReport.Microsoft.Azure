function Get-AbrAzFirewallPolicy {
    [CmdletBinding()]
    param (
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzFirewallPolicy
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.FirewallPolicy)
    }

    process {
        try {
            if ($InfoLevel.FirewallPolicy -gt 0) {
                $firewallPolicies = Get-AzResource -ResourceType "Microsoft.Network/firewallPolicies"
                if ($firewallPolicies) {
                    Section -Style Heading4 $LocalizedData.Heading {
                        Write-PScriboMessage $LocalizedData.Collecting
                        foreach ($firewallPolicy in $firewallPolicies) {
                            # Get full policy details
                            $policy = Get-AzFirewallPolicy -Name $firewallpolicy.Name -ResourceGroupName $firewallpolicy.ResourceGroupName
                            # Display policy settings
                            Section -Style Heading5 $policy.name {
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name = $policy.Name
                                    $LocalizedData.ResourceGroup = $policy.ResourceGroupName
                                    $LocalizedData.Location = $AzLocationLookup."$($policy.Location)"
                                    $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($policy.Id).split('/')[2]))"
                                    $LocalizedData.SubscriptionID = ($policy.Id).split('/')[2]
                                    $LocalizedData.ProvisioningState = $policy.ProvisioningState
                                    $LocalizedData.ParentPolicy = if ($policy.BasePolicy.Id) {
                                        ($policy.BasePolicy.Id).Split('/')[-1]
                                    } else {
                                        $LocalizedData.None
                                    }
                                    $LocalizedData.PolicyTier = $policy.Sku.Tier
                                    $LocalizedData.ThreatIntelMode = if ($policy.ThreatIntelMode) {
                                        $policy.ThreatIntelMode
                                    } else {
                                        $LocalizedData.Off
                                    }
                                    $LocalizedData.IntrusionDetectionMode = if ($policy.Sku.Tier -eq 'Premium') {
                                        $policy.IntrusionDetection.Mode
                                    } else {
                                        $LocalizedData.NotSupported
                                    }
                                    $LocalizedData.DnsServers = if (-not $policy.DnsSettings -or -not $policy.DnsSettings.Servers) {
                                        $LocalizedData.Disabled
                                    } elseif ($policy.DnsSettings.Servers.Count -eq 0) {
                                        $LocalizedData.Default
                                    } else {
                                        $policy.DnsSettings.Servers -join ", "
                                    }
                                    $LocalizedData.DnsProxy = if ($policy.DnsSettings.EnableProxy) {
                                        $LocalizedData.Enabled
                                    } else {
                                        $LocalizedData.Disabled
                                    }
                                }

                                if ($Options.ShowTags) {
                                    $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($policy.Tag)) {
                                        $LocalizedData.None
                                    } else {
                                        ($policy.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                    }
                                }

                                $PolicyInfo = [PSCustomObject]$InObj

                                # Apply health check highlighting
                                if ($Healthcheck.FirewallPolicy.ProvisioningState) {
                                    if ($PolicyInfo.ProvisioningState -ne 'Succeeded') {
                                        $PolicyInfo | Set-Style -Style Critical -Property ProvisioningState
                                    }
                                }
                                if ($Healthcheck.FirewallPolicy.ThreatIntelMode) {
                                    if ($PolicyInfo.ThreatIntelMode -eq $LocalizedData.Off) {
                                        $PolicyInfo | Set-Style -Style Warning -Property ThreatIntelMode
                                    }
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeading) - $($firewallpolicy.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $PolicyInfo | Table @TableParams
                            }

                            # Check if policy has rule collection groups
                            if (-not $policy.RuleCollectionGroups -or $policy.RuleCollectionGroups.Count -eq 0) {
                                Write-PScriboMessage ($LocalizedData.NotFound -f $firewallPolicy.Name)
                                continue
                            } else {
                                Write-PScriboMessage ($LocalizedData.Found -f $($policy.RuleCollectionGroups.Count), $firewallPolicy.Name)

                                if ($InfoLevel.FirewallPolicy -ge 2) {
                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.RcgHeading {
                                        $allRuleGroups = @()
                                        $parentPolicyName = $null

                                        # Get parent policy rule collection groups if parent exists
                                        if ($policy.BasePolicy.Id) {
                                            $parentPolicyName = ($policy.BasePolicy.Id).Split('/')[-1]
                                            $parentPolicyRG = ($policy.BasePolicy.Id).Split('/')[4]
                                            try {
                                                $parentPolicy = Get-AzFirewallPolicy -Name $parentPolicyName -ResourceGroupName $parentPolicyRG -ErrorAction SilentlyContinue
                                                if ($parentPolicy.RuleCollectionGroups) {
                                                    foreach ($rcgRef in $parentPolicy.RuleCollectionGroups) {
                                                        $rcgId = $rcgRef.Id
                                                        if (-not $rcgId) {
                                                            Write-PScriboMessage -IsWarning $LocalizedData.Skipping
                                                            continue
                                                        }
                                                        $rcgName = $rcgId.Split('/')[-1]
                                                        $rcgPolicyName = $rcgId.Split('/')[8]
                                                        $rcgResourceGroup = $rcgId.Split('/')[4]

                                                        # Get the rule collection group details
                                                        $ruleGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $rcgName -ResourceGroupName $rcgResourceGroup -AzureFirewallPolicyName $rcgPolicyName

                                                        # Count total rules
                                                        $totalRules = 0
                                                        foreach ($ruleCollection in $ruleGroup.Properties.RuleCollection) {
                                                            if ($ruleCollection.Rules) {
                                                                $totalRules += $ruleCollection.Rules.Count
                                                            }
                                                        }

                                                        $allRuleGroups += [PSCustomObject]@{
                                                            $LocalizedData.Name = $ruleGroup.Name
                                                            $LocalizedData.Priority = $ruleGroup.Properties.Priority
                                                            $LocalizedData.Rules = $totalRules
                                                            $LocalizedData.InheritedFrom = $parentPolicyName
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage $LocalizedData.NoParentPolicyRCG
                                            }
                                        }

                                        # Get current policy rule collection groups
                                        foreach ($rcgRef in $policy.RuleCollectionGroups) {
                                            $rcgId = $rcgRef.Id
                                            if (-not $rcgId) {
                                                Write-PScriboMessage -IsWarning $LocalizedData.Skipping
                                                continue
                                            }
                                            $rcgName = $rcgId.Split('/')[-1]
                                            $rcgPolicyName = $rcgId.Split('/')[8]
                                            $rcgResourceGroup = $rcgId.Split('/')[4]

                                            # Get the rule collection group details
                                            $ruleGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $rcgName -ResourceGroupName $rcgResourceGroup -AzureFirewallPolicyName $rcgPolicyName

                                            # Count total rules
                                            $totalRules = 0
                                            foreach ($ruleCollection in $ruleGroup.Properties.RuleCollection) {
                                                if ($ruleCollection.Rules) {
                                                    $totalRules += $ruleCollection.Rules.Count
                                                }
                                            }

                                            # For current policy RCGs, show blank for InheritedFrom
                                            $allRuleGroups += [PSCustomObject]@{
                                                $LocalizedData.Name = $ruleGroup.Name
                                                $LocalizedData.Priority = $ruleGroup.Properties.Priority
                                                $LocalizedData.Rules = $totalRules
                                                $LocalizedData.InheritedFrom = ""
                                            }
                                        }

                                        $RuleGroupInfo = $allRuleGroups

                                        $TableParams = @{
                                            Name = "$($LocalizedData.RcgTableHeading) - $($firewallpolicy.Name)"
                                            List = $false
                                            ColumnWidths = 43, 12, 12, 33
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $RuleGroupInfo | Table @TableParams
                                    }
                                    # InfoLevel 3: Show rule collection summary
                                    if ($InfoLevel.FirewallPolicy -ge 3) {
                                        # Collect all rule collection groups with their source
                                        $allRcgData = @()
                                        $parentPolicyName = $null

                                        # Add parent policy RCGs if parent exists
                                        if ($policy.BasePolicy.Id) {
                                            $parentPolicyName = ($policy.BasePolicy.Id).Split('/')[-1]
                                            $parentPolicyRG = ($policy.BasePolicy.Id).Split('/')[4]
                                            try {
                                                $parentPolicy = Get-AzFirewallPolicy -Name $parentPolicyName -ResourceGroupName $parentPolicyRG -ErrorAction SilentlyContinue
                                                if ($parentPolicy.RuleCollectionGroups) {
                                                    foreach ($rcgRef in $parentPolicy.RuleCollectionGroups) {
                                                        $allRcgData += [PSCustomObject]@{
                                                            RcgRef = $rcgRef
                                                            Source = $parentPolicyName
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage $LocalizedData.NoParentPolicy
                                            }
                                        }

                                        # Add current policy RCGs
                                        foreach ($rcgRef in $policy.RuleCollectionGroups) {
                                            $allRcgData += [PSCustomObject]@{
                                                RcgRef = $rcgRef
                                                Source = ""
                                            }
                                        }

                                        foreach ($rcgData in $allRcgData) {
                                            # Extract the RCG name and details from the ID
                                            $rcgId = $rcgData.RcgRef.Id
                                            if (-not $rcgId) {
                                                Write-PScriboMessage -IsWarning $LocalizedData.Skipping
                                                continue
                                            }
                                            $rcgName = $rcgId.Split('/')[-1]
                                            $rcgPolicyName = $rcgId.Split('/')[8]
                                            $rcgResourceGroup = $rcgId.Split('/')[4]

                                            # Get the rule collection group details from the correct policy
                                            $ruleGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $rcgName -ResourceGroupName $rcgResourceGroup -AzureFirewallPolicyName $rcgPolicyName

                                            # Build rule collections summary table
                                            $rulesInfo = foreach ($ruleCollection in $ruleGroup.Properties.RuleCollection) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.Name = $ruleCollection.Name
                                                    $LocalizedData.Priority = $ruleCollection.Priority
                                                    $LocalizedData.Action = $ruleCollection.Action.Type
                                                    $LocalizedData.Rules = $ruleCollection.Rules.Count
                                                    $LocalizedData.InheritedFrom = $rcgData.Source
                                                }
                                                [PSCustomObject]$InObj
                                            }

                                            if ($rulesInfo) {
                                                Section -Style NOTOCHeading7 -ExcludeFromTOC $rcgName {
                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.RcTableHeading) - $rcgName"
                                                        List = $false
                                                        ColumnWidths = 34, 12, 12, 12, 30
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }

                                                    $rulesInfo | Table @TableParams

                                                    # InfoLevel 4: Show individual rule details
                                                    if ($InfoLevel.FirewallPolicy -eq 4) {
                                                        foreach ($ruleCollection in ($ruleGroup.Properties.RuleCollection | Sort-Object Priority)) {
                                                            if (-not $ruleCollection.Rules -or $ruleCollection.Rules.Count -eq 0) {
                                                                continue
                                                            }

                                                            Section -Style NOTOCHeading7 -ExcludeFromTOC $ruleCollection.Name {
                                                                # Determine rule type from first rule
                                                                $firstRule = $ruleCollection.Rules[0]

                                                                # Application Rules
                                                                if ($firstRule.RuleType -eq "ApplicationRule") {
                                                                    foreach ($rule in $ruleCollection.Rules) {
                                                                        $InObj = [Ordered]@{
                                                                            $LocalizedData.Name = $rule.Name
                                                                            $LocalizedData.Description = $rule.Description
                                                                            $LocalizedData.SourceAddresses = if ($rule.SourceAddresses) { ($rule.SourceAddresses -join ", ") } else { "" }
                                                                            $LocalizedData.SourceIpGroups = if ($rule.SourceIpGroups) { ($rule.SourceIpGroups -join ", ") } else { "" }
                                                                            $LocalizedData.TargetFQDNs = if ($rule.TargetFqdns) { ($rule.TargetFqdns -join ", ") } else { "" }
                                                                            $LocalizedData.TargetUrls = if ($rule.TargetUrls) { ($rule.TargetUrls -join ", ") } else { "" }
                                                                            $LocalizedData.Protocols = if ($rule.Protocols) { ($rule.Protocols | ForEach-Object { "$($_.ProtocolType):$($_.Port)" }) -join ", " } else { "" }
                                                                            $LocalizedData.WebCategories = if ($rule.WebCategories) { ($rule.WebCategories -join ", ") } else { "" }
                                                                        }
                                                                        $appRule = [PSCustomObject]$InObj

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.AppRuleTableHeading) - $($rule.Name)"
                                                                            List = $true
                                                                            ColumnWidths = 40, 60
                                                                        }

                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }

                                                                        $appRule | Table @TableParams
                                                                    }
                                                                }

                                                                # Network Rules
                                                                elseif ($firstRule.RuleType -eq "NetworkRule") {
                                                                    foreach ($rule in $ruleCollection.Rules) {
                                                                        $InObj = [Ordered]@{
                                                                            $LocalizedData.Name = $rule.Name
                                                                            $LocalizedData.Description = $rule.Description
                                                                            $LocalizedData.SourceAddresses = if ($rule.SourceAddresses) { ($rule.SourceAddresses -join ", ") } else { "" }
                                                                            $LocalizedData.SourceIpGroups = if ($rule.SourceIpGroups) { ($rule.SourceIpGroups -join ", ") } else { "" }
                                                                            $LocalizedData.DestinationAddresses = if ($rule.DestinationAddresses) { ($rule.DestinationAddresses -join ", ") } else { "" }
                                                                            $LocalizedData.DestinationIpGroups = if ($rule.DestinationIpGroups) { ($rule.DestinationIpGroups -join ", ") } else { "" }
                                                                            $LocalizedData.DestinationFqdns = if ($rule.DestinationFqdns) { ($rule.DestinationFqdns -join ", ") } else { "" }
                                                                            $LocalizedData.DestinationPorts = if ($rule.DestinationPorts) { ($rule.DestinationPorts -join ", ") } else { "" }
                                                                            $LocalizedData.Protocols = if ($rule.IpProtocols) { ($rule.IpProtocols -join ", ") } else { "" }
                                                                        }
                                                                        $netRule = [PSCustomObject]$InObj

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.NetRuleTableHeading) - $($rule.Name)"
                                                                            List = $true
                                                                            ColumnWidths = 40, 60
                                                                        }

                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }

                                                                        $netRule | Table @TableParams
                                                                    }
                                                                }

                                                                # DNAT Rules
                                                                elseif ($firstRule.RuleType -eq "NatRule") {
                                                                    foreach ($rule in $ruleCollection.Rules) {
                                                                        $InObj = [Ordered]@{
                                                                            $LocalizedData.Name = $rule.Name
                                                                            $LocalizedData.Description = $rule.Description
                                                                            $LocalizedData.SourceAddresses = if ($rule.SourceAddresses) { ($rule.SourceAddresses -join ", ") } else { "" }
                                                                            $LocalizedData.SourceIpGroups = if ($rule.SourceIpGroups) { ($rule.SourceIpGroups -join ", ") } else { "" }
                                                                            $LocalizedData.DestinationAddresses = if ($rule.DestinationAddresses) { ($rule.DestinationAddresses -join ", ") } else { "" }
                                                                            $LocalizedData.DestinationPorts = if ($rule.DestinationPorts) { ($rule.DestinationPorts -join ", ") } else { "" }
                                                                            $LocalizedData.Protocols = if ($rule.IpProtocols) { ($rule.IpProtocols -join ", ") } else { "" }
                                                                            $LocalizedData.TranslatedAddress = $rule.TranslatedAddress
                                                                            $LocalizedData.TranslatedPort = $rule.TranslatedPort
                                                                            $LocalizedData.TranslatedFqdn = $rule.TranslatedFqdn
                                                                        }
                                                                        $natRule = [PSCustomObject]$InObj

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.DnatRuleTableHeading) - $($rule.Name)"
                                                                            List = $true
                                                                            ColumnWidths = 40, 60
                                                                        }

                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }

                                                                        $natRule | Table @TableParams
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                Write-PScriboMessage ($LocalizedData.NoRuleCollections -f $rcgName)
                                            }
                                    }
                                }
                            }
                        }
                    }

                }
            }

        }
        } catch {
            Write-PScriboMessage -IsWarning ($_.Exception.Message)
        }
    }
    end {}
}