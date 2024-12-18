function Get-AbrAzFirewall {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Firewall information
    .DESCRIPTION

    .NOTES
        Version:        0.1.2
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        Write-PScriboMessage "Firewall InfoLevel set at $($InfoLevel.Firewall)."
    }

    process {
        Try {
            if ($InfoLevel.Firewall -gt 0) {
                $AzFirewalls = Get-AzFirewall | Sort-Object Name
                if ($AzFirewalls) {
                    Write-PScriboMessage "Collecting Azure Firewall information."
                    Section -Style Heading4 'Firewalls' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "Azure Firewall is a cloud-native and intelligent network firewall security service that provides the best of breed threat protection for your cloud workloads running in Azure. It's a fully stateful, firewall as a service with built-in high availability and unrestricted cloud scalability. It provides both east-west and north-south traffic inspection."
                            BlankLine
                        }
                        $AzFirewallInfo = @()
                        foreach ($AzFirewall in $AzFirewalls) {
                            $InObj = [Ordered]@{
                                'Name' = $AzFirewall.Name
                                'Resource Group' = $AzFirewall.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzFirewall.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzFirewall.Id).split('/')[2]))"
                                'Provisioning State' = $AzFirewall.ProvisioningState
                                <#
                                'DNS Server' = if ($AzFirewall.DNSServer) {
                                    ($AzFirewall.DNSServer) -join ', '
                                } else {
                                    'Default (Azure provided'
                                }
                                'DNS Proxy' = if ($AzFirewall.DNSEnableProxy) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Firewall Subnet' = ($AzFirewall.IpConfigurations | Where-Object {$_.Name -eq 'AzureFirewallIpConfiguration0'}).Subnet.Id.Split('/')[-1]
                                'Firewall Public IP' = ($AzFirewall.IpConfigurations | Where-Object {$_.Name -eq 'AzureFirewallIpConfiguration0'}).PublicIpAddress.Id.Split('/')[-1]
                                'Firewall Private IP' = ($AzFirewall.IpConfigurations | Where-Object {$_.Name -eq 'AzureFirewallIpConfiguration0'}).PrivateIpAddress
                                #>
                                'Firewall SKU' = $AzFirewall.Sku.Tier
                                'NAT Rule Collections' = $AzFirewall.NatkRuleCollections.Count
                                'Network Rule Collections' = $AzFirewall.NetworkRuleCollections.Count
                                'Application Rule Collections' = $AzFirewall.ApplicationRuleCollections.Count
                                ##ToDo: App Rules
                            }

                            if ($Options.ShowTags) {
                                $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzFirewall.Tag)) {
                                    'None'
                                } else {
                                    ($AzFirewall.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzFirewallInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.Firewall -ge 2) {
                            Paragraph "The following sections detail the configuration of the firewalls within the $($AzSubscription.Name) subscription."
                            foreach ($AzFirewall in $AzFirewallInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzFirewall.Name)" {
                                    $TableParams = @{
                                        Name = "Firewall - $($AzFirewall.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzFirewall | Table @TableParams

                                    # Get NAT Collection Rules
                                    Get-AbrAzFirewallNatRule -Name $AzFirewall.Name

                                    # Get Network Collection Rules
                                    Get-AbrAzFirewallNetworkRule -Name $AzFirewall.Name
                                }
                            }
                        } else {
                            Paragraph "The following table summarises the configuration of the firewalls within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "Firewalls - $($AzSubscription.Name)"
                                List = $false
                                Headers = 'Name', 'Resource Group', 'Location', 'NAT Rules', 'Network Rules', 'App Rules'
                                Columns = 'Name', 'Resource Group', 'Location', 'NAT Rule Collections', 'Network Rule Collections', 'Application Rule Collections'
                                ColumnWidths = 25, 21, 21, 11, 11, 11
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzFirewallInfo | Table @TableParams
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