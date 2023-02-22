function Get-AbrAzFirewallNetworkRule {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Firewall Network Collection Rule information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    begin {}

    process {
        $AzFirewall = Get-AzFirewall -Name $Name
        $NetworkRuleCollections = $AzFirewall.NetworkRuleCollections
        if ($NetworkRuleCollections) {
            Write-PScriboMessage "Collecting Azure Firewall Network Rule Collections information."
            Section -Style Heading5 -ExcludeFromTOC 'Network Rule Collections' {
                $NetworkRuleCollectionInfo = @()
                foreach ($NetworkRuleCollection in ($NetworkRuleCollections | Sort-Object Priority)) {
                    $InObj = [Ordered]@{
                        'Priority' = $NetworkRuleCollection.Priority
                        'Name' = $NetworkRuleCollection.Name
                        'Action' = $NetworkRuleCollection.Action.Type
                        'Rules' = ($NetworkRuleCollection.Rules).Count
                    }
                    $NetworkRuleCollectionInfo += [PSCustomObject]$InObj
                }

                $TableParams = @{
                    Name = "Network Rule Collections"
                    List = $false
                    ColumnWidths = 15, 55, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name) - $($Name)"
                }
                $NetworkRuleCollectionInfo | Table @TableParams

                if ($InfoLevel.Firewall -ge 3) {
                    foreach ($NetworkRuleCollection in ($NetworkRuleCollections | Sort-Object Name)) {
                        if ($NetworkRuleCollection.Action.Type -eq 'Allow') {
                            Section -Style NOTOCHeading6 -ExcludeFromTOC $($NetworkRuleCollection.Name) {
                                $NetworkAllowRules = $NetworkRuleCollection.Rules | Where-Object {$NetworkRuleCollection.Action.Type -eq 'Allow'}
                                $AllowRuleInfo = @()
                                foreach ($AllowRule in $NetworkAllowRules) {
                                    $InObj = [Ordered]@{
                                        'Name' = $AllowRule.Name
                                        'Protocols' = $AllowRule.Protocols -join ', '
                                        'Source Type' = & {
                                            if ($AllowRule.SourceAddresses) {
                                                'IP Address'
                                            } else {
                                                'IP Group'
                                            }
                                        }
                                        'Source' = & {
                                            if ($AllowRule.SourceAddresses) {
                                                $AllowRule.SourceAddresses -join ', '
                                            } elseif ($AllowRule.SourceIpGroups) {
                                                ($AllowRule.SourceIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            }
                                        }
                                        'Destination Type' = & {
                                            if ($AllowRule.DestinationAddresses) {
                                                'IP Address'
                                            } else {
                                                'IP Group'
                                            }
                                        }
                                        'Destination' = & {
                                            if ($AllowRule.DestinationAddresses) {
                                                $AllowRule.DestinationAddresses -join ', '
                                            } elseif ($AllowRule.DestinationIpGroups) {
                                                ($AllowRule.DestinationIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            } elseif ($AllowRule.DestinationFqdns) {
                                                ($AllowRule.DestinationFqdns | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            }
                                        }
                                        'Destination Ports' = $AllowRule.DestinationPorts -join ', '
                                    }
                                    $AllowRuleInfo += [PSCustomObject]$InObj
                                }

                                $TableParams = @{
                                    Name = "Network Allow Rule $($NetworkRuleCollection.Name) - $($Name)"
                                    List = $false
                                    ColumnWidths = 15, 12, 10, 19, 10, 19, 15
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AllowRuleInfo | Table @TableParams
                            }
                        }
                        if ($NetworkRuleCollection.Action.Type -eq 'Deny') {
                            Section -Style NOTOCHeading6 -ExcludeFromTOC $($NetworkRuleCollection.Name) {
                                $NetworkDenyRules = $NetworkRuleCollection.Rules | Where-Object {$NetworkRuleCollection.Action.Type -eq 'Deny'}
                                $DenyRuleInfo = @()
                                foreach ($DenyRule in $NetworkDenyRules) {
                                    $InObj = [Ordered]@{
                                        'Name' = $DenyRule.Name
                                        'Protocols' = $DenyRule.Protocols -join ', '
                                        'Source Type' = & {
                                            if ($DenyRule.SourceAddresses) {
                                                'IP Address'
                                            } else {
                                                'IP Group'
                                            }
                                        }
                                        'Source' = & {
                                            if ($DenyRule.SourceAddresses) {
                                                $DenyRule.SourceAddresses -join ', '
                                            } elseif ($DenyRule.SourceIpGroups) {
                                                ($DenyRule.SourceIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            }
                                        }
                                        'Destination Type' = & {
                                            if ($DenyRule.DestinationAddresses) {
                                                'IP Address'
                                            } else {
                                                'IP Group'
                                            }
                                        }
                                        'Destination' = & {
                                            if ($DenyRule.DestinationAddresses) {
                                                $DenyRule.DestinationAddresses -join ', '
                                            } elseif ($DenyRule.DestinationIpGroups) {
                                                ($DenyRule.DestinationIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            } elseif ($DenyRule.DestinationFqdns) {
                                                ($DenyRule.DestinationFqdns | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            }
                                        }
                                        'Destination Ports' = $DenyRule.DestinationPorts -join ', '
                                    }
                                    $DenyRuleInfo += [PSCustomObject]$InObj
                                }

                                $TableParams = @{
                                    Name = "Network Deny Rule $($NetworkRuleCollection.Name) - $($Name)"
                                    List = $false
                                    ColumnWidths = 15, 12, 10, 19, 10, 19, 15
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $DenyRuleInfo | Table @TableParams
                            }
                        }
                    }
                }
            }
        }
    }

    end {}
}