function Get-AbrAzDataCollectionRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Data Collection Rule information
    .DESCRIPTION
        Documents the configuration of Azure Data Collection Rules including data sources,
        Log Analytics destinations, and data flows.
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
        $LocalizedData = $reportTranslate.GetAbrAzDataCollectionRule
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.DataCollectionRule)
    }

    process {
        try {
            if ($InfoLevel.DataCollectionRule -ge 1) {
                $AzDcrs = Get-AzDataCollectionRule -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzDcrs) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzDcrInfo = @()
                        foreach ($AzDcr in $AzDcrs) {
                            $DataSourceTypes = @()
                            if ($AzDcr.DataSourcePerformanceCounter) { $DataSourceTypes += $LocalizedData.PerformanceCounters }
                            if ($AzDcr.DataSourceWindowsEventLog)    { $DataSourceTypes += $LocalizedData.WindowsEventLogs }
                            if ($AzDcr.DataSourceSyslog)             { $DataSourceTypes += $LocalizedData.Syslog }
                            if ($AzDcr.DataSourceExtension)          { $DataSourceTypes += $LocalizedData.Extensions }
                            if ($AzDcr.DataSourceLogFile)            { $DataSourceTypes += $LocalizedData.LogFiles }
                            $DataSourceSummary = if ($DataSourceTypes) { $DataSourceTypes -join ', ' } else { $LocalizedData.None }

                            $DestinationCount = if ($AzDcr.DestinationLogAnalytic) { $AzDcr.DestinationLogAnalytic.Count } else { 0 }

                            $InObj = [Ordered]@{
                                $LocalizedData.Name                       = $AzDcr.Name
                                $LocalizedData.ResourceGroup              = $AzDcr.ResourceGroupName
                                $LocalizedData.Location                   = $AzLocationLookup."$($AzDcr.Location)"
                                $LocalizedData.Subscription               = "$($AzSubscriptionLookup.(($AzDcr.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID             = ($AzDcr.Id).split('/')[2]
                                $LocalizedData.Description                = if ($AzDcr.Description) { $AzDcr.Description } else { $LocalizedData.None }
                                $LocalizedData.DataSources                = $DataSourceSummary
                                $LocalizedData.LogAnalyticsDestinations   = $DestinationCount
                                $LocalizedData.ProvisioningState          = $AzDcr.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzDcr.Tag -or $AzDcr.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzDcr.Tag.Keys | ForEach-Object { "$_`:`t$($AzDcr.Tag[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzDcrInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.DataCollectionRule.ProvisioningState) {
                            $AzDcrInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.DataCollectionRule -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzDcrItem in $AzDcrInfo) {
                                $DcrName = $AzDcrItem.($LocalizedData.Name)
                                $DcrRg   = $AzDcrItem.($LocalizedData.ResourceGroup)
                                $FullDcr = $AzDcrs | Where-Object { $_.Name -eq $DcrName -and $_.ResourceGroupName -eq $DcrRg }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $DcrName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $DcrName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzDcrItem | Table @TableParams

                                    if ($FullDcr.DestinationLogAnalytic) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Destinations {
                                            $DestInfo = @()
                                            foreach ($Dest in $FullDcr.DestinationLogAnalytic) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.DestinationName = $Dest.Name
                                                    $LocalizedData.WorkspaceId     = $Dest.WorkspaceResourceId
                                                }
                                                $DestInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.Destinations) - $DcrName"
                                                List         = $false
                                                ColumnWidths = 35, 65
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $DestInfo | Table @TableParams
                                        }
                                    }

                                    if ($FullDcr.DataFlow) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.DataFlows {
                                            $FlowInfo = @()
                                            foreach ($Flow in $FullDcr.DataFlow) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.Streams      = ($Flow.Stream -join ', ')
                                                    $LocalizedData.Destinations = ($Flow.Destination -join ', ')
                                                }
                                                $FlowInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.DataFlows) - $DcrName"
                                                List         = $false
                                                ColumnWidths = 55, 45
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $FlowInfo | Table @TableParams
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
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.LogAnalyticsDestinations, $LocalizedData.ProvisioningState
                                ColumnWidths = 25, 20, 15, 25, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzDcrInfo | Table @TableParams
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
