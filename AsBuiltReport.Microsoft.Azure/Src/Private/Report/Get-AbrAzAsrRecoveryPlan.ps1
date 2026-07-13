function Get-AbrAzAsrRecoveryPlan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Site Recovery Recovery Plan information
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
        $LocalizedData = $reportTranslate.GetAbrAzAsrRecoveryPlan
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.AsrRecoveryPlan)
    }

    process {
        Try {
            if ($InfoLevel.AsrRecoveryPlan -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    foreach ($AzRsv in $AzRsvs) {
                        $null = Set-AzRecoveryServicesAsrVaultContext -Vault $AzRsv -ErrorAction SilentlyContinue
                        $AsrRecoveryPlans = Get-AzRecoveryServicesAsrRecoveryPlan -ErrorAction SilentlyContinue | Sort-Object Name
                        if ($AsrRecoveryPlans) {
                            Write-PScriboMessage ($LocalizedData.Collecting -f $AzRsv.Name)
                            Section -Style Heading4 "$($LocalizedData.Heading) - $($AzRsv.Name)" {
                                if ($Options.ShowSectionInfo) {
                                    Paragraph $LocalizedData.SectionInfo
                                    BlankLine
                                }
                                $PlanInfo = @()
                                foreach ($Plan in $AsrRecoveryPlans) {
                                    $ProtectedItemCount = ($Plan.Groups | ForEach-Object { $_.ReplicationProtectedItems } | Measure-Object).Count
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name                    = $Plan.Name
                                        $LocalizedData.PrimaryFabric           = $Plan.PrimaryFabricFriendlyName
                                        $LocalizedData.RecoveryFabric          = $Plan.RecoveryFabricFriendlyName
                                        $LocalizedData.GroupCount              = ($Plan.Groups | Measure-Object).Count
                                        $LocalizedData.ProtectedItemCount      = $ProtectedItemCount
                                        $LocalizedData.FailoverDeploymentModel = Switch ($Plan.FailoverDeploymentModel) {
                                            $null   { $LocalizedData.None }
                                            default { $Plan.FailoverDeploymentModel }
                                        }
                                    }
                                    $PlanInfo += [PSCustomObject]$InObj
                                }

                                if ($InfoLevel.AsrRecoveryPlan -ge 2) {
                                    Paragraph ($LocalizedData.ParagraphDetail -f $AzRsv.Name)
                                    foreach ($Plan in $PlanInfo) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Plan.($LocalizedData.Name))" {
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.Heading) - $($Plan.($LocalizedData.Name))"
                                                List         = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $Plan | Table @TableParams
                                        }
                                    }
                                } else {
                                    Paragraph ($LocalizedData.ParagraphSummary -f $AzRsv.Name)
                                    BlankLine
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeadings) - $($AzRsv.Name)"
                                        List         = $false
                                        Columns      = $LocalizedData.Name, $LocalizedData.PrimaryFabric, $LocalizedData.RecoveryFabric, $LocalizedData.GroupCount, $LocalizedData.ProtectedItemCount
                                        ColumnWidths = 30, 20, 20, 15, 15
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $PlanInfo | Table @TableParams
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
