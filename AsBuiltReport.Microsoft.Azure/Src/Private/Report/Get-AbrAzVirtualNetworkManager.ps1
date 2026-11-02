function Get-AbrAzVirtualNetworkManager {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Manager information
    .DESCRIPTION
        Documents the Azure Virtual Network Manager instances within the current subscription, including
        their management scope, enabled features, network groups, connectivity, security admin and routing
        configurations, and configuration deployments, in Word/HTML/Text formats using PScribo.
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
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVirtualNetworkManager
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.VirtualNetworkManager)
    }

    process {
        Try {
            if ($InfoLevel.VirtualNetworkManager -gt 0) {
                $AzNetworkManagers = Get-AzNetworkManager -ErrorAction Stop | Sort-Object Name
                if ($AzNetworkManagers) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $LockMap = @{}
                        $AllLocks = Get-AzResourceLock -ErrorAction SilentlyContinue
                        foreach ($Lock in $AllLocks) {
                            $Key = $Lock.ResourceId.ToLower()
                            if (-not $LockMap.ContainsKey($Key)) { $LockMap[$Key] = @() }
                            $LockMap[$Key] += $Lock
                        }

                        $AzNetworkManagerInfo = @()
                        $ScopeAccessMap = @{}
                        $DeploymentStatusMap = @{}
                        $Count = 1
                        foreach ($AzNetworkManager in $AzNetworkManagers) {
                            Write-PScriboMessage ($LocalizedData.Processing -f ($AzNetworkManager.Name), $Count, ($AzNetworkManagers.Count))
                            $Count ++
                            Try {
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name = $AzNetworkManager.Name
                                    $LocalizedData.ResourceGroup = $AzNetworkManager.ResourceGroupName
                                    $LocalizedData.Location = $AzLocationLookup."$($AzNetworkManager.Location)"
                                    $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzNetworkManager.Id).split('/')[2]))"
                                    $LocalizedData.SubscriptionID = ($AzNetworkManager.Id).split('/')[2]
                                    $LocalizedData.ProvisioningState = $AzNetworkManager.ProvisioningState
                                    $LocalizedData.Description = $(if ($AzNetworkManager.Description) {
                                        $AzNetworkManager.Description
                                    } else {
                                        $LocalizedData.None
                                    })
                                    $LocalizedData.Features = $(if ($AzNetworkManager.NetworkManagerScopeAccesses) {
                                        ($AzNetworkManager.NetworkManagerScopeAccesses | ForEach-Object {
                                            switch ($_) {
                                                'Connectivity' { $LocalizedData.Connectivity }
                                                'SecurityAdmin' { $LocalizedData.SecurityAdmin }
                                                'Routing' { $LocalizedData.Routing }
                                                default { $_ }
                                            }
                                        }) -join ', '
                                    } else {
                                        $LocalizedData.None
                                    })
                                    # Scope IDs are full resource IDs; show the management group ID and the subscription name where it can be resolved
                                    $LocalizedData.ManagementGroupScope = $(if ($AzNetworkManager.NetworkManagerScopes.ManagementGroups) {
                                        ($AzNetworkManager.NetworkManagerScopes.ManagementGroups | ForEach-Object { $_.split('/')[-1] } | Sort-Object) -join [Environment]::NewLine
                                    } else {
                                        $LocalizedData.None
                                    })
                                    $LocalizedData.SubscriptionScope = $(if ($AzNetworkManager.NetworkManagerScopes.Subscriptions) {
                                        ($AzNetworkManager.NetworkManagerScopes.Subscriptions | ForEach-Object {
                                            $ScopeSubscriptionId = $_.split('/')[-1]
                                            if ($AzSubscriptionLookup.$ScopeSubscriptionId) {
                                                $AzSubscriptionLookup.$ScopeSubscriptionId
                                            } else {
                                                $ScopeSubscriptionId
                                            }
                                        } | Sort-Object) -join [Environment]::NewLine
                                    } else {
                                        $LocalizedData.None
                                    })
                                }

                                $InObj[$LocalizedData.Locks] = $(
                                    $rl = $LockMap[$AzNetworkManager.Id.ToLower()]
                                    if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                    else { $LocalizedData.None }
                                )

                                if ($Options.ShowTags) {
                                    $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzNetworkManager.Tag)) {
                                        $LocalizedData.None
                                    } else {
                                        ($AzNetworkManager.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                    }
                                }

                                $AzNetworkManagerInfo += [PSCustomObject]$InObj
                                $ScopeAccessMap[$AzNetworkManager.Name] = @($AzNetworkManager.NetworkManagerScopeAccesses)

                                # Deployment status is shared by the configuration sections and the deployment table, so collect it once per manager
                                if ($InfoLevel.VirtualNetworkManager -ge 2) {
                                    Try {
                                        $AzDeployments = @()
                                        $SkipToken = $null
                                        do {
                                            $DeploymentParams = @{
                                                NetworkManagerName = $AzNetworkManager.Name
                                                ResourceGroupName = $AzNetworkManager.ResourceGroupName
                                                ErrorAction = 'Stop'
                                            }
                                            if ($SkipToken) {
                                                $DeploymentParams['SkipToken'] = $SkipToken
                                            }
                                            $AzDeploymentResult = Get-AzNetworkManagerDeploymentStatus @DeploymentParams
                                            $AzDeployments += @($AzDeploymentResult.Value | Where-Object { $_ })
                                            $SkipToken = $AzDeploymentResult.SkipToken
                                        } while ($SkipToken)
                                        $DeploymentStatusMap[$AzNetworkManager.Name] = $AzDeployments
                                    } Catch {
                                        Write-PScriboMessage -IsWarning ($LocalizedData.DeploymentStatusError -f $AzNetworkManager.Name, $_.Exception.Message)
                                        $DeploymentStatusMap[$AzNetworkManager.Name] = $null
                                    }
                                }
                            } Catch {
                                Write-PScriboMessage -IsWarning ($LocalizedData.ProcessingError -f $AzNetworkManager.Name, $_.Exception.Message)
                            }
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.VirtualNetworkManager.ProvisioningState) {
                            $AzNetworkManagerInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.VirtualNetworkManager -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzNetworkManager in $AzNetworkManagerInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzNetworkManager.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzNetworkManager.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzNetworkManager | Table @TableParams

                                    $NetworkManagerName = $AzNetworkManager.($LocalizedData.Name)
                                    $NetworkManagerResourceGroup = $AzNetworkManager.($LocalizedData.ResourceGroup)
                                    $NetworkManagerDeployments = $DeploymentStatusMap[$NetworkManagerName]
                                    $NetworkManagerScopeAccesses = $ScopeAccessMap[$NetworkManagerName]

                                    # Network Groups
                                    Get-AbrAzVnmNetworkGroup -NetworkManagerName $NetworkManagerName -ResourceGroupName $NetworkManagerResourceGroup
                                    # Configurations are only reported for the features the network manager has enabled
                                    if ($NetworkManagerScopeAccesses -contains 'Connectivity') {
                                        Get-AbrAzVnmConnectivityConfiguration -NetworkManagerName $NetworkManagerName -ResourceGroupName $NetworkManagerResourceGroup -DeploymentStatus $NetworkManagerDeployments
                                    }
                                    if ($NetworkManagerScopeAccesses -contains 'SecurityAdmin') {
                                        Get-AbrAzVnmSecurityAdminConfiguration -NetworkManagerName $NetworkManagerName -ResourceGroupName $NetworkManagerResourceGroup -DeploymentStatus $NetworkManagerDeployments
                                    }
                                    if ($NetworkManagerScopeAccesses -contains 'Routing') {
                                        Get-AbrAzVnmRoutingConfiguration -NetworkManagerName $NetworkManagerName -ResourceGroupName $NetworkManagerResourceGroup -DeploymentStatus $NetworkManagerDeployments
                                    }
                                    # Configuration Deployments
                                    Get-AbrAzVnmDeploymentStatus -NetworkManagerName $NetworkManagerName -DeploymentStatus $NetworkManagerDeployments
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Features
                                ColumnWidths = 25, 25, 20, 30
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzNetworkManagerInfo | Table @TableParams
                        }
                        BlankLine
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}
