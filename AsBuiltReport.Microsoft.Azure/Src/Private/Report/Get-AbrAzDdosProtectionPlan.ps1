function Get-AbrAzDdosProtectionPlan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure DDoS Protection Plan information
    .DESCRIPTION
        Documents the configuration of Azure DDoS Protection Plans including protected
        virtual networks and provisioning state.
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
        $LocalizedData = $reportTranslate.GetAbrAzDdosProtectionPlan
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.DdosProtectionPlan)
    }

    process {
        try {
            if ($InfoLevel.DdosProtectionPlan -ge 1) {
                $AzDdosPlans = Get-AzDdosProtectionPlan -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzDdosPlans) {
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

                        $AzDdosPlanInfo = @()
                        foreach ($AzDdosPlan in $AzDdosPlans) {
                            $ProtectedVNetCount = if ($AzDdosPlan.VirtualNetworks) { $AzDdosPlan.VirtualNetworks.Count } else { 0 }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name                     = $AzDdosPlan.Name
                                $LocalizedData.ResourceGroup            = $AzDdosPlan.ResourceGroupName
                                $LocalizedData.Location                 = $AzLocationLookup."$($AzDdosPlan.Location)"
                                $LocalizedData.Subscription             = "$($AzSubscriptionLookup.(($AzDdosPlan.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID           = ($AzDdosPlan.Id).split('/')[2]
                                $LocalizedData.ProtectedVirtualNetworks = $ProtectedVNetCount
                                $LocalizedData.ProvisioningState        = $AzDdosPlan.ProvisioningState
                            }

                            $InObj[$LocalizedData.Locks] = $(
                                $rl = $LockMap[$AzDdosPlan.Id.ToLower()]
                                if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                else { $LocalizedData.None }
                            )

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzDdosPlan.Tags -or $AzDdosPlan.Tags.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzDdosPlan.Tags.Keys | ForEach-Object { "$_`:`t$($AzDdosPlan.Tags[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzDdosPlanInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.DdosProtectionPlan.ProvisioningState) {
                            $AzDdosPlanInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.DdosProtectionPlan -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzDdosPlan in $AzDdosPlanInfo) {
                                $PlanName = $AzDdosPlan.($LocalizedData.Name)
                                $PlanRg   = $AzDdosPlan.($LocalizedData.ResourceGroup)
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $PlanName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $PlanName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzDdosPlan | Table @TableParams

                                    $FullPlan = $AzDdosPlans | Where-Object { $_.Name -eq $PlanName -and $_.ResourceGroupName -eq $PlanRg }
                                    if ($FullPlan -and $FullPlan.VirtualNetworks) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ProtectedVirtualNetworks {
                                            $VNetInfo = @()
                                            foreach ($VNet in $FullPlan.VirtualNetworks) {
                                                $VNetIdParts = $VNet.Id.split('/')
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.VirtualNetworkName = $VNetIdParts[-1]
                                                    $LocalizedData.ResourceGroup      = $VNetIdParts[4]
                                                    $LocalizedData.Subscription       = "$($AzSubscriptionLookup.($VNetIdParts[2]))"
                                                }
                                                $VNetInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.ProtectedVirtualNetworks) - $PlanName"
                                                List         = $false
                                                ColumnWidths = 40, 35, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $VNetInfo | Table @TableParams
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
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.ProtectedVirtualNetworks, $LocalizedData.ProvisioningState
                                ColumnWidths = 25, 20, 15, 20, 20
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzDdosPlanInfo | Table @TableParams
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
