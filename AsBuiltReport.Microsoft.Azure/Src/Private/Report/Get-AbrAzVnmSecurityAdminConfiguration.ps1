function Get-AbrAzVnmSecurityAdminConfiguration {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Manager security admin configuration information
    .DESCRIPTION
        Documents the security admin configurations of an Azure Virtual Network Manager and, at InfoLevel 3 and above,
        the rule collections and security admin rules of each configuration, in Word/HTML/Text formats using PScribo.
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
        $LocalizedData = $reportTranslate.GetAbrAzVnmSecurityAdminConfiguration
    }

    process {
        Try {
            $AzSecurityAdminConfigs = Get-AzNetworkManagerSecurityAdminConfiguration -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name
            if ($AzSecurityAdminConfigs) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $NetworkManagerName)

                # Collect rule collections, and at InfoLevel 3 their rules, before any output is written
                $RuleCollectionMap = @{}
                $RuleMap = @{}
                foreach ($AzSecurityAdminConfig in $AzSecurityAdminConfigs) {
                    Try {
                        $RuleCollectionMap[$AzSecurityAdminConfig.Name] = @(Get-AzNetworkManagerSecurityAdminRuleCollection -SecurityAdminConfigurationName $AzSecurityAdminConfig.Name -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name)
                    } Catch {
                        Write-PScriboMessage -IsWarning ($LocalizedData.RuleCollectionError -f $AzSecurityAdminConfig.Name, $_.Exception.Message)
                        $RuleCollectionMap[$AzSecurityAdminConfig.Name] = $null
                    }
                    if ($InfoLevel.VirtualNetworkManager -ge 3) {
                        foreach ($AzRuleCollection in $RuleCollectionMap[$AzSecurityAdminConfig.Name]) {
                            $RuleKey = "$($AzSecurityAdminConfig.Name)/$($AzRuleCollection.Name)"
                            Try {
                                $RuleMap[$RuleKey] = @(Get-AzNetworkManagerSecurityAdminRule -RuleCollectionName $AzRuleCollection.Name -SecurityAdminConfigurationName $AzSecurityAdminConfig.Name -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Priority)
                            } Catch {
                                Write-PScriboMessage -IsWarning ($LocalizedData.RuleError -f $AzRuleCollection.Name, $_.Exception.Message)
                                $RuleMap[$RuleKey] = $null
                            }
                        }
                    }
                }

                $AzSecurityAdminConfigInfo = foreach ($AzSecurityAdminConfig in $AzSecurityAdminConfigs) {
                    [PSCustomObject]@{
                        $LocalizedData.Name = $AzSecurityAdminConfig.Name
                        $LocalizedData.Description = $(if ($AzSecurityAdminConfig.Description) {
                            $AzSecurityAdminConfig.Description
                        } else {
                            $LocalizedData.None
                        })
                        $LocalizedData.RuleCollections = $(if ($null -eq $RuleCollectionMap[$AzSecurityAdminConfig.Name]) {
                            $LocalizedData.Unknown
                        } else {
                            $RuleCollectionMap[$AzSecurityAdminConfig.Name].Count
                        })
                        # A configuration only takes effect once it has been committed to at least one region
                        $LocalizedData.DeployedRegions = $(if ($null -eq $DeploymentStatus) {
                            $LocalizedData.Unknown
                        } else {
                            $DeployedRegions = $DeploymentStatus | Where-Object { ($_.DeploymentStatus -eq 'Deployed') -and ($_.ConfigurationIds -contains $AzSecurityAdminConfig.Id) } | ForEach-Object { if ($AzLocationLookup."$($_.Region)") { $AzLocationLookup."$($_.Region)" } else { $_.Region } } | Sort-Object -Unique
                            if ($DeployedRegions) { $DeployedRegions -join ', ' } else { $LocalizedData.None }
                        })
                    }
                }

                if ($Healthcheck.VirtualNetworkManager.UndeployedConfiguration) {
                    $AzSecurityAdminConfigInfo | Where-Object { $_.$($LocalizedData.DeployedRegions) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.DeployedRegions
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
                    $AzSecurityAdminConfigInfo | Table @TableParams

                    if ($InfoLevel.VirtualNetworkManager -ge 3) {
                        foreach ($AzSecurityAdminConfig in $AzSecurityAdminConfigs) {
                            $ConfigSummary = $AzSecurityAdminConfigInfo | Where-Object { $_.$($LocalizedData.Name) -eq $AzSecurityAdminConfig.Name }
                            $AzSecurityAdminConfigDetail = [PSCustomObject]@{
                                $LocalizedData.Name = $AzSecurityAdminConfig.Name
                                $LocalizedData.Description = $ConfigSummary.($LocalizedData.Description)
                                $LocalizedData.ProvisioningState = $AzSecurityAdminConfig.ProvisioningState
                                $LocalizedData.ApplyOnNetworkIntentPolicyBasedServices = $(if ($AzSecurityAdminConfig.ApplyOnNetworkIntentPolicyBasedServices) {
                                    $AzSecurityAdminConfig.ApplyOnNetworkIntentPolicyBasedServices -join ', '
                                } else {
                                    $LocalizedData.None
                                })
                                $LocalizedData.AddressSpaceAggregation = $(if ($AzSecurityAdminConfig.NetworkGroupAddressSpaceAggregationOption) {
                                    $AzSecurityAdminConfig.NetworkGroupAddressSpaceAggregationOption
                                } else {
                                    $LocalizedData.NotConfigured
                                })
                                $LocalizedData.DeployedRegions = $ConfigSummary.($LocalizedData.DeployedRegions)
                            }

                            if ($Healthcheck.VirtualNetworkManager.UndeployedConfiguration) {
                                $AzSecurityAdminConfigDetail | Where-Object { $_.$($LocalizedData.DeployedRegions) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.DeployedRegions
                            }

                            $AzRuleCollections = $RuleCollectionMap[$AzSecurityAdminConfig.Name]
                            $AzRuleCollectionInfo = foreach ($AzRuleCollection in $AzRuleCollections) {
                                $RuleKey = "$($AzSecurityAdminConfig.Name)/$($AzRuleCollection.Name)"
                                [PSCustomObject]@{
                                    $LocalizedData.Name = $AzRuleCollection.Name
                                    $LocalizedData.NetworkGroups = $(if ($AzRuleCollection.AppliesToGroups.NetworkGroupId) {
                                        ($AzRuleCollection.AppliesToGroups.NetworkGroupId | ForEach-Object { $_.split('/')[-1] } | Sort-Object) -join ', '
                                    } else {
                                        $LocalizedData.None
                                    })
                                    $LocalizedData.Rules = $(if ($null -eq $RuleMap[$RuleKey]) {
                                        $LocalizedData.Unknown
                                    } else {
                                        $RuleMap[$RuleKey].Count
                                    })
                                }
                            }

                            Section -Style NOTOCHeading7 -ExcludeFromTOC "$($AzSecurityAdminConfig.Name)" {
                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeading) - $($AzSecurityAdminConfig.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzSecurityAdminConfigDetail | Table @TableParams

                                if ($AzRuleCollectionInfo) {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.RuleCollectionTableHeading) - $($AzSecurityAdminConfig.Name)"
                                        List = $false
                                        ColumnWidths = 30, 50, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRuleCollectionInfo | Table @TableParams
                                }

                                foreach ($AzRuleCollection in $AzRuleCollections) {
                                    $AzRules = $RuleMap["$($AzSecurityAdminConfig.Name)/$($AzRuleCollection.Name)"]
                                    if ($AzRules) {
                                        $AzRuleInfo = foreach ($AzRule in $AzRules) {
                                            $RuleObj = [PSCustomObject]@{
                                                $LocalizedData.Priority = $AzRule.Priority
                                                $LocalizedData.Name = $AzRule.Name
                                                $LocalizedData.Access = switch ($AzRule.Access) {
                                                    'Allow' { $LocalizedData.Allow }
                                                    'AlwaysAllow' { $LocalizedData.AlwaysAllow }
                                                    'Deny' { $LocalizedData.Deny }
                                                    default { $AzRule.Access }
                                                }
                                                $LocalizedData.Direction = switch ($AzRule.Direction) {
                                                    'Inbound' { $LocalizedData.Inbound }
                                                    'Outbound' { $LocalizedData.Outbound }
                                                    default { $AzRule.Direction }
                                                }
                                                $LocalizedData.Protocol = $AzRule.Protocol
                                                $LocalizedData.Source = $(if ($AzRule.Sources.AddressPrefix) { $AzRule.Sources.AddressPrefix -join ', ' } else { '*' })
                                                $LocalizedData.Destination = $(if ($AzRule.Destinations.AddressPrefix) { $AzRule.Destinations.AddressPrefix -join ', ' } else { '*' })
                                                $LocalizedData.DestinationPorts = $(if ($AzRule.DestinationPortRanges) { $AzRule.DestinationPortRanges -join ', ' } else { '*' })
                                            }
                                            # Always Allow rules bypass NSGs, so allowing them from any source exposes every member network
                                            if ($Healthcheck.VirtualNetworkManager.PermissiveSecurityAdminRule -and ($AzRule.Access -eq 'AlwaysAllow') -and ($AzRule.Direction -eq 'Inbound') -and ((-not $AzRule.Sources.AddressPrefix) -or ($AzRule.Sources.AddressPrefix | Where-Object { $_ -in @('*', 'Internet', '0.0.0.0/0') }))) {
                                                $RuleObj | Set-Style -Style Warning -Property $LocalizedData.Access, $LocalizedData.Source
                                            }
                                            $RuleObj
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.RuleTableHeading) - $($AzRuleCollection.Name)"
                                            List = $false
                                            ColumnWidths = 9, 16, 11, 11, 10, 15, 15, 13
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
