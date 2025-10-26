function Get-AbrAzNetworkSecurityGroupRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Network Security Group Security Rules information
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
        $LocalizedData = $reportTranslate.GetAbrAzNetworkSecurityGroupRule
    }

    process {
        Try {
            $AzNetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $Name
            $AzNetworkSecurityGroupRules = @()
            $AzNetworkSecurityGroupRules += $AzNetworkSecurityGroup.SecurityRules
            $AzNetworkSecurityGroupRules += $AzNetworkSecurityGroup.DefaultSecurityRules

            if ($AzNetworkSecurityGroupRules) {
                Write-PscriboMessage $LocalizedData.Collecting
                $InboundNsgSecurityRules = $AzNetworkSecurityGroupRules | Where-Object {$_.Direction -eq 'Inbound'} | Sort-Object Priority

                if ($InboundNsgSecurityRules) {
                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading1 {
                        $InboundRuleInfo = @()
                        foreach ($InboundNsgSecurityRule in $InboundNsgSecurityRules) {
                            Try {
                                $SourceApplicationSecurityGroups = @()
                                $jsonstring = $InboundNsgSecurityRule.SourceApplicationSecurityGroupsText -join "`n"
                                $convertedJson = $jsonstring | ConvertFrom-Json
                                if ($convertedJson.id) {
                                    $SourceApplicationSecurityGroups = ($convertedJson.id).Split('/')[-1]
                                }
                            } Catch {
                                # Silently continue if ASG parsing fails
                            }
                            Try {
                                $DestinationApplicationSecurityGroups = @()
                                $jsonstring = $InboundNsgSecurityRule.DestinationApplicationSecurityGroupsText -join "`n"
                                $convertedJson = $jsonstring | ConvertFrom-Json
                                if ($convertedJson.id) {
                                    $DestinationApplicationSecurityGroups = ($convertedJson.id).Split('/')[-1]
                                }
                            } Catch {
                                # Silently continue if ASG parsing fails
                            }
                            $InObj = [Ordered] @{
                                $LocalizedData.Priority = $InboundNsgSecurityRule.Priority
                                $LocalizedData.Name = $InboundNsgSecurityRule.Name
                                $LocalizedData.Port = if ($InboundNsgSecurityRule.DestinationPortRange -eq '*') {
                                    $LocalizedData.Any
                                } else {
                                    $InboundNsgSecurityRule.DestinationPortRange -join ','
                                }
                                $LocalizedData.Protocol = if ($InboundNsgSecurityRule.Protocol -eq '*') {
                                    $LocalizedData.Any
                                } else {
                                    $InboundNsgSecurityRule.Protocol
                                }
                                $LocalizedData.Source = & {
                                    if ($SourceApplicationSecurityGroups) {
                                        $SourceApplicationSecurityGroups
                                    } else {
                                        if ($InboundNsgSecurityRule.SourceAddressPrefix -eq '*') {
                                            $LocalizedData.Any
                                        } else {
                                            $InboundNsgSecurityRule.SourceAddressPrefix
                                        }
                                    }
                                }
                                $LocalizedData.Destination = & {
                                    if ($DestinationApplicationSecurityGroups) {
                                        $DestinationApplicationSecurityGroups
                                    } else {
                                        if ($InboundNsgSecurityRule.DestinationAddressPrefix -eq '*') {
                                            $LocalizedData.Any
                                        } else {
                                            $InboundNsgSecurityRule.DestinationAddressPrefix
                                        }
                                    }
                                }
                                $LocalizedData.Action = $InboundNsgSecurityRule.Access
                            }
                            $InboundRuleInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting for overly permissive rules
                        if ($Healthcheck.NetworkSecurityGroup.OverlyPermissiveRules) {
                            $InboundRuleInfo | Where-Object {
                                $_.($LocalizedData.Action) -eq 'Allow' -and
                                ($_.($LocalizedData.Source) -eq $LocalizedData.Any -or
                                 $_.($LocalizedData.Source) -match '0\.0\.0\.0' -or
                                 $_.($LocalizedData.Source) -eq 'Internet')
                            } | Set-Style -Style Warning -Property $LocalizedData.Source
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading1) - $($AzNetworkSecurityGroup.Name)"
                            List = $false
                            ColumnWidths = 10, 20, 10, 10, 20, 20, 10
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $InboundRuleInfo | Table @TableParams
                    }
                }

                $OutboundNsgSecurityRules = $AzNetworkSecurityGroupRules | Where-Object {$_.Direction -eq 'Outbound'} | Sort-Object Priority
                if ($OutboundNsgSecurityRules) {
                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading2 {
                        $OutboundRuleInfo = @()
                        foreach ($OutboundNsgSecurityRule in $OutboundNsgSecurityRules) {
                            Try {
                                $SourceApplicationSecurityGroups = @()
                                $jsonstring = $OutboundNsgSecurityRule.SourceApplicationSecurityGroupsText -join "`n"
                                $convertedJson = $jsonstring | ConvertFrom-Json
                                if ($convertedJson.id) {
                                    $SourceApplicationSecurityGroups = ($convertedJson.id).Split('/')[-1]
                                }
                            } Catch {
                                # Silently continue if ASG parsing fails
                            }
                            Try {
                                $DestinationApplicationSecurityGroups = @()
                                $jsonstring = $OutboundNsgSecurityRule.DestinationApplicationSecurityGroupsText -join "`n"
                                $convertedJson = $jsonstring | ConvertFrom-Json
                                if ($convertedJson.id) {
                                    $DestinationApplicationSecurityGroups = ($convertedJson.id).Split('/')[-1]
                                }
                            } Catch {
                                # Silently continue if ASG parsing fails
                            }
                            $InObj = [Ordered] @{
                                $LocalizedData.Priority = $OutboundNsgSecurityRule.Priority
                                $LocalizedData.Name = $OutboundNsgSecurityRule.Name
                                $LocalizedData.Port = if ($OutboundNsgSecurityRule.DestinationPortRange -eq '*') {
                                    $LocalizedData.Any
                                } else {
                                    $OutboundNsgSecurityRule.DestinationPortRange -join ','
                                }
                                $LocalizedData.Protocol = if ($OutboundNsgSecurityRule.Protocol -eq '*') {
                                    $LocalizedData.Any
                                } else {
                                    $OutboundNsgSecurityRule.Protocol
                                }
                                $LocalizedData.Source = & {
                                    if ($SourceApplicationSecurityGroups) {
                                        $SourceApplicationSecurityGroups
                                    } else {
                                        if ($OutboundNsgSecurityRule.SourceAddressPrefix -eq '*') {
                                            $LocalizedData.Any
                                        } else {
                                            $OutboundNsgSecurityRule.SourceAddressPrefix
                                        }
                                    }
                                }
                                $LocalizedData.Destination = & {
                                    if ($DestinationApplicationSecurityGroups) {
                                        $DestinationApplicationSecurityGroups
                                    } else {
                                        if ($OutboundNsgSecurityRule.DestinationAddressPrefix -eq '*') {
                                            $LocalizedData.Any
                                        } else {
                                            $OutboundNsgSecurityRule.DestinationAddressPrefix
                                        }
                                    }
                                }
                                $LocalizedData.Action = $OutboundNsgSecurityRule.Access
                            }
                            $OutboundRuleInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting for overly permissive rules
                        if ($Healthcheck.NetworkSecurityGroup.OverlyPermissiveRules) {
                            $OutboundRuleInfo | Where-Object {
                                $_.($LocalizedData.Action) -eq 'Allow' -and
                                ($_.($LocalizedData.Source) -eq $LocalizedData.Any -or
                                 $_.($LocalizedData.Source) -match '0\.0\.0\.0' -or
                                 $_.($LocalizedData.Source) -eq 'Internet')
                            } | Set-Style -Style Warning -Property $LocalizedData.Source
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading2) - $($AzNetworkSecurityGroup.Name)"
                            List = $false
                            ColumnWidths = 10, 20, 10, 10, 20, 20, 10
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutboundRuleInfo | Table @TableParams
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}