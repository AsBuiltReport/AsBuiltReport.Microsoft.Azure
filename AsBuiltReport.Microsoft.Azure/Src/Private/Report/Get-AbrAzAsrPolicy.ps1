function Get-AbrAzAsrPolicy {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Site Recovery Replication Policy information
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        $LocalizedData = $reportTranslate.GetAbrAzAsrPolicy
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.AsrPolicy)
    }

    process {
        Try {
            if ($InfoLevel.AsrPolicy -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    foreach ($AzRsv in $AzRsvs) {
                        $null = Set-AzRecoveryServicesAsrVaultContext -Vault $AzRsv -ErrorAction SilentlyContinue
                        $AsrPolicies = Get-AzRecoveryServicesAsrPolicy -ErrorAction SilentlyContinue | Sort-Object Name
                        if ($AsrPolicies) {
                            Write-PScriboMessage ($LocalizedData.Collecting -f $AzRsv.Name)
                            Section -Style Heading4 "$($LocalizedData.Heading) - $($AzRsv.Name)" {
                                if ($Options.ShowSectionInfo) {
                                    Paragraph $LocalizedData.SectionInfo
                                    BlankLine
                                }
                                $PolicyInfo = @()
                                foreach ($Policy in $AsrPolicies) {
                                    $ProvSettings = $Policy.ReplicationProviderSettings
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name                   = $Policy.Name
                                        $LocalizedData.Provider               = $Policy.ReplicationProvider
                                        $LocalizedData.RpoThreshold           = $(
                                            if ($null -ne $ProvSettings.RecoveryPointThresholdInMinutes) { $ProvSettings.RecoveryPointThresholdInMinutes }
                                            else { $LocalizedData.NotApplicable }
                                        )
                                        $LocalizedData.RecoveryPointHistory   = $(
                                            if ($null -ne $ProvSettings.RecoveryPointHistory) { $ProvSettings.RecoveryPointHistory }
                                            elseif ($null -ne $ProvSettings.RecoveryPointHistoryDurationInHours) { $ProvSettings.RecoveryPointHistoryDurationInHours }
                                            else { $LocalizedData.NotApplicable }
                                        )
                                        $LocalizedData.AppConsistentFrequency = $(
                                            if ($null -ne $ProvSettings.AppConsistentFrequencyInMinutes) { $ProvSettings.AppConsistentFrequencyInMinutes }
                                            elseif ($null -ne $ProvSettings.ApplicationConsistentSnapshotFrequencyInHours) { $ProvSettings.ApplicationConsistentSnapshotFrequencyInHours * 60 }
                                            else { $LocalizedData.NotApplicable }
                                        )
                                        $LocalizedData.CrashConsistentFrequency = $(
                                            if ($null -ne $ProvSettings.CrashConsistentFrequencyInMinutes) { $ProvSettings.CrashConsistentFrequencyInMinutes }
                                            else { $LocalizedData.NotApplicable }
                                        )
                                        $LocalizedData.MultiVmSync            = Switch ($ProvSettings.MultiVmSyncStatus) {
                                            $null   { $LocalizedData.NotApplicable }
                                            default { $ProvSettings.MultiVmSyncStatus }
                                        }
                                    }
                                    $PolicyInfo += [PSCustomObject]$InObj
                                }

                                if ($Healthcheck.AsrPolicy.AppConsistentSnapshot) {
                                    $PolicyInfo | Where-Object {
                                        $_.$($LocalizedData.AppConsistentFrequency) -eq '0' -or
                                        $_.$($LocalizedData.AppConsistentFrequency) -eq $LocalizedData.NotApplicable
                                    } | Set-Style -Style Warning -Property $LocalizedData.AppConsistentFrequency
                                }

                                if ($InfoLevel.AsrPolicy -ge 2) {
                                    Paragraph ($LocalizedData.ParagraphDetail -f $AzRsv.Name)
                                    foreach ($Policy in $PolicyInfo) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Policy.($LocalizedData.Name))" {
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.Heading) - $($Policy.($LocalizedData.Name))"
                                                List         = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $Policy | Table @TableParams
                                        }
                                    }
                                } else {
                                    Paragraph ($LocalizedData.ParagraphSummary -f $AzRsv.Name)
                                    BlankLine
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeadings) - $($AzRsv.Name)"
                                        List         = $false
                                        Columns      = $LocalizedData.Name, $LocalizedData.Provider, $LocalizedData.RpoThreshold, $LocalizedData.RecoveryPointHistory, $LocalizedData.AppConsistentFrequency
                                        ColumnWidths = 26, 20, 18, 18, 18
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $PolicyInfo | Table @TableParams
                                }
                            }
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
