function Get-AbrAzRouteTable {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Route Table and Routes information
    .DESCRIPTION

    .NOTES
        Version:        0.4.0
        Author:         Howard Hao & Tim Carman
        Twitter:        @tpcarman
        Github:         howardhaooooo / tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzRouteTable
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.RouteTable)
    }

    process {
        Try {
            if ($InfoLevel.RouteTable -gt 0) {
                $AzRouteTables = Get-AzRouteTable | Sort-Object Name
                if ($AzRouteTables) {
                    Write-PscriboMessage $LocalizedData.Collecting
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

                        if ($InfoLevel.RouteTable -ge 3) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine

                            foreach ($AzRouteTable in $AzRouteTables) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRouteTable.Name)" {
                                    $AzRouteTableInfo = @()
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $AzRouteTable.Name
                                        $LocalizedData.ResourceGroup = $AzRouteTable.ResourceGroupName
                                        $LocalizedData.Location = $AzLocationLookup."$($AzRouteTable.Location)"
                                        $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzRouteTable.Id).split('/')[2]))"
                                        $LocalizedData.SubscriptionID = ($AzRouteTable.Id).split('/')[2]
                                        $LocalizedData.ProvisioningState = $AzRouteTable.ProvisioningState
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzRouteTable.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    $InObj[$LocalizedData.Locks] = $(
                                        $rl = $LockMap[$AzRouteTable.Id.ToLower()]
                                        if ($rl) { ($rl | ForEach-Object { "$($_.Name) ($($_.Properties.Level))" }) -join [Environment]::NewLine }
                                        else { $LocalizedData.None }
                                    )

                                    if ($Options.ShowTags) {
                                        $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzRouteTable.Tag)) {
                                            '--'
                                        } else {
                                            ($AzRouteTable.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                        }
                                        $TableParams['Columns'] = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Subscription, $LocalizedData.Tags
                                    } else {
                                        $TableParams['Columns'] = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Subscription
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }

                                    $AzRouteTableInfo += [PSCustomObject]$InObj

                                    # Apply health check highlighting
                                    if ($Healthcheck.RouteTable.ProvisioningState) {
                                        $AzRouteTableInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                                    }

                                    $AzRouteTableInfo | Table @TableParams
                                }

                                $AzRoutes = $AzRouteTable.Routes | Sort-Object Name
                                if ($AzRoutes) {
                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Routes {
                                        $AzRouteInfo = @()
                                        foreach ($AzRoute in $AzRoutes){
                                            $InObj = [Ordered]@{
                                                $LocalizedData.Name = $AzRoute.Name
                                                $LocalizedData.AddressPrefix = $AzRoute.AddressPrefix
                                                $LocalizedData.NextHopType = $AzRoute.NextHopType
                                                $LocalizedData.NextHopIPAddress = $(if ($AzRoute.NextHopIpAddress) {
                                                    $AzRoute.NextHopIpAddress
                                                } else {
                                                    '--'
                                                })
                                            }
                                            $AzRouteInfo += [PSCustomObject]$InObj
                                        }
                                        $TableParams = @{
                                            Name = "$($LocalizedData.Routes) - $($AzRouteTable.($LocalizedData.Name))"
                                            List = $false
                                            ColumnWidths = 25, 25, 25, 25
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $AzRouteInfo | Table @TableParams
                                    }
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine

                            $AzRouteTableInfo = @()
                            foreach ($AzRouteTable in $AzRouteTables) {
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name = $AzRouteTable.Name
                                    $LocalizedData.ResourceGroup = $AzRouteTable.ResourceGroupName
                                    $LocalizedData.Location = $AzLocationLookup."$($AzRouteTable.Location)"
                                    $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzRouteTable.Id).split('/')[2]))"
                                    $LocalizedData.ProvisioningState = $AzRouteTable.ProvisioningState
                                }
                                $AzRouteTableInfo += [PSCustomObject]$InObj
                            }

                            # Apply health check highlighting
                            if ($Healthcheck.RouteTable.ProvisioningState) {
                                $AzRouteTableInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.Subscription
                                ColumnWidths = 25, 25, 25, 25
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }

                            $AzRouteTableInfo | Table @TableParams
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