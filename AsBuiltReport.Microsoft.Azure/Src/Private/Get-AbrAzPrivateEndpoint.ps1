function Get-AbrAzPrivateEndpoint {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Private Endpoint information
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
        $LocalizedData = $reportTranslate.GetAbrAzPrivateEndpoint
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.PrivateEndpoint)
    }

    process {
        Try {
            if ($InfoLevel.PrivateEndpoint -gt 0) {
                $AzPrivateEndpoints = Get-AzPrivateEndpoint | Sort-Object Name
                if ($AzPrivateEndpoints) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzPrivateEndpointInfo = @()
                        foreach ($AzPrivateEndpoint in $AzPrivateEndpoints) {
                            # Extract NIC details
                            $nicId = $AzPrivateEndpoint.NetworkInterfaces[0].Id
                            if (-not $nicId) {
                                Write-PScriboMessage -IsWarning "Skipping Private Endpoint '$($AzPrivateEndpoint.Name)' - No network interface found"
                                continue
                            }
                            $nicName = $nicId.Split("/")[-1]
                            $nicRg = $nicId.Split("/")[4]
                            $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $nicRg -ErrorAction SilentlyContinue

                            # Extract <vnet>/<subnet> from subnet ID
                            if (-not $AzPrivateEndpoint.Subnet.Id) {
                                Write-PScriboMessage -IsWarning "Skipping Private Endpoint '$($AzPrivateEndpoint.Name)' - No subnet found"
                                continue
                            }
                            $subnetParts = $AzPrivateEndpoint.Subnet.Id.Split("/")
                            $vnetName = $subnetParts[$subnetParts.IndexOf("virtualNetworks") + 1]
                            $subnetName = $subnetParts[$subnetParts.IndexOf("subnets") + 1]

                            # Extract Private Link Service connection info
                            $plsConnection = $AzPrivateEndpoint.PrivateLinkServiceConnections[0]
                            $plsName = if ($plsConnection.PrivateLinkServiceId) {
                                $plsConnection.PrivateLinkServiceId.Split("/")[-1]
                            } else {
                                "N/A"
                            }
                            $RequestMessage = $plsConnection.RequestMessage
                            $ResponseMessage = $plsConnection.PrivateLinkServiceConnectionState.Description

                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzPrivateEndpoint.Name
                                $LocalizedData.ResourceGroup = $AzPrivateEndpoint.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzPrivateEndpoint.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzPrivateEndpoint.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzPrivateEndpoint.Id).split('/')[2]
                                $LocalizedData.ProvisioningState = $plsConnection.ProvisioningState
                                $LocalizedData.VirtualNetworkSubnet = "$vnetName/$subnetName"
                                $LocalizedData.NetworkInterface = $nicName
                                $LocalizedData.PrivateLinkResource = $plsName
                                $LocalizedData.PrivateIP = $nic.IpConfigurations[0].PrivateIpAddress
                                $LocalizedData.TargetSubResource = ($plsConnection.GroupIds -join ",")
                                $LocalizedData.ConnectionStatus = $plsConnection.PrivateLinkServiceConnectionState.Status
                                $LocalizedData.Response = $ResponseMessage
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzPrivateEndpoint.Tag)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzPrivateEndpoint.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzPrivateEndpointInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.PrivateEndpoint.ProvisioningState) {
                            $AzPrivateEndpointInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.PrivateEndpoint.ConnectionStatus) {
                            $AzPrivateEndpointInfo | Where-Object { $_.$($LocalizedData.ConnectionStatus) -ne 'Approved' } | Set-Style -Style Critical -Property $LocalizedData.ConnectionStatus
                        }

                        if ($InfoLevel.PrivateEndpoint -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzPrivateEndpoint in $AzPrivateEndpointInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzPrivateEndpoint.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.Heading) - $($AzPrivateEndpoint.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzPrivateEndpoint | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.PrivateIP
                                ColumnWidths = 25, 25, 25, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzPrivateEndpointInfo | Table @TableParams
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