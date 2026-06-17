function Get-AbrAzMaintenanceConfiguration {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Maintenance Configuration information
    .DESCRIPTION
        Documents the configuration of Azure Maintenance Configurations, including scope,
        maintenance window, recurrence, timezone, and visibility settings.
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
        $LocalizedData = $reportTranslate.GetAbrAzMaintenanceConfiguration
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.MaintenanceConfiguration)
    }

    process {
        try {
            if ($InfoLevel.MaintenanceConfiguration -ge 1) {
                $AzMaintenanceConfigs = Get-AzMaintenanceConfiguration -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzMaintenanceConfigs) {
                    Write-PScriboMessage $LocalizedData.Collecting

                    # PSMaintenanceConfiguration does not expose ResourceGroupName or ProvisioningState directly;
                    # fetch via Get-AzResource with expanded properties to populate both fields.
                    $AzMcResourceMap = @{}
                    $AzMcResources = Get-AzResource -ResourceType 'Microsoft.Maintenance/maintenanceConfigurations' -ExpandProperties -ErrorAction SilentlyContinue
                    foreach ($Res in $AzMcResources) {
                        $AzMcResourceMap[$Res.ResourceId.ToLower()] = $Res
                    }

                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzMcInfo = @()
                        foreach ($AzMc in $AzMaintenanceConfigs) {
                            $AzMcResource = $AzMcResourceMap[$AzMc.Id.ToLower()]
                            $ResourceGroup = ($AzMc.Id).split('/')[4]
                            $ProvisioningState = if ($AzMcResource) { $AzMcResource.Properties.ProvisioningState } else { $LocalizedData.None }
                            $StartDateTime = if ($AzMc.MaintenanceWindow.StartDateTime) {
                                $AzMc.MaintenanceWindow.StartDateTime
                            } else {
                                $LocalizedData.NotConfigured
                            }
                            $ExpirationDateTime = if ($AzMc.MaintenanceWindow.ExpirationDateTime) {
                                $AzMc.MaintenanceWindow.ExpirationDateTime
                            } else {
                                $LocalizedData.NoExpiry
                            }
                            $Duration = if ($AzMc.MaintenanceWindow.Duration) {
                                $AzMc.MaintenanceWindow.Duration
                            } else {
                                $LocalizedData.NotConfigured
                            }
                            $RecurEvery = if ($AzMc.MaintenanceWindow.RecurEvery) {
                                $AzMc.MaintenanceWindow.RecurEvery
                            } else {
                                $LocalizedData.NotConfigured
                            }
                            $TimeZone = if ($AzMc.MaintenanceWindow.TimeZone) {
                                $AzMc.MaintenanceWindow.TimeZone
                            } else {
                                $LocalizedData.NotConfigured
                            }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name              = $AzMc.Name
                                $LocalizedData.ResourceGroup     = $ResourceGroup
                                $LocalizedData.Location          = $AzLocationLookup."$($AzMc.Location)"
                                $LocalizedData.Subscription      = "$($AzSubscriptionLookup.(($AzMc.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID    = ($AzMc.Id).split('/')[2]
                                $LocalizedData.Scope             = $AzMc.MaintenanceScope
                                $LocalizedData.Visibility        = $AzMc.Visibility
                                $LocalizedData.StartDateTime     = $StartDateTime
                                $LocalizedData.ExpirationDateTime = $ExpirationDateTime
                                $LocalizedData.Duration          = $Duration
                                $LocalizedData.RecurEvery        = $RecurEvery
                                $LocalizedData.TimeZone          = $TimeZone
                                $LocalizedData.ProvisioningState = $ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzMc.Tag -or $AzMc.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzMc.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzMcInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.MaintenanceConfiguration.ProvisioningState) {
                            $AzMcInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.MaintenanceConfiguration -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzMcItem in $AzMcInfo) {
                                $McName = $AzMcItem.($LocalizedData.Name)
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $McName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $McName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzMcItem | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.Location, $LocalizedData.Scope, $LocalizedData.RecurEvery, $LocalizedData.Duration, $LocalizedData.ProvisioningState
                                ColumnWidths = 25, 15, 20, 15, 10, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzMcInfo | Table @TableParams
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
