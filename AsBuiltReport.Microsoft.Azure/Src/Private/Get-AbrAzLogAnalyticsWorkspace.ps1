function Get-AbrAzLogAnalyticsWorkspace {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Log Analytics Workspace information
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
        $LocalizedData = $reportTranslate.GetAbrAzLogAnalyticsWorkspace
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.LogAnalyticsWorkspace)
    }

    process {
        try {
            if ($InfoLevel.LogAnalyticsWorkspace -gt 0) {
                $AzLogAnalyticsWorkspaces = Get-AzOperationalInsightsWorkspace | Sort-Object Name
                if ($AzLogAnalyticsWorkspaces) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $AzLogAnalyticsWorkspaceInfo = @()
                        foreach ($AzLogAnalyticsWorkspace in $AzLogAnalyticsWorkspaces) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzLogAnalyticsWorkspace.Name
                                $LocalizedData.ResourceGroup = $AzLogAnalyticsWorkspace.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzLogAnalyticsWorkspace.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzLogAnalyticsWorkspace.ResourceId).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzLogAnalyticsWorkspace.ResourceId).split('/')[2]
                                $LocalizedData.WorkspaceID = $AzLogAnalyticsWorkspace.CustomerId
                                $LocalizedData.Sku = $AzLogAnalyticsWorkspace.Sku
                                $LocalizedData.RetentionDays = $AzLogAnalyticsWorkspace.RetentionInDays
                                $LocalizedData.DailyQuotaGB = if ($AzLogAnalyticsWorkspace.DailyQuotaGb) {
                                    "$($AzLogAnalyticsWorkspace.DailyQuotaGb) GB"
                                } else {
                                    $LocalizedData.NoQuota
                                }
                                $LocalizedData.ProvisioningState = $AzLogAnalyticsWorkspace.ProvisioningState
                                $LocalizedData.PublicNetworkAccessForIngestion = switch ($AzLogAnalyticsWorkspace.PublicNetworkAccessForIngestion) {
                                    'Enabled' { $LocalizedData.Enabled }
                                    'Disabled' { $LocalizedData.Disabled }
                                    default { $LocalizedData.Unknown }
                                }
                                $LocalizedData.PublicNetworkAccessForQuery = switch ($AzLogAnalyticsWorkspace.PublicNetworkAccessForQuery) {
                                    'Enabled' { $LocalizedData.Enabled }
                                    'Disabled' { $LocalizedData.Disabled }
                                    default { $LocalizedData.Unknown }
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzLogAnalyticsWorkspace.Tags)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzLogAnalyticsWorkspace.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzLogAnalyticsWorkspaceInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.LogAnalyticsWorkspace.ProvisioningState) {
                            $AzLogAnalyticsWorkspaceInfo | Where-Object { $_.($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($Healthcheck.LogAnalyticsWorkspace.PublicNetworkAccessForIngestion) {
                            $AzLogAnalyticsWorkspaceInfo | Where-Object { $_.($LocalizedData.PublicNetworkAccessForIngestion) -eq $LocalizedData.Enabled } | Set-Style -Style Warning -Property $LocalizedData.PublicNetworkAccessForIngestion
                        }

                        if ($Healthcheck.LogAnalyticsWorkspace.PublicNetworkAccessForQuery) {
                            $AzLogAnalyticsWorkspaceInfo | Where-Object { $_.($LocalizedData.PublicNetworkAccessForQuery) -eq $LocalizedData.Enabled } | Set-Style -Style Warning -Property $LocalizedData.PublicNetworkAccessForQuery
                        }

                        if ($InfoLevel.LogAnalyticsWorkspace -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine
                            foreach ($AzLogAnalyticsWorkspace in $AzLogAnalyticsWorkspaceInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $AzLogAnalyticsWorkspace.($LocalizedData.Name) {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzLogAnalyticsWorkspace.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzLogAnalyticsWorkspace | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Sku, $LocalizedData.RetentionDays
                                ColumnWidths = 25, 25, 20, 15, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzLogAnalyticsWorkspaceInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}
