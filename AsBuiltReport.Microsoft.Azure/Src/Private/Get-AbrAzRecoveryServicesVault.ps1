function Get-AbrAzRecoveryServicesVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Recovery Services Vault information
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
        $LocalizedData = $reportTranslate.GetAbrAzRecoveryServicesVault
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.RecoveryServicesVault)
    }

    process {
        Try {
            if ($InfoLevel.RecoveryServicesVault -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    Write-PscriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $AzRsvInfo = @()
                        foreach ($AzRsv in $AzRsvs) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzRsv.Name
                                $LocalizedData.ResourceGroup = $AzRsv.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzRsv.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzRsv.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzRsv.Id).split('/')[2]
                                $LocalizedData.ProvisioningState = $AzRsv.Properties.ProvisioningState
                                $LocalizedData.PrivateEndpointStateForBackup = Switch ($AzRsv.Properties.PrivateEndpointStateForBackup) {
                                    $null { $LocalizedData.None }
                                    default { $AzRsv.Properties.PrivateEndpointStateForBackup }
                                }
                                $LocalizedData.PrivateEndpointStateForSiteRecovery = Switch ($AzRsv.Properties.PrivateEndpointStateForSiteRecovery) {
                                    $null { $LocalizedData.None }
                                    default { $AzRsv.Properties.PrivateEndpointStateForSiteRecovery }
                                }
                            }
                            $AzRsvInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.RecoveryServicesVault.ProvisioningState) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.RecoveryServicesVault.PrivateEndpointStateForBackup) {
                            $AzRsvInfo | Where-Object { $_.$($LocalizedData.PrivateEndpointStateForBackup) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.PrivateEndpointStateForBackup
                        }

                        if ($InfoLevel.RecoveryServicesVault -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzRsv in $AzRsvInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRsv.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.Heading) - $($AzRsv.($LocalizedData.Name))"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRsv | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location
                                ColumnWidths = 33, 34, 33
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzRsvinfo | Table @TableParams
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}