function Get-AbrAzNetworkWatcher {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Network Watcher and Flow Log information
    .DESCRIPTION
        Documents the configuration of Azure Network Watchers and their associated NSG Flow Logs,
        including retention policy, traffic analytics, and storage account settings.
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
        $LocalizedData = $reportTranslate.GetAbrAzNetworkWatcher
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.NetworkWatcher)
    }

    process {
        try {
            if ($InfoLevel.NetworkWatcher -ge 1) {
                $AzNetworkWatchers = Get-AzNetworkWatcher -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzNetworkWatchers) {
                    Write-PScriboMessage $LocalizedData.Collecting

                    # Pre-collect flow logs per watcher for use at both InfoLevels
                    $FlowLogsMap = @{}
                    foreach ($AzWatcher in $AzNetworkWatchers) {
                        $FlowLogsMap[$AzWatcher.Name] = Get-AzNetworkWatcherFlowLog -NetworkWatcher $AzWatcher -ErrorAction SilentlyContinue
                    }

                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzWatcherInfo = @()
                        foreach ($AzWatcher in $AzNetworkWatchers) {
                            $FlowLogCount = if ($FlowLogsMap[$AzWatcher.Name]) { @($FlowLogsMap[$AzWatcher.Name]).Count } else { 0 }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name              = $AzWatcher.Name
                                $LocalizedData.ResourceGroup     = $AzWatcher.ResourceGroupName
                                $LocalizedData.Location          = $AzLocationLookup."$($AzWatcher.Location)"
                                $LocalizedData.Subscription      = "$($AzSubscriptionLookup.(($AzWatcher.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID    = ($AzWatcher.Id).split('/')[2]
                                $LocalizedData.FlowLogs          = $FlowLogCount
                                $LocalizedData.ProvisioningState = $AzWatcher.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzWatcher.Tag -or $AzWatcher.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzWatcher.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzWatcherInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.NetworkWatcher.ProvisioningState) {
                            $AzWatcherInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.NetworkWatcher -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzWatcherItem in $AzWatcherInfo) {
                                $WatcherName = $AzWatcherItem.($LocalizedData.Name)
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $WatcherName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $WatcherName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzWatcherItem | Table @TableParams

                                    $FlowLogs = $FlowLogsMap[$WatcherName]
                                    if ($FlowLogs) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.FlowLogsHeading {
                                            $FlowLogInfo = @()
                                            foreach ($FlowLog in $FlowLogs) {
                                                $TargetResource = if ($FlowLog.TargetResourceId) {
                                                    ($FlowLog.TargetResourceId).split('/')[-1]
                                                } else {
                                                    $LocalizedData.None
                                                }
                                                $StorageAccount = if ($FlowLog.StorageId) {
                                                    ($FlowLog.StorageId).split('/')[-1]
                                                } else {
                                                    $LocalizedData.None
                                                }
                                                $RetentionDays = if ($FlowLog.RetentionPolicy.Enabled) {
                                                    $FlowLog.RetentionPolicy.Days
                                                } else {
                                                    $LocalizedData.Unlimited
                                                }
                                                $TrafficAnalytics = if ($FlowLog.FlowAnalyticsConfiguration.NetworkWatcherFlowAnalyticsConfiguration.Enabled) {
                                                    $LocalizedData.Enabled
                                                } else {
                                                    $LocalizedData.Disabled
                                                }
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.FlowLogName       = $FlowLog.Name
                                                    $LocalizedData.TargetResource    = $TargetResource
                                                    $LocalizedData.FlowLogEnabled    = $FlowLog.Enabled
                                                    $LocalizedData.RetentionDays     = $RetentionDays
                                                    $LocalizedData.TrafficAnalytics  = $TrafficAnalytics
                                                    $LocalizedData.StorageAccount    = $StorageAccount
                                                    $LocalizedData.ProvisioningState = $FlowLog.ProvisioningState
                                                }
                                                $FlowLogInfo += [PSCustomObject]$InObj
                                            }

                                            if ($Healthcheck.NetworkWatcher.FlowLogEnabled) {
                                                $FlowLogInfo | Where-Object { -not $_.$($LocalizedData.FlowLogEnabled) } | Set-Style -Style Warning -Property $LocalizedData.FlowLogEnabled
                                            }

                                            $TableParams = @{
                                                Name         = "$($LocalizedData.FlowLogsHeading) - $WatcherName"
                                                List         = $false
                                                ColumnWidths = 20, 20, 10, 10, 15, 15, 10
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $FlowLogInfo | Table @TableParams
                                        }
                                    }
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.Location, $LocalizedData.FlowLogs, $LocalizedData.ProvisioningState
                                ColumnWidths = 30, 25, 20, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzWatcherInfo | Table @TableParams
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
