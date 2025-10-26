function Get-AbrAzFirewall {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Firewall information
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
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzFirewall
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Firewall)
    }

    process {
        Try {
            if ($InfoLevel.Firewall -gt 0) {
                $AzFirewalls = Get-AzFirewall | Sort-Object Name
                if ($AzFirewalls) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $AzFirewallInfo = @()
                        foreach ($AzFirewall in $AzFirewalls) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzFirewall.Name
                                $LocalizedData.ResourceGroup = $AzFirewall.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzFirewall.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzFirewall.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzFirewall.Id).split('/')[2]
                                #'Virtual Network' = ''
                                $LocalizedData.FirewallPolicy = if ($AzFirewall.FirewallPolicy.id) {
                                    ($AzFirewall.FirewallPolicy.id).Split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.ProvisioningState = $AzFirewall.ProvisioningState
                                $LocalizedData.SKU = $AzFirewall.Sku.Tier
                                $LocalizedData.Subnet = if (($AzFirewall.IpConfigurations | Where-Object {$null -ne $_.PrivateIPAddress}).Subnet.Id) {
                                    ($AzFirewall.IpConfigurations | Where-Object {$null -ne $_.PrivateIPAddress}).Subnet.Id.Split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.PublicIP = if (($AzFirewall.IpConfigurations | Where-Object {$null -ne $_.PrivateIPAddress}).PublicIpAddress.Id) {
                                    ($AzFirewall.IpConfigurations | Where-Object {$null -ne $_.PrivateIPAddress}).PublicIpAddress.Id.Split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.PrivateIP = ($AzFirewall.IpConfigurations | Where-Object {$null -ne $_.PrivateIPAddress}).PrivateIpAddress
                                ##ToDo: App Rules
                            }

                            if ($AzFirewall.VirtualHub) {
                                #Write-Output "The Azure Firewall is managed by Azure Firewall Manager (in a Secured Virtual Hub)."
                            } elseif ($AzFirewall.FirewallPolicy) {
                                #Write-Output "The Azure Firewall is managed by a Firewall Policy but is not in a Virtual Hub."
                            } else {
                                $InObj[$LocalizedData.NatRuleCollections] = $AzFirewall.NatRuleCollections.Count
                                $InObj[$LocalizedData.NetworkRuleCollections] = $AzFirewall.NetworkRuleCollections.Count
                                $InObj[$LocalizedData.ApplicationRuleCollections] = $AzFirewall.ApplicationRuleCollections.Count
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzFirewall.Tag)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzFirewall.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzFirewallInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.Firewall.ProvisioningState) {
                            $AzFirewallInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.Firewall -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzFirewall in $AzFirewallInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $AzFirewall.Name {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzFirewall.Name)"
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
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Headers = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location #, $LocalizedData.NatRules, $LocalizedData.NetworkRules, $LocalizedData.AppRules
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location #, $LocalizedData.NatRuleCollections, $LocalizedData.NetworkRuleCollections, $LocalizedData.ApplicationRuleCollections
                                #ColumnWidths = 25, 21, 21, 11, 11, 11
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