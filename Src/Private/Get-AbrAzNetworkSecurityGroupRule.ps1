function Get-AbrAzNetworkSecurityGroupRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Network Security Group Security Rules information
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
        Try {
            $AzNetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $Name
            $AzNetworkSecurityGroupRules = @()
            $AzNetworkSecurityGroupRules += $AzNetworkSecurityGroup.SecurityRules
            $AzNetworkSecurityGroupRules += $AzNetworkSecurityGroup.DefaultSecurityRules

            if ($AzNetworkSecurityGroupRules) {
                Write-PscriboMessage "Collecting Azure NSG Security Rules information."
                $InboundNsgSecurityRules = $AzNetworkSecurityGroupRules | Where-Object {$_.Direction -eq 'Inbound'} | Sort-Object Priority

                if ($InboundNsgSecurityRules) {
                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Inbound Security Rules" {
                        $InboundRuleInfo = @()
                        foreach ($InboundNsgSecurityRule in $InboundNsgSecurityRules) {
                            Try {
                                $SourceApplicationSecurityGroups = @()
                                $jsonstring = $InboundNsgSecurityRule.SourceApplicationSecurityGroupsText -join "`n"
                                $SourceApplicationSecurityGroups = (($jsonstring | ConvertFrom-Json).id).Split('/')[-1]
                            } Catch {

                            }
                            Try {
                                $DestinationApplicationSecurityGroups = @()
                                $jsonstring = $InboundNsgSecurityRule.DestinationApplicationSecurityGroupsText -join "`n"
                                $DestinationApplicationSecurityGroups = (($jsonstring | ConvertFrom-Json).id).Split('/')[-1]
                            } Catch {

                            }
                            $InObj = [Ordered] @{
                                'Priority' = $InboundNsgSecurityRule.Priority
                                'Name' = $InboundNsgSecurityRule.Name
                                'Port' = if ($InboundNsgSecurityRule.DestinationPortRange -eq '*') {
                                    'Any'
                                } else {
                                    $InboundNsgSecurityRule.DestinationPortRange -join ','
                                }
                                'Protocol' = if ($InboundNsgSecurityRule.Protocol -eq '*') {
                                    'Any'
                                } else {
                                    $InboundNsgSecurityRule.Protocol
                                }
                                'Source' = & {
                                    if ($SourceApplicationSecurityGroups) {
                                        $SourceApplicationSecurityGroups
                                    } else {
                                        if ($InboundNsgSecurityRule.SourceAddressPrefix -eq '*') {
                                            'Any'
                                        } else {
                                            $InboundNsgSecurityRule.SourceAddressPrefix
                                        }
                                    }
                                }
                                'Destination' = & {
                                    if ($DestinationApplicationSecurityGroups) {
                                        $DestinationApplicationSecurityGroups
                                    } else {
                                        if ($InboundNsgSecurityRule.DestinationAddressPrefix -eq '*') {
                                            'Any'
                                        } else {
                                            $InboundNsgSecurityRule.DestinationAddressPrefix
                                        }
                                    }
                                }
                                'Action' = $InboundNsgSecurityRule.Access
                            }
                            $InboundRuleInfo += [PSCustomObject]$InObj
                        }
                        $TableParams = @{
                            Name = "Inbound Security Rules - $($AzNetworkSecurityGroup.Name)"
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
                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Outbound Security Rules" {
                        $OutboundRuleInfo = @()
                        foreach ($OutboundNsgSecurityRule in $OutboundNsgSecurityRules) {
                            Try {
                                $SourceApplicationSecurityGroups = @()
                                $jsonstring = $OutboundNsgSecurityRule.SourceApplicationSecurityGroupsText -join "`n"
                                $SourceApplicationSecurityGroups = (($jsonstring | ConvertFrom-Json).id).Split('/')[-1]
                            } Catch {

                            }
                            Try {
                                $DestinationApplicationSecurityGroups = @()
                                $jsonstring = $OutboundNsgSecurityRule.DestinationApplicationSecurityGroupsText -join "`n"
                                $DestinationApplicationSecurityGroups = (($jsonstring | ConvertFrom-Json).id).Split('/')[-1]
                            } Catch {

                            }
                            $InObj = [Ordered] @{
                                'Priority' = $OutboundNsgSecurityRule.Priority
                                'Name' = $OutboundNsgSecurityRule.Name
                                'Port' = if ($OutboundNsgSecurityRule.DestinationPortRange -eq '*') {
                                    'Any'
                                } else {
                                    $OutboundNsgSecurityRule.DestinationPortRange -join ','
                                }
                                'Protocol' = if ($OutboundNsgSecurityRule.Protocol -eq '*') {
                                    'Any'
                                } else {
                                    $OutboundNsgSecurityRule.Protocol
                                }
                                'Source' = & {
                                    if ($SourceApplicationSecurityGroups) {
                                        $SourceApplicationSecurityGroups
                                    } else {
                                        if ($OutboundNsgSecurityRule.SourceAddressPrefix -eq '*') {
                                            'Any'
                                        } else {
                                            $OutboundNsgSecurityRule.SourceAddressPrefix
                                        }
                                    }
                                }
                                'Destination' = & {
                                    if ($DestinationApplicationSecurityGroups) {
                                        $DestinationApplicationSecurityGroups
                                    } else {
                                        if ($OutboundNsgSecurityRule.DestinationAddressPrefix -eq '*') {
                                            'Any'
                                        } else {
                                            $OutboundNsgSecurityRule.DestinationAddressPrefix
                                        }
                                    }
                                }
                                'Action' = $OutboundNsgSecurityRule.Access
                            }
                            $OutboundRuleInfo += [PSCustomObject]$InObj
                        }
                        $TableParams = @{
                            Name = "Outbound Security Rules - $($AzNetworkSecurityGroup.Name)"
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