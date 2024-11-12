function Get-AbrAzDnsPrivateResolver {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure DNS Private Resolver information
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
    )

    begin {
        Write-PScriboMessage "DnsPrivateResolver InfoLevel set at $($InfoLevel.DnsPrivateResolver)."
    }

    process {
        Try {
            if ($InfoLevel.DnsPrivateResolver -gt 0) {
                $AzDnsPrivateResolvers = Get-AzDnsResolver | Sort-Object Name
                if ($AzDnsPrivateResolvers) {
                    Write-PscriboMessage "Collecting Azure DNS Private Resolver information."
                    Section -Style Heading4 'DNS Private Resolver' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "Azure Private DNS Resolver is a service that securely resolves DNS queries for private resources in Azure VNets, enabling seamless communication between on-premises and cloud environments without exposing traffic to the public internet. It centralises DNS management and supports hybrid cloud architectures."
                        }
                        $AzDnsPrivateResolverInfo = @()
                        foreach ($AzDnsPrivateResolver in $AzDnsPrivateResolvers) {
                            $AzResourceGroup = Get-AzResource -ResourceType $AzDnsPrivateResolver.Type
                            $AzDnsResolverInboundEndpoint = Get-AzDnsResolverInboundEndpoint -DnsResolverName $AzDnsPrivateResolver.Name -ResourceGroupName $AzResourceGroup.ResourceGroupName
                            $AzDnsResolverOutboundEndpoint = Get-AzDnsResolverOutboundEndpoint -DnsResolverName $AzDnsPrivateResolver.Name -ResourceGroupName $AzResourceGroup.ResourceGroupName
                            $InObj = [Ordered]@{
                                'Name' = $AzDnsPrivateResolver.Name
                                'Resource Group' = $AzResourceGroup.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzDnsPrivateResolver.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzDnsPrivateResolver.Id).split('/')[2]))"
                                'Inbound Endpoints' = $AzDnsResolverInboundEndpoint.Count
                                'Outbound Endpoints' = $AzDnsResolverOutboundEndpoint.Count
                                'Virtual Network' = ($AzDnsPrivateResolver.VirtualNetworkId).split('/')[-1]
                                'Resource Guid' = $AzDnsPrivateResolver.ResourceGuid
                                'Creation Time' = get-date $AzDnsPrivateResolver.SystemDataCreatedAt.ToLocalTime() -format G
                                'Last Modified' = get-date $AzDnsPrivateResolver.SystemDataLastModifiedAt.ToLocalTime() -format G
                                'Current State' = $AzDnsPrivateResolver.State
                                'Provisioning State' = $AzDnsPrivateResolver.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzResourceGroup.Tags)) {
                                    'None'
                                } else {
                                    ($AzResourceGroup.Tags.GetEnumerator() | ForEach-Object {"$($_.Key):`t$($_.Value)"}) -join [Environment]::NewLine
                                }
                            }

                            $AzDnsPrivateResolverInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.DnsPrivateResolver -ge 2) {
                            Paragraph "The following sections detail the configuration of the DNS private resolver(s) within the $($AzSubscription.Name) subscription."
                            foreach ($AzDnsPrivateResolver in $AzDnsPrivateResolverInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzDnsPrivateResolver.Name)" {
                                    $TableParams = @{
                                        Name = "Private DNS Resolver - $($AzDnsPrivateResolver.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzDnsPrivateResolver | Table @TableParams

                                    # Inbound Endpoints
                                    if ($AzDnsResolverInboundEndpoint) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Inbound Endpoints' {
                                            $InboundEndpointInfo = @()
                                            $InObj = [Ordered]@{
                                                'Endpoint Name' = $AzDnsResolverInboundEndpoint.Name
                                                'IP Address' = $AzDnsResolverInboundEndpoint.IPConfiguration.PrivateIPAddress
                                                'IP Allocation' = $AzDnsResolverInboundEndpoint.IPConfiguration.PrivateIPAllocationMethod
                                            }
                                            $InboundEndpointInfo += [PSCustomObject]$InObj

                                            $TableParams = @{
                                                Name = "Inbound Endpoints - $($AzDnsPrivateResolver.Name)"
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
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Outbound Endpoints' {
                                            $OutboundEndpointInfo = @()
                                            $InObj = [Ordered]@{
                                                'Endpoint Name' = $AzDnsResolverOutboundEndpoint.Name
                                                'IP Address' = $AzDnsResolverOutboundEndpoint.IPConfiguration.PrivateIPAddress
                                                'IP Allocation' = $AzDnsResolverOutboundEndpoint.IPConfiguration.PrivateIPAllocationMethod
                                            }
                                            $OutboundEndpointInfo += [PSCustomObject]$InObj

                                            $TableParams = @{
                                                Name = "Outbound Endpoints - $($AzDnsPrivateResolver.Name)"
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
                            Paragraph "The following table summarises the configuration of the DNS private resolver(s) within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "DNS Private Resolver - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Resource Group', 'Location', 'Subscription'
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
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}