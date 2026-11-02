function Get-AbrAzVnmConnectivityConfiguration {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Manager connectivity configuration information
    .DESCRIPTION
        Documents the connectivity configurations of an Azure Virtual Network Manager and, at InfoLevel 3 and above,
        the settings and network groups of each configuration, in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $NetworkManagerName,

        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ResourceGroupName,

        # Deployment status records for the network manager; $null when they could not be collected
        [Parameter(
            Position = 2,
            Mandatory = $false
        )]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Object[]] $DeploymentStatus
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVnmConnectivityConfiguration
    }

    process {
        Try {
            $AzConnectivityConfigs = Get-AzNetworkManagerConnectivityConfiguration -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name
            if ($AzConnectivityConfigs) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $NetworkManagerName)

                $AzConnectivityConfigInfo = foreach ($AzConnectivityConfig in $AzConnectivityConfigs) {
                    [PSCustomObject]@{
                        $LocalizedData.Name = $AzConnectivityConfig.Name
                        $LocalizedData.Topology = switch ($AzConnectivityConfig.ConnectivityTopology) {
                            'HubAndSpoke' { $LocalizedData.HubAndSpoke }
                            'Mesh' { $LocalizedData.Mesh }
                            default { $AzConnectivityConfig.ConnectivityTopology }
                        }
                        $LocalizedData.Hubs = $(if ($AzConnectivityConfig.Hubs.ResourceId) {
                            ($AzConnectivityConfig.Hubs.ResourceId | ForEach-Object { $_.split('/')[-1] } | Sort-Object) -join ', '
                        } else {
                            $LocalizedData.None
                        })
                        $LocalizedData.NetworkGroups = $(if ($AzConnectivityConfig.AppliesToGroups.NetworkGroupId) {
                            ($AzConnectivityConfig.AppliesToGroups.NetworkGroupId | ForEach-Object { $_.split('/')[-1] } | Sort-Object) -join ', '
                        } else {
                            $LocalizedData.None
                        })
                        # A configuration only takes effect once it has been committed to at least one region
                        $LocalizedData.DeployedRegions = $(if ($null -eq $DeploymentStatus) {
                            $LocalizedData.Unknown
                        } else {
                            $DeployedRegions = $DeploymentStatus | Where-Object { ($_.DeploymentStatus -eq 'Deployed') -and ($_.ConfigurationIds -contains $AzConnectivityConfig.Id) } | ForEach-Object { if ($AzLocationLookup."$($_.Region)") { $AzLocationLookup."$($_.Region)" } else { $_.Region } } | Sort-Object -Unique
                            if ($DeployedRegions) { $DeployedRegions -join ', ' } else { $LocalizedData.None }
                        })
                    }
                }

                if ($Healthcheck.VirtualNetworkManager.UndeployedConfiguration) {
                    $AzConnectivityConfigInfo | Where-Object { $_.$($LocalizedData.DeployedRegions) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.DeployedRegions
                }

                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeadings) - $NetworkManagerName"
                        List = $false
                        ColumnWidths = 20, 15, 20, 25, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzConnectivityConfigInfo | Table @TableParams

                    if ($InfoLevel.VirtualNetworkManager -ge 3) {
                        foreach ($AzConnectivityConfig in $AzConnectivityConfigs) {
                            $ConfigSummary = $AzConnectivityConfigInfo | Where-Object { $_.$($LocalizedData.Name) -eq $AzConnectivityConfig.Name }
                            $AzConnectivityConfigDetail = [PSCustomObject]@{
                                $LocalizedData.Name = $AzConnectivityConfig.Name
                                $LocalizedData.Description = $(if ($AzConnectivityConfig.Description) {
                                    $AzConnectivityConfig.Description
                                } else {
                                    $LocalizedData.None
                                })
                                $LocalizedData.ProvisioningState = $AzConnectivityConfig.ProvisioningState
                                $LocalizedData.Topology = $ConfigSummary.($LocalizedData.Topology)
                                $LocalizedData.Hubs = $ConfigSummary.($LocalizedData.Hubs)
                                $LocalizedData.GlobalMesh = $(if ($AzConnectivityConfig.IsGlobal -eq 'True') { $LocalizedData.Yes } else { $LocalizedData.No })
                                $LocalizedData.DeleteExistingPeering = $(if ($AzConnectivityConfig.DeleteExistingPeering -eq 'True') { $LocalizedData.Yes } else { $LocalizedData.No })
                                # Connectivity capabilities are only returned by newer API versions
                                $LocalizedData.AddressOverlap = $(if ($AzConnectivityConfig.ConnectivityCapability.ConnectedGroupAddressOverlap) {
                                    $AzConnectivityConfig.ConnectivityCapability.ConnectedGroupAddressOverlap
                                } else {
                                    $LocalizedData.NotConfigured
                                })
                                $LocalizedData.PrivateEndpointScale = $(if ($AzConnectivityConfig.ConnectivityCapability.ConnectedGroupPrivateEndpointsScale) {
                                    $AzConnectivityConfig.ConnectivityCapability.ConnectedGroupPrivateEndpointsScale
                                } else {
                                    $LocalizedData.NotConfigured
                                })
                                $LocalizedData.PeeringEnforcement = $(if ($AzConnectivityConfig.ConnectivityCapability.PeeringEnforcement) {
                                    $AzConnectivityConfig.ConnectivityCapability.PeeringEnforcement
                                } else {
                                    $LocalizedData.NotConfigured
                                })
                                $LocalizedData.DeployedRegions = $ConfigSummary.($LocalizedData.DeployedRegions)
                            }

                            if ($Healthcheck.VirtualNetworkManager.UndeployedConfiguration) {
                                $AzConnectivityConfigDetail | Where-Object { $_.$($LocalizedData.DeployedRegions) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.DeployedRegions
                            }

                            $AzAppliesToGroupInfo = foreach ($AzAppliesToGroup in $AzConnectivityConfig.AppliesToGroups) {
                                [PSCustomObject]@{
                                    $LocalizedData.NetworkGroup = $AzAppliesToGroup.NetworkGroupId.split('/')[-1]
                                    $LocalizedData.DirectConnectivity = $(if ($AzAppliesToGroup.GroupConnectivity -eq 'DirectlyConnected') { $LocalizedData.Yes } else { $LocalizedData.No })
                                    $LocalizedData.Global = $(if ($AzAppliesToGroup.IsGlobal -eq 'True') { $LocalizedData.Yes } else { $LocalizedData.No })
                                    $LocalizedData.UseHubGateway = $(if ($AzAppliesToGroup.UseHubGateway -eq 'True') { $LocalizedData.Yes } else { $LocalizedData.No })
                                }
                            }

                            Section -Style NOTOCHeading7 -ExcludeFromTOC "$($AzConnectivityConfig.Name)" {
                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeading) - $($AzConnectivityConfig.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzConnectivityConfigDetail | Table @TableParams

                                if ($AzAppliesToGroupInfo) {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.NetworkGroupTableHeading) - $($AzConnectivityConfig.Name)"
                                        List = $false
                                        ColumnWidths = 40, 20, 20, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzAppliesToGroupInfo | Sort-Object $LocalizedData.NetworkGroup | Table @TableParams
                                }
                            }
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning ($LocalizedData.CollectionError -f $NetworkManagerName, $_.Exception.Message)
            Paragraph ($LocalizedData.Unavailable -f $NetworkManagerName)
        }
    }

    end {}
}
