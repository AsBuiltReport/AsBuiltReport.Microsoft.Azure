function Get-AbrAzFirewallNatRule {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Firewall NAT Colletion Rule information
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
        $NatRuleCollections = $AzFirewall.NatRuleCollections
        if ($NatRuleCollections) {
            Write-PScriboMessage "Collecting Azure Firewall NAT Rule Collections information."
            Section -Style Heading4 'NAT Rule Collections' {
                $NatRuleCollectionInfo = @()
                foreach ($NatRuleCollection in ($NatRuleCollections | Sort-Object Priority)) {
                    $InObj = [Ordered]@{
                        'Priority' = $NatRuleCollection.Priority
                        'Name' = $NatRuleCollection.Name
                        'Action' = $NatRuleCollection.Action.Type
                        'Rules' = ($NatRuleCollection.Rules).Count
                    }
                    $NatRuleCollectionInfo += [PSCustomObject]$InObj
                }

                $TableParams = @{
                    Name = "NAT Rule Collections"
                    List = $false
                    ColumnWidths = 15, 55, 15, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name) - $($Name)"
                }
                $NatRuleCollectionInfo | Table @TableParams

                if ($InfoLevel.Firewall -ge 3) {
                    foreach ($NatRuleCollection in ($NatRuleCollections | Sort-Object Name)) {
                        Section -Style Heading5 $($NatRuleCollection.Name) {
                            $NatRuleInfo = @()
                            foreach ($NatRule in $($NatRuleCollection.Rules)) {
                                $InObj = [Ordered]@{
                                    'Name' = $NatRule.Name
                                    'Protocols' = $NatRule.Protocols -join ', '
                                    'Source Type' = & {
                                        if ($NatRule.SourceAddresses) {
                                            'IP Address'
                                        } else {
                                            'IP Group'
                                        }
                                    }
                                    'Source' = & {
                                        if ($NatRule.SourceAddresses) {
                                            $NatRule.SourceAddresses -join ', '
                                        } elseif ($NatRule.SourceIpGroups) {
                                            ($NatRule.SourceIpGroups | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                        }
                                    }
                                    'Destination Addresses' = $NatRule.DestinationAddresses -join ', '
                                    'Destination Ports' = $NatRule.DestinationPorts -join ', '
                                    'Translated Address' = $NatRule.TranslatedAddress
                                    'Translated Port' = $NatRule.TranslatedPort
                                }
                                $NatRuleInfo += [PSCustomObject]$InObj
                            }

                            $TableParams = @{
                                Name = "NAT Rule $($NatRuleCollection.Name) - $($Name)"
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
    }

    end {}
}