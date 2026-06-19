function Get-AbrAzDiagnosticSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Diagnostic Setting information
    .DESCRIPTION
        Documents the configuration of Azure Diagnostic Settings across resources, including
        Log Analytics workspace, storage account, and Event Hub destinations.
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
        $LocalizedData = $reportTranslate.GetAbrAzDiagnosticSetting
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.DiagnosticSetting)
    }

    process {
        try {
            if ($InfoLevel.DiagnosticSetting -ge 1) {
                Write-PScriboMessage $LocalizedData.Collecting
                $AzResources = Get-AzResource -ErrorAction SilentlyContinue | Sort-Object Name

                $DiagSettingsData = @()
                foreach ($Resource in $AzResources) {
                    $Settings = Get-AzDiagnosticSetting -ResourceId $Resource.ResourceId -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
                    foreach ($Setting in $Settings) {
                        $EnabledLogCount = ($Setting.Log | Where-Object { $_.Enabled }).Count
                        $MetricsEnabled  = ($Setting.Metric | Where-Object { $_.Enabled }).Count -gt 0

                        $WorkspaceName = if ($Setting.WorkspaceId) {
                            ($Setting.WorkspaceId).split('/')[-1]
                        } else {
                            $LocalizedData.None
                        }

                        $StorageAccountName = if ($Setting.StorageAccountId) {
                            ($Setting.StorageAccountId).split('/')[-1]
                        } else {
                            $LocalizedData.None
                        }

                        $EventHubName = if ($Setting.EventHubAuthorizationRuleId) {
                            ($Setting.EventHubAuthorizationRuleId).split('/')[-3]
                        } else {
                            $LocalizedData.None
                        }

                        $InObj = [Ordered]@{
                            $LocalizedData.ResourceName          = $Resource.Name
                            $LocalizedData.ResourceType          = $Resource.ResourceType
                            $LocalizedData.ResourceGroup         = $Resource.ResourceGroupName
                            $LocalizedData.Name                  = $Setting.Name
                            $LocalizedData.LogAnalyticsWorkspace = $WorkspaceName
                            $LocalizedData.StorageAccount        = $StorageAccountName
                            $LocalizedData.EventHub              = $EventHubName
                            $LocalizedData.LogCategoriesEnabled  = $EnabledLogCount
                            $LocalizedData.MetricsEnabled        = if ($MetricsEnabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                        }

                        $DiagSettingsData += [PSCustomObject]$InObj
                    }
                }

                if ($DiagSettingsData) {
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        if ($Healthcheck.DiagnosticSetting.NoLogsEnabled) {
                            $DiagSettingsData | Where-Object { $_.$($LocalizedData.LogCategoriesEnabled) -eq 0 } | Set-Style -Style Warning -Property $LocalizedData.LogCategoriesEnabled
                        }

                        if ($InfoLevel.DiagnosticSetting -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine
                            foreach ($DiagSetting in $DiagSettingsData) {
                                $SectionTitle = "$($DiagSetting.($LocalizedData.ResourceName)) - $($DiagSetting.($LocalizedData.Name))"
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $SectionTitle {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $SectionTitle"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $DiagSetting | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.ResourceName, $LocalizedData.ResourceGroup, $LocalizedData.Name, $LocalizedData.LogCategoriesEnabled, $LocalizedData.MetricsEnabled
                                ColumnWidths = 25, 20, 25, 15, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $DiagSettingsData | Table @TableParams
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
