function Get-AbrAzVmScaleSet {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Machine Scale Set information
    .DESCRIPTION
        Documents the configuration of Azure Virtual Machine Scale Sets, including SKU,
        orchestration mode, upgrade policy, zones, and instance count.
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
        $LocalizedData = $reportTranslate.GetAbrAzVmScaleSet
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.VmScaleSet)
    }

    process {
        try {
            if ($InfoLevel.VmScaleSet -ge 1) {
                $AzVmScaleSets = Get-AzVmss -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzVmScaleSets) {
                    Write-PScriboMessage $LocalizedData.Collecting

                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzVmssInfo = @()
                        foreach ($AzVmss in $AzVmScaleSets) {
                            $Zones = if ($AzVmss.Zones -and $AzVmss.Zones.Count -gt 0) {
                                $AzVmss.Zones -join ', '
                            } else {
                                $LocalizedData.None
                            }
                            $Identity = if ($AzVmss.Identity) {
                                $AzVmss.Identity.Type
                            } else {
                                $LocalizedData.None
                            }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name                 = $AzVmss.Name
                                $LocalizedData.ResourceGroup        = $AzVmss.ResourceGroupName
                                $LocalizedData.Location             = $AzLocationLookup."$($AzVmss.Location)"
                                $LocalizedData.Subscription         = "$($AzSubscriptionLookup.(($AzVmss.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID       = ($AzVmss.Id).split('/')[2]
                                $LocalizedData.VmSize               = $AzVmss.Sku.Name
                                $LocalizedData.Instances            = $AzVmss.Sku.Capacity
                                $LocalizedData.OrchestrationMode    = $AzVmss.OrchestrationMode
                                $LocalizedData.UpgradePolicy        = $AzVmss.UpgradePolicy.Mode
                                $LocalizedData.Overprovision        = $AzVmss.Overprovision
                                $LocalizedData.SinglePlacementGroup = $AzVmss.SinglePlacementGroup
                                $LocalizedData.Zones                = $Zones
                                $LocalizedData.Identity             = $Identity
                                $LocalizedData.ProvisioningState    = $AzVmss.ProvisioningState
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzVmss.Tags -or $AzVmss.Tags.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzVmss.Tags.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzVmssInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.VmScaleSet.ProvisioningState) {
                            $AzVmssInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.VmScaleSet -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzVmssItem in $AzVmssInfo) {
                                $VmssName = $AzVmssItem.($LocalizedData.Name)
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $VmssName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $VmssName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzVmssItem | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.Location, $LocalizedData.VmSize, $LocalizedData.Instances, $LocalizedData.UpgradePolicy, $LocalizedData.ProvisioningState
                                ColumnWidths = 25, 20, 25, 10, 10, 10
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzVmssInfo | Table @TableParams
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
