function Get-AbrAzVirtualWan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual WAN information
    .DESCRIPTION
        Documents the configuration of Azure Virtual WANs including type, branch-to-branch
        traffic and provisioning state, along with their virtual hubs.
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
        $LocalizedData = $reportTranslate.GetAbrAzVirtualWan
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.VirtualWan)
    }

    process {
        try {
            if ($InfoLevel.VirtualWan -ge 1) {
                $AzVirtualWans = Get-AzVirtualWan -ErrorAction Stop | Sort-Object Name
                # Azure Route Server is also a virtual hub resource, but it has no parent Virtual WAN
                $AzVirtualHubs = Get-AzVirtualHub -ErrorAction Stop | Where-Object { $_.VirtualWan.Id } | Sort-Object Name

                if ($AzVirtualWans -or $AzVirtualHubs) {
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

                        $AzVirtualWanInfo = @()
                        foreach ($AzVirtualWan in $AzVirtualWans) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name                  = $AzVirtualWan.Name
                                $LocalizedData.ResourceGroup         = $AzVirtualWan.ResourceGroupName
                                $LocalizedData.Location              = if ($AzLocationLookup."$($AzVirtualWan.Location)") { $AzLocationLookup."$($AzVirtualWan.Location)" } else { $AzVirtualWan.Location }
                                $LocalizedData.Subscription          = "$($AzSubscriptionLookup.(($AzVirtualWan.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID        = ($AzVirtualWan.Id).split('/')[2]
                                $LocalizedData.VirtualWanType        = $AzVirtualWan.VirtualWANType
                                $LocalizedData.BranchToBranchTraffic = if ($AzVirtualWan.AllowBranchToBranchTraffic) { $LocalizedData.Enabled } else { $LocalizedData.Disabled }
                                $LocalizedData.VirtualHubs           = @($AzVirtualHubs | Where-Object { $_.VirtualWan.Id -eq $AzVirtualWan.Id }).Count
                                $LocalizedData.ProvisioningState     = $AzVirtualWan.ProvisioningState
                            }

                            $InObj[$LocalizedData.Locks] = $(
                                $rl = $LockMap[$AzVirtualWan.Id.ToLower()]
                                if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                else { $LocalizedData.None }
                            )

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzVirtualWan.Tag -or $AzVirtualWan.Tag.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzVirtualWan.Tag.Keys | ForEach-Object { "$_`:`t$($AzVirtualWan.Tag[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzVirtualWanInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.VirtualWan.ProvisioningState) {
                            $AzVirtualWanInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($AzVirtualWanInfo) {
                            if ($InfoLevel.VirtualWan -ge 2) {
                                Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                                foreach ($AzVirtualWan in $AzVirtualWanInfo) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzVirtualWan.($LocalizedData.Name))" {
                                        $TableParams = @{
                                            Name         = "$($LocalizedData.TableHeading) - $($AzVirtualWan.($LocalizedData.Name))"
                                            List         = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $AzVirtualWan | Table @TableParams
                                    }
                                }
                            } else {
                                Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                                BlankLine
                                $TableParams = @{
                                    Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                    List         = $false
                                    Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.VirtualWanType, $LocalizedData.VirtualHubs, $LocalizedData.ProvisioningState
                                    ColumnWidths = 25, 20, 15, 15, 10, 15
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzVirtualWanInfo | Table @TableParams
                            }
                        }

                        if ($AzVirtualHubs) {
                            Get-AbrAzVirtualHub -VirtualHub $AzVirtualHubs
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
