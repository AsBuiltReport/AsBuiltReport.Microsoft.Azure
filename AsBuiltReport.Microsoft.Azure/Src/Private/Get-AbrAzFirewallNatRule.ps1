function Get-AbrAzFirewallNatRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Firewall NAT Colletion Rule information
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
        $LocalizedData = $reportTranslate.GetAbrAzFirewallNatRule
    }

    process {
        Try {
            $AzFirewall = Get-AzFirewall -Name $Name
            $NatRuleCollections = $AzFirewall.NatRuleCollections
            if ($NatRuleCollections) {
                Write-PScriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $NatRuleCollectionInfo = @()
                    foreach ($NatRuleCollection in ($NatRuleCollections | Sort-Object Priority)) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Priority = $NatRuleCollection.Priority
                            $LocalizedData.Name = $NatRuleCollection.Name
                            $LocalizedData.Action = $NatRuleCollection.Action.Type
                            $LocalizedData.Rules = ($NatRuleCollection.Rules).Count
                        }
                        $NatRuleCollectionInfo += [PSCustomObject]$InObj
                    }

                    $TableParams = @{
                        Name = $LocalizedData.TableHeading
                        List = $false
                        ColumnWidths = 15, 55, 15, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name) - $($Name)"
                    }
                    $NatRuleCollectionInfo | Table @TableParams

                    if ($InfoLevel.Firewall -ge 3) {
                        foreach ($NatRuleCollection in ($NatRuleCollections | Sort-Object Name)) {
                            Section -Style NOTOCHeading7 -ExcludeFromTOC $($NatRuleCollection.Name) {
                                $NatRuleInfo = @()
                                foreach ($NatRule in $($NatRuleCollection.Rules)) {
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $NatRule.Name
                                        $LocalizedData.Protocols = $NatRule.Protocols -join ', '
                                        $LocalizedData.SourceType = if ($NatRule.SourceAddresses) {
                                            $LocalizedData.IPAddress
                                        } else {
                                            $LocalizedData.IPGroup
                                        }
                                        $LocalizedData.Source = if ($NatRule.SourceAddresses) {
                                            $NatRule.SourceAddresses -join ', '
                                        } elseif ($NatRule.SourceIpGroups) {
                                            ($NatRule.SourceIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                        } else {
                                            '--'
                                        }
                                        $LocalizedData.DestinationAddresses = $NatRule.DestinationAddresses -join ', '
                                        $LocalizedData.DestinationPorts = $NatRule.DestinationPorts -join ', '
                                        $LocalizedData.TranslatedAddress = $NatRule.TranslatedAddress
                                        $LocalizedData.TranslatedPort = $NatRule.TranslatedPort
                                    }
                                    $NatRuleInfo += [PSCustomObject]$InObj
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.NatRule) $($NatRuleCollection.Name) - $($Name)"
                                    List = $false
                                    ColumnWidths = 16, 12, 12, 12, 12, 12, 12, 12
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $NatRuleInfo | Table @TableParams
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