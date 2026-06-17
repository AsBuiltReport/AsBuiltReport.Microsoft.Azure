function Get-AbrAzPublicIpAddress {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Public IP Address information
    .DESCRIPTION
        Documents the configuration of Azure Public IP Addresses including allocation method,
        SKU, DNS settings, and associated resource.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param ()

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzPublicIpAddress
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.PublicIpAddress)
    }

    process {
        try {
            if ($InfoLevel.PublicIpAddress -ge 1) {
                $AzPublicIps = Get-AzPublicIpAddress -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzPublicIps) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzPublicIpInfo = @()
                        foreach ($AzPip in $AzPublicIps) {
                            $AssociatedResource = if ($AzPip.IpConfiguration.Id) {
                                ($AzPip.IpConfiguration.Id).split('/')[-3]
                            } else {
                                $LocalizedData.None
                            }

                            $Zones = if ($AzPip.Zones -and $AzPip.Zones.Count -gt 0) {
                                $AzPip.Zones -join ', '
                            } else {
                                $LocalizedData.None
                            }

                            $InObj = [Ordered]@{
                                $LocalizedData.Name               = $AzPip.Name
                                $LocalizedData.ResourceGroup      = $AzPip.ResourceGroupName
                                $LocalizedData.Location           = $AzLocationLookup."$($AzPip.Location)"
                                $LocalizedData.Subscription       = "$($AzSubscriptionLookup.(($AzPip.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID     = ($AzPip.Id).split('/')[2]
                                $LocalizedData.SKU                = $AzPip.Sku.Name
                                $LocalizedData.Tier               = $AzPip.Sku.Tier
                                $LocalizedData.IpVersion          = $AzPip.PublicIpAddressVersion
                                $LocalizedData.AllocationMethod   = $AzPip.PublicIpAllocationMethod
                                $LocalizedData.IpAddress          = if ($AzPip.IpAddress) { $AzPip.IpAddress } else { $LocalizedData.NotAssigned }
                                $LocalizedData.DnsLabel           = if ($AzPip.DnsSettings.DomainNameLabel) { $AzPip.DnsSettings.DomainNameLabel } else { $LocalizedData.None }
                                $LocalizedData.Fqdn               = if ($AzPip.DnsSettings.Fqdn) { $AzPip.DnsSettings.Fqdn } else { $LocalizedData.None }
                                $LocalizedData.Zones              = $Zones
                                $LocalizedData.AssociatedResource = $AssociatedResource
                                $LocalizedData.ProvisioningState  = $AzPip.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzPip.Tag -or $AzPip.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzPip.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzPublicIpInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.PublicIpAddress.ProvisioningState) {
                            $AzPublicIpInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.PublicIpAddress.Unattached) {
                            $AzPublicIpInfo | Where-Object { $_.$($LocalizedData.AssociatedResource) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.AssociatedResource
                        }

                        if ($InfoLevel.PublicIpAddress -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzPip in $AzPublicIpInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzPip.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $($AzPip.($LocalizedData.Name))"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzPip | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.SKU, $LocalizedData.IpAddress, $LocalizedData.AllocationMethod, $LocalizedData.ProvisioningState
                                ColumnWidths = 20, 15, 15, 10, 15, 12, 13
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzPublicIpInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($LocalizedData.ErrorMessage) $($_.Exception.Message)"
        }
    }

    end {}
}
