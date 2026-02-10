function Get-AbrAzFirewallNetworkRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Firewall Network Collection Rule information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzFirewallNetworkRule
    }

    process {
        Try {
            $AzFirewall = Get-AzFirewall -Name $Name
            $NetworkRuleCollections = $AzFirewall.NetworkRuleCollections
            if ($NetworkRuleCollections) {
                Write-PScriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                    $NetworkRuleCollectionInfo = @()
                    foreach ($NetworkRuleCollection in ($NetworkRuleCollections | Sort-Object Priority)) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Priority = $NetworkRuleCollection.Priority
                            $LocalizedData.Name = $NetworkRuleCollection.Name
                            $LocalizedData.Action = $NetworkRuleCollection.Action.Type
                            $LocalizedData.Rules = ($NetworkRuleCollection.Rules).Count
                        }
                        $NetworkRuleCollectionInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = $LocalizedData.TableHeading
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
                                            $LocalizedData.Name = $AllowRule.Name
                                            $LocalizedData.Protocols = $AllowRule.Protocols -join ', '
                                            $LocalizedData.SourceType = $(if ($AllowRule.SourceAddresses) {
                                                $LocalizedData.IPAddress
                                            } else {
                                                $LocalizedData.IPGroup
                                            })
                                            $LocalizedData.Source = $(if ($AllowRule.SourceAddresses) {
                                                $AllowRule.SourceAddresses -join ', '
                                            } elseif ($AllowRule.SourceIpGroups) {
                                                ($AllowRule.SourceIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            })
                                            $LocalizedData.DestinationType = $(if ($AllowRule.DestinationAddresses) {
                                                $LocalizedData.IPAddress
                                            } else {
                                                $LocalizedData.IPGroup
                                            })
                                            $LocalizedData.Destination = $(if ($AllowRule.DestinationAddresses) {
                                                $AllowRule.DestinationAddresses -join ', '
                                            } elseif ($AllowRule.DestinationIpGroups) {
                                                ($AllowRule.DestinationIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            } elseif ($AllowRule.DestinationFqdns) {
                                                ($AllowRule.DestinationFqdns | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            })
                                            $LocalizedData.DestinationPorts = $AllowRule.DestinationPorts -join ', '
                                        }
                                        $AllowRuleInfo += [PSCustomObject]$InObj
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.NetworkAllowRule) $($NetworkRuleCollection.Name) - $($Name)"
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
                                            $LocalizedData.Name = $DenyRule.Name
                                            $LocalizedData.Protocols = $DenyRule.Protocols -join ', '
                                            $LocalizedData.SourceType = $(if ($DenyRule.SourceAddresses) {
                                                $LocalizedData.IPAddress
                                            } else {
                                                $LocalizedData.IPGroup
                                            })
                                            $LocalizedData.Source = $(if ($DenyRule.SourceAddresses) {
                                                $DenyRule.SourceAddresses -join ', '
                                            } elseif ($DenyRule.SourceIpGroups) {
                                                ($DenyRule.SourceIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            })
                                            $LocalizedData.DestinationType = $(if ($DenyRule.DestinationAddresses) {
                                                $LocalizedData.IPAddress
                                            } else {
                                                $LocalizedData.IPGroup
                                            })
                                            $LocalizedData.Destination = $(if ($DenyRule.DestinationAddresses) {
                                                $DenyRule.DestinationAddresses -join ', '
                                            } elseif ($DenyRule.DestinationIpGroups) {
                                                ($DenyRule.DestinationIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            } elseif ($DenyRule.DestinationFqdns) {
                                                ($DenyRule.DestinationFqdns | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                            })
                                            $LocalizedData.DestinationPorts = $DenyRule.DestinationPorts -join ', '
                                        }
                                        $DenyRuleInfo += [PSCustomObject]$InObj
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.NetworkDenyRule) $($NetworkRuleCollection.Name) - $($Name)"
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
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}