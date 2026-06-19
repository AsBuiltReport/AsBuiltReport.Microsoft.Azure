function Get-AbrAzPrivateDnsZone {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Private DNS Zone information
    .DESCRIPTION
        Documents the configuration of Azure Private DNS Zones including record set counts,
        virtual network links, and provisioning state.
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
        $LocalizedData = $reportTranslate.GetAbrAzPrivateDnsZone
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.PrivateDnsZone)
    }

    process {
        try {
            if ($InfoLevel.PrivateDnsZone -ge 1) {
                $AzPrivateDnsZones = Get-AzResource -ResourceType 'Microsoft.Network/privateDnsZones' -ExpandProperties -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzPrivateDnsZones) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        # Pre-collect VNet links per zone for InfoLevel 2 detail.
                        # Key is "ResourceGroup/ZoneName" to handle the same zone name in multiple resource groups.
                        $VNetLinksMap = @{}
                        if ($InfoLevel.PrivateDnsZone -ge 2) {
                            foreach ($AzPrivateDnsZone in $AzPrivateDnsZones) {
                                $VNetLinksMap["$($AzPrivateDnsZone.ResourceGroupName)/$($AzPrivateDnsZone.Name)"] = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $AzPrivateDnsZone.ResourceGroupName -ZoneName $AzPrivateDnsZone.Name -ErrorAction SilentlyContinue
                            }
                        }

                        $LockMap = @{}
                        $AllLocks = Get-AzResourceLock -ErrorAction SilentlyContinue
                        foreach ($Lock in $AllLocks) {
                            $Key = $Lock.ResourceId.ToLower()
                            if (-not $LockMap.ContainsKey($Key)) { $LockMap[$Key] = @() }
                            $LockMap[$Key] += $Lock
                        }

                        $AzPrivateDnsZoneInfo = @()
                        foreach ($AzPrivateDnsZone in $AzPrivateDnsZones) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name                      = $AzPrivateDnsZone.Name
                                $LocalizedData.ResourceGroup             = $AzPrivateDnsZone.ResourceGroupName
                                $LocalizedData.Location                  = if ($AzLocationLookup."$($AzPrivateDnsZone.Location)") { $AzLocationLookup."$($AzPrivateDnsZone.Location)" } else { $AzPrivateDnsZone.Location }
                                $LocalizedData.Subscription              = "$($AzSubscriptionLookup.(($AzPrivateDnsZone.ResourceId).split('/')[2]))"
                                $LocalizedData.SubscriptionID            = ($AzPrivateDnsZone.ResourceId).split('/')[2]
                                $LocalizedData.RecordSets                = $AzPrivateDnsZone.Properties.NumberOfRecordSets
                                $LocalizedData.MaxRecordSets             = $AzPrivateDnsZone.Properties.MaxNumberOfRecordSets
                                $LocalizedData.VirtualNetworkLinks       = $AzPrivateDnsZone.Properties.NumberOfVirtualNetworkLinks
                                $LocalizedData.VNetLinksWithRegistration = $AzPrivateDnsZone.Properties.NumberOfVirtualNetworkLinksWithRegistration
                                $LocalizedData.ProvisioningState         = $AzPrivateDnsZone.Properties.ProvisioningState
                            }

                            $InObj[$LocalizedData.Locks] = $(
                                $rl = $LockMap[$AzPrivateDnsZone.ResourceId.ToLower()]
                                if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                else { $LocalizedData.None }
                            )

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzPrivateDnsZone.Tags -or $AzPrivateDnsZone.Tags.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzPrivateDnsZone.Tags.Keys | ForEach-Object { "$_`:`t$($AzPrivateDnsZone.Tags[$_])" }) -join [Environment]::NewLine
                                }
                            }

                            $AzPrivateDnsZoneInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.PrivateDnsZone.ProvisioningState) {
                            $AzPrivateDnsZoneInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }
                        if ($Healthcheck.PrivateDnsZone.VirtualNetworkLinks) {
                            $AzPrivateDnsZoneInfo | Where-Object { [int]$_.$($LocalizedData.VirtualNetworkLinks) -eq 0 } | Set-Style -Style Warning -Property $LocalizedData.VirtualNetworkLinks
                        }

                        if ($InfoLevel.PrivateDnsZone -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzPrivateDnsZone in $AzPrivateDnsZoneInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzPrivateDnsZone.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $($AzPrivateDnsZone.($LocalizedData.Name))"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzPrivateDnsZone | Table @TableParams

                                    $AzZoneName = $AzPrivateDnsZone.($LocalizedData.Name)
                                    $AzZoneRg   = $AzPrivateDnsZone.($LocalizedData.ResourceGroup)
                                    $VNetLinks = $VNetLinksMap["$AzZoneRg/$AzZoneName"]
                                    if ($VNetLinks) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.VirtualNetworkLinks {
                                            $VNetLinkInfo = @()
                                            foreach ($VNetLink in $VNetLinks) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.LinkName                = $VNetLink.Name
                                                    $LocalizedData.VirtualNetwork          = ($VNetLink.VirtualNetworkId).split('/')[-1]
                                                    $LocalizedData.AutoRegistration        = $VNetLink.RegistrationEnabled
                                                    $LocalizedData.VirtualNetworkLinkState = $VNetLink.VirtualNetworkLinkState
                                                    $LocalizedData.ProvisioningState       = $VNetLink.ProvisioningState
                                                }
                                                $VNetLinkInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.VirtualNetworkLinks) - $($AzZoneName)"
                                                List         = $false
                                                ColumnWidths = 30, 25, 15, 15, 15
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $VNetLinkInfo | Table @TableParams
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
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.RecordSets, $LocalizedData.VirtualNetworkLinks, $LocalizedData.ProvisioningState
                                ColumnWidths = 25, 20, 15, 15, 10, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzPrivateDnsZoneInfo | Table @TableParams
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
