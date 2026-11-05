function Get-AbrAzVnmRoutingConfiguration {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Manager routing configuration information
    .DESCRIPTION
        Documents the routing configurations of an Azure Virtual Network Manager and, at InfoLevel 3 and above, the rule collections and routing rules of each configuration, in Word/HTML/Text formats using PScribo.
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
        $LocalizedData = $reportTranslate.GetAbrAzVnmRoutingConfiguration
    }

    process {
        Try {
            $AzRoutingConfigs = Get-AzNetworkManagerRoutingConfiguration -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name
            if ($AzRoutingConfigs) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $NetworkManagerName)

                # Collect rule collections, and at InfoLevel 3 their rules, before any output is written
                $RuleCollectionMap = @{}
                $RuleMap = @{}
                foreach ($AzRoutingConfig in $AzRoutingConfigs) {
                    Try {
                        $RuleCollectionMap[$AzRoutingConfig.Name] = @(Get-AzNetworkManagerRoutingRuleCollection -RoutingConfigurationName $AzRoutingConfig.Name -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name)
                    } Catch {
                        Write-PScriboMessage -IsWarning ($LocalizedData.RuleCollectionError -f $AzRoutingConfig.Name, $_.Exception.Message)
                        $RuleCollectionMap[$AzRoutingConfig.Name] = $null
                    }
                    if ($InfoLevel.VirtualNetworkManager -ge 3) {
                        foreach ($AzRuleCollection in $RuleCollectionMap[$AzRoutingConfig.Name]) {
                            $RuleKey = "$($AzRoutingConfig.Name)/$($AzRuleCollection.Name)"
                            Try {
                                $RuleMap[$RuleKey] = @(Get-AzNetworkManagerRoutingRule -RuleCollectionName $AzRuleCollection.Name -RoutingConfigurationName $AzRoutingConfig.Name -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name)
                            } Catch {
                                Write-PScriboMessage -IsWarning ($LocalizedData.RuleError -f $AzRuleCollection.Name, $_.Exception.Message)
                                $RuleMap[$RuleKey] = $null
                            }
                        }
                    }
                }

                $AzRoutingConfigInfo = foreach ($AzRoutingConfig in $AzRoutingConfigs) {
                    [PSCustomObject]@{
                        $LocalizedData.Name = $AzRoutingConfig.Name
                        $LocalizedData.Description = $(if ($AzRoutingConfig.Description) {
                            $AzRoutingConfig.Description
                        } else {
                            $LocalizedData.None
                        })
                        $LocalizedData.RuleCollections = $(if ($null -eq $RuleCollectionMap[$AzRoutingConfig.Name]) {
                            $LocalizedData.Unknown
                        } else {
                            $RuleCollectionMap[$AzRoutingConfig.Name].Count
                        })
                        # A configuration only takes effect once it has been committed to at least one region
                        $LocalizedData.DeployedRegions = $(if ($null -eq $DeploymentStatus) {
                            $LocalizedData.Unknown
                        } else {
                            $DeployedRegions = $DeploymentStatus | Where-Object { ($_.DeploymentStatus -eq 'Deployed') -and ($_.ConfigurationIds -contains $AzRoutingConfig.Id) } | ForEach-Object { if ($AzLocationLookup."$($_.Region)") { $AzLocationLookup."$($_.Region)" } else { $_.Region } } | Sort-Object -Unique
                            if ($DeployedRegions) { $DeployedRegions -join ', ' } else { $LocalizedData.None }
                        })
                    }
                }

                if ($Healthcheck.VirtualNetworkManager.UndeployedConfiguration) {
                    $AzRoutingConfigInfo | Where-Object { $_.$($LocalizedData.DeployedRegions) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.DeployedRegions
                }

                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeadings) - $NetworkManagerName"
                        List = $false
                        ColumnWidths = 30, 30, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzRoutingConfigInfo | Table @TableParams

                    if ($InfoLevel.VirtualNetworkManager -ge 3) {
                        foreach ($AzRoutingConfig in $AzRoutingConfigs) {
                            $ConfigSummary = $AzRoutingConfigInfo | Where-Object { $_.$($LocalizedData.Name) -eq $AzRoutingConfig.Name }
                            $AzRoutingConfigDetail = [PSCustomObject]@{
                                $LocalizedData.Name = $AzRoutingConfig.Name
                                $LocalizedData.Description = $ConfigSummary.($LocalizedData.Description)
                                $LocalizedData.ProvisioningState = $AzRoutingConfig.ProvisioningState
                                $LocalizedData.RouteTableUsageMode = $(if ($AzRoutingConfig.RouteTableUsageMode) {
                                    $AzRoutingConfig.RouteTableUsageMode
                                } else {
                                    $LocalizedData.NotConfigured
                                })
                                $LocalizedData.DeployedRegions = $ConfigSummary.($LocalizedData.DeployedRegions)
                            }

                            if ($Healthcheck.VirtualNetworkManager.UndeployedConfiguration) {
                                $AzRoutingConfigDetail | Where-Object { $_.$($LocalizedData.DeployedRegions) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.DeployedRegions
                            }

                            $AzRuleCollections = $RuleCollectionMap[$AzRoutingConfig.Name]
                            $AzRuleCollectionInfo = foreach ($AzRuleCollection in $AzRuleCollections) {
                                $RuleKey = "$($AzRoutingConfig.Name)/$($AzRuleCollection.Name)"
                                [PSCustomObject]@{
                                    $LocalizedData.Name = $AzRuleCollection.Name
                                    $LocalizedData.NetworkGroups = $(if ($AzRuleCollection.AppliesTo.NetworkGroupId) {
                                        ($AzRuleCollection.AppliesTo.NetworkGroupId | ForEach-Object { $_.split('/')[-1] } | Sort-Object) -join ', '
                                    } else {
                                        $LocalizedData.None
                                    })
                                    $LocalizedData.BgpRoutePropagation = $(if ($AzRuleCollection.DisableBgpRoutePropagation -eq 'True') { $LocalizedData.Disabled } else { $LocalizedData.Enabled })
                                    $LocalizedData.Rules = $(if ($null -eq $RuleMap[$RuleKey]) {
                                        $LocalizedData.Unknown
                                    } else {
                                        $RuleMap[$RuleKey].Count
                                    })
                                }
                            }

                            Section -Style NOTOCHeading7 -ExcludeFromTOC "$($AzRoutingConfig.Name)" {
                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeading) - $($AzRoutingConfig.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzRoutingConfigDetail | Table @TableParams

                                if ($AzRuleCollectionInfo) {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.RuleCollectionTableHeading) - $($AzRoutingConfig.Name)"
                                        List = $false
                                        ColumnWidths = 25, 40, 20, 15
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRuleCollectionInfo | Table @TableParams
                                }

                                foreach ($AzRuleCollection in $AzRuleCollections) {
                                    $AzRules = $RuleMap["$($AzRoutingConfig.Name)/$($AzRuleCollection.Name)"]
                                    if ($AzRules) {
                                        $AzRuleInfo = foreach ($AzRule in $AzRules) {
                                            [PSCustomObject]@{
                                                $LocalizedData.Name = $AzRule.Name
                                                $LocalizedData.Destination = $AzRule.Destination.DestinationAddress
                                                $LocalizedData.DestinationType = $AzRule.Destination.Type
                                                $LocalizedData.NextHopType = $AzRule.NextHop.NextHopType
                                                $LocalizedData.NextHopAddress = $(if ($AzRule.NextHop.NextHopAddress) { $AzRule.NextHop.NextHopAddress } else { $LocalizedData.None })
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.RuleTableHeading) - $($AzRuleCollection.Name)"
                                            List = $false
                                            ColumnWidths = 25, 25, 15, 17, 18
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $AzRuleInfo | Table @TableParams
                                    }
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
