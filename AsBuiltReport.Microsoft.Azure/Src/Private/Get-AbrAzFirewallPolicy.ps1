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
                                    Name = $policy.Name
                                    ResourceGroupName = $policy.ResourceGroupName
                                    Location = $AzLocationLookup."$($policy.Location)"
                                    Subscription = "$($AzSubscriptionLookup.(($policy.Id).split('/')[2]))"
                                    SubscriptionID = ($policy.Id).split('/')[2]
                                    ProvisioningState = $policy.ProvisioningState
                                    ParentPolicy = if ($policy.BasePolicy.Id) {
                                        ($policy.BasePolicy.Id).Split('/')[-1]
                                    } else {
                                        $LocalizedData.None
                                    }
                                    PolicyTier = $policy.Sku.Tier
                                    ThreatIntelMode = if ($policy.ThreatIntelMode) {
                                        $policy.ThreatIntelMode
                                    } else {
                                        $LocalizedData.Off
                                    }
                                    IntrusionDetectionMode = if ($policy.Sku.Tier -eq 'Premium') {
                                        $policy.IntrusionDetection.Mode
                                    } else {
                                        $LocalizedData.NotSupported
                                    }
                                    DnsServers = if (-not $policy.DnsSettings -or -not $policy.DnsSettings.Servers) {
                                        $LocalizedData.Disabled
                                    } elseif ($policy.DnsSettings.Servers.Count -eq 0) {
                                        "Default (Azure provided)"
                                    } else {
                                        $policy.DnsSettings.Servers -join ", "
                                    }
                                    DnsProxy = if ($policy.DnsSettings.EnableProxy) {
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
                                    Name = "Firewall Policy - $($firewallpolicy.Name)"
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
                                    Section -Style NOTOCHeading6 -ExcludeFromTOC 'Rule Collection Groups' {
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
                                                            Name = $ruleGroup.Name
                                                            Priority = $ruleGroup.Properties.Priority
                                                            Rules = $totalRules
                                                            InheritedFrom = $parentPolicyName
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage "Unable to retrieve parent policy rule collection groups"
                                            }
                                        }

                                        # Get current policy rule collection groups
                                        foreach ($rcgRef in $policy.RuleCollectionGroups) {
                                            $rcgId = $rcgRef.Id
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
                                                Name = $ruleGroup.Name
                                                Priority = $ruleGroup.Properties.Priority
                                                Rules = $totalRules
                                                InheritedFrom = ""
                                            }
                                        }

                                        $RuleGroupInfo = $allRuleGroups

                                        $TableParams = @{
                                            Name = "Rule Collection Groups - $($firewallpolicy.Name)"
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
                                                Write-PScriboMessage "Unable to retrieve parent policy for InfoLevel 3"
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
                                            $rcgName = $rcgId.Split('/')[-1]
                                            $rcgPolicyName = $rcgId.Split('/')[8]
                                            $rcgResourceGroup = $rcgId.Split('/')[4]

                                            # Get the rule collection group details from the correct policy
                                            $ruleGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $rcgName -ResourceGroupName $rcgResourceGroup -AzureFirewallPolicyName $rcgPolicyName

                                            # Build rule collections summary table
                                            $rulesInfo = foreach ($ruleCollection in $ruleGroup.Properties.RuleCollection) {
                                                $InObj = [Ordered]@{
                                                    Name = $ruleCollection.Name
                                                    Priority = $ruleCollection.Priority
                                                    Action = $ruleCollection.Action.Type
                                                    Rules = $ruleCollection.Rules.Count
                                                    InheritedFrom = $rcgData.Source
                                                }
                                                [PSCustomObject]$InObj
                                            }

                                            if ($rulesInfo) {
                                                Section -Style NOTOCHeading7 -ExcludeFromTOC $rcgName {
                                                    $TableParams = @{
                                                        Name = "Rule Collections - $rcgName"
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
                                                                            Name = $rule.Name
                                                                            Description = $rule.Description
                                                                            SourceAddresses = if ($rule.SourceAddresses) { ($rule.SourceAddresses -join ", ") } else { "" }
                                                                            SourceIpGroups = if ($rule.SourceIpGroups) { ($rule.SourceIpGroups -join ", ") } else { "" }
                                                                            TargetFQDNs = if ($rule.TargetFqdns) { ($rule.TargetFqdns -join ", ") } else { "" }
                                                                            TargetUrls = if ($rule.TargetUrls) { ($rule.TargetUrls -join ", ") } else { "" }
                                                                            Protocols = if ($rule.Protocols) { ($rule.Protocols | ForEach-Object { "$($_.ProtocolType):$($_.Port)" }) -join ", " } else { "" }
                                                                            WebCategories = if ($rule.WebCategories) { ($rule.WebCategories -join ", ") } else { "" }
                                                                        }
                                                                        $appRule = [PSCustomObject]$InObj

                                                                        $TableParams = @{
                                                                            Name = "Application Rule - $($rule.Name)"
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
                                                                            Name = $rule.Name
                                                                            Description = $rule.Description
                                                                            SourceAddresses = if ($rule.SourceAddresses) { ($rule.SourceAddresses -join ", ") } else { "" }
                                                                            SourceIpGroups = if ($rule.SourceIpGroups) { ($rule.SourceIpGroups -join ", ") } else { "" }
                                                                            DestinationAddresses = if ($rule.DestinationAddresses) { ($rule.DestinationAddresses -join ", ") } else { "" }
                                                                            DestinationIpGroups = if ($rule.DestinationIpGroups) { ($rule.DestinationIpGroups -join ", ") } else { "" }
                                                                            DestinationFqdns = if ($rule.DestinationFqdns) { ($rule.DestinationFqdns -join ", ") } else { "" }
                                                                            DestinationPorts = if ($rule.DestinationPorts) { ($rule.DestinationPorts -join ", ") } else { "" }
                                                                            Protocols = if ($rule.IpProtocols) { ($rule.IpProtocols -join ", ") } else { "" }
                                                                        }
                                                                        $netRule = [PSCustomObject]$InObj

                                                                        $TableParams = @{
                                                                            Name = "Network Rule - $($rule.Name)"
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
                                                                            Name = $rule.Name
                                                                            Description = $rule.Description
                                                                            SourceAddresses = if ($rule.SourceAddresses) { ($rule.SourceAddresses -join ", ") } else { "" }
                                                                            SourceIpGroups = if ($rule.SourceIpGroups) { ($rule.SourceIpGroups -join ", ") } else { "" }
                                                                            DestinationAddresses = if ($rule.DestinationAddresses) { ($rule.DestinationAddresses -join ", ") } else { "" }
                                                                            DestinationPorts = if ($rule.DestinationPorts) { ($rule.DestinationPorts -join ", ") } else { "" }
                                                                            Protocols = if ($rule.IpProtocols) { ($rule.IpProtocols -join ", ") } else { "" }
                                                                            TranslatedAddress = $rule.TranslatedAddress
                                                                            TranslatedPort = $rule.TranslatedPort
                                                                            TranslatedFqdn = $rule.TranslatedFqdn
                                                                        }
                                                                        $natRule = [PSCustomObject]$InObj

                                                                        $TableParams = @{
                                                                            Name = "DNAT Rule - $($rule.Name)"
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
                                                Write-PScriboMessage "No rule collections found in $rcgName"
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
            Write-PScriboMessage ($_.Exception.Message)
        }
    }
    end {}
}