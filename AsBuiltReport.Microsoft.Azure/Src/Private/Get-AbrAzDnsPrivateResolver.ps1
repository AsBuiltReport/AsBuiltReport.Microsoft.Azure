function Get-AbrAzDnsPrivateResolver {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure DNS Private Resolver information
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
        $LocalizedData = $reportTranslate.GetAbrAzDnsPrivateResolver
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.DnsPrivateResolver)
    }

    process {
        Try {
            if ($InfoLevel.DnsPrivateResolver -gt 0) {
                $AzDnsPrivateResolvers = Get-AzDnsResolver | Sort-Object Name
                if ($AzDnsPrivateResolvers) {
                    Write-PscriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            Blankline
                        }
                        $AzDnsPrivateResolverInfo = @()
                        foreach ($AzDnsPrivateResolver in $AzDnsPrivateResolvers) {
                            $AzResourceGroup = Get-AzResource -ResourceType $AzDnsPrivateResolver.Type
                            $AzDnsResolverInboundEndpoint = Get-AzDnsResolverInboundEndpoint -DnsResolverName $AzDnsPrivateResolver.Name -ResourceGroupName $AzResourceGroup.ResourceGroupName
                            $AzDnsResolverOutboundEndpoint = Get-AzDnsResolverOutboundEndpoint -DnsResolverName $AzDnsPrivateResolver.Name -ResourceGroupName $AzResourceGroup.ResourceGroupName
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzDnsPrivateResolver.Name
                                $LocalizedData.ResourceGroup = $AzResourceGroup.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzDnsPrivateResolver.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzDnsPrivateResolver.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzDnsPrivateResolver.Id).split('/')[2]
                                $LocalizedData.InboundEndpoints = $AzDnsResolverInboundEndpoint.Count
                                $LocalizedData.OutboundEndpoints = $AzDnsResolverOutboundEndpoint.Count
                                $LocalizedData.VirtualNetwork = ($AzDnsPrivateResolver.VirtualNetworkId).split('/')[-1]
                                $LocalizedData.ResourceGuid = $AzDnsPrivateResolver.ResourceGuid
                                $LocalizedData.CreationTime = get-date $AzDnsPrivateResolver.SystemDataCreatedAt.ToLocalTime() -format G
                                $LocalizedData.LastModified = get-date $AzDnsPrivateResolver.SystemDataLastModifiedAt.ToLocalTime() -format G
                                $LocalizedData.CurrentState = $AzDnsPrivateResolver.State
                                $LocalizedData.ProvisioningState = $AzDnsPrivateResolver.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzResourceGroup.Tags)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzResourceGroup.Tags.GetEnumerator() | ForEach-Object {"$($_.Key):`t$($_.Value)"}) -join [Environment]::NewLine
                                }
                            }

                            $AzDnsPrivateResolverInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.DnsPrivateResolver.ProvisioningState) {
                            $AzDnsPrivateResolverInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.DnsPrivateResolver.CurrentState) {
                            $AzDnsPrivateResolverInfo | Where-Object { $_.$($LocalizedData.CurrentState) -ne 'Connected' } | Set-Style -Style Warning -Property $LocalizedData.CurrentState
                        }

                        if ($InfoLevel.DnsPrivateResolver -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzDnsPrivateResolver in $AzDnsPrivateResolverInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzDnsPrivateResolver.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzDnsPrivateResolver.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzDnsPrivateResolver | Table @TableParams

                                    # Inbound Endpoints
                                    if ($AzDnsResolverInboundEndpoint) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.InboundEndpoints {
                                            $InboundEndpointInfo = @()
                                            $InObj = [Ordered]@{
                                                $LocalizedData.EndpointName = $AzDnsResolverInboundEndpoint.Name
                                                $LocalizedData.IPAddress = $AzDnsResolverInboundEndpoint.IPConfiguration.PrivateIpAddress
                                                $LocalizedData.IpAllocation = $AzDnsResolverInboundEndpoint.IPConfiguration.PrivateIPAllocationMethod
                                            }
                                            $InboundEndpointInfo += [PSCustomObject]$InObj

                                            $TableParams = @{
                                                Name = "$($LocalizedData.InboundEndpoints) - $($AzDnsPrivateResolver.Name)"
                                                List = $false
                                                ColumnWidths = 40, 30, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $InboundEndpointInfo | Table @TableParams
                                        }
                                    }

                                    # Outbound Endpoints
                                    if ($AzDnsResolverOutboundEndpoint) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.OutboundEndpoints {
                                            $OutboundEndpointInfo = @()
                                            $InObj = [Ordered]@{
                                                $LocalizedData.EndpointName = $AzDnsResolverOutboundEndpoint.Name
                                                $LocalizedData.IpAddress = $AzDnsResolverOutboundEndpoint.IPConfiguration.PrivateIPAddress
                                                $LocalizedData.IpAllocation = $AzDnsResolverOutboundEndpoint.IPConfiguration.PrivateIPAllocationMethod
                                            }
                                            $OutboundEndpointInfo += [PSCustomObject]$InObj

                                            $TableParams = @{
                                                Name = "$($LocalizedData.OutboundEndpoints) - $($AzDnsPrivateResolver.Name)"
                                                List = $false
                                                ColumnWidths = 40, 30, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutboundEndpointInfo | Table @TableParams
                                        }
                                    }
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Subscription
                                ColumnWidths = 25, 25, 25, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzDnsPrivateResolverInfo | Table @TableParams
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}