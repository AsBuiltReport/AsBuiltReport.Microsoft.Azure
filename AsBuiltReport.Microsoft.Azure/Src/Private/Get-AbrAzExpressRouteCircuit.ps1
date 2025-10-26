function Get-AbrAzExpressRouteCircuit {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure ExpressRoute Circuit information
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
        $LocalizedData = $reportTranslate.GetAbrAzExpressRouteCircuit
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.ExpressRoute)
    }

    process {
        Try {
            if ($InfoLevel.ExpressRoute -gt 0) {
                $AzExpressRouteCircuits = Get-AzExpressRouteCircuit | Sort-Object Name
                if ($AzExpressRouteCircuits) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $AzExpressRouteCircuitInfo = @()
                        foreach ($AzExpressRouteCircuit in $AzExpressRouteCircuits) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzExpressRouteCircuit.Name
                                $LocalizedData.ResourceGroup = $AzExpressRouteCircuit.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzExpressRouteCircuit.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzExpressRouteCircuit.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzExpressRouteCircuit.Id).split('/')[2]
                                $LocalizedData.CircuitStatus = $AzExpressRouteCircuit.CircuitProvisioningState
                                $LocalizedData.Provider = $AzExpressRouteCircuit.ServiceProviderProperties.ServiceProviderName
                                $LocalizedData.ProviderStatus = $AzExpressRouteCircuit.ServiceProviderProvisioningState
                                $LocalizedData.PeeringLocation = $AzExpressRouteCircuit.ServiceProviderProperties.PeeringLocation
                                $LocalizedData.Bandwidth = "$($AzExpressRouteCircuit.ServiceProviderProperties.BandwidthInMbps) Mbps"
                                $LocalizedData.ServiceKey = $AzExpressRouteCircuit.ServiceKey
                                $LocalizedData.SKU = $AzExpressRouteCircuit.Sku.Tier
                                $LocalizedData.BillingModel = Switch ($AzExpressRouteCircuit.Sku.Family) {
                                    'MeteredData' { $LocalizedData.MeteredData }
                                    default { $AzExpressRouteCircuit.Sku.Family }
                                }
                                $LocalizedData.AllowClassicOperations = if ($AzExpressRouteCircuit.AllowClassicOperations) {
                                    $LocalizedData.On
                                } else {
                                    $LocalizedData.Off
                                }
                                ##ToDo: Peerings
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzExpressRouteCircuit.Tags)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzExpressRouteCircuit.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzExpressRouteCircuitInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.ExpressRoute.CircuitStatus) {
                            $AzExpressRouteCircuitInfo | Where-Object { $_.($LocalizedData.CircuitStatus) -ne 'Enabled' } | Set-Style -Style Critical -Property $LocalizedData.CircuitStatus
                        }
                        if ($InfoLevel.ExpressRoute -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine
                            foreach ($AzExpressRouteCircuit in $AzExpressRouteCircuitInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $AzExpressRouteCircuit.Name {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzExpressRouteCircuit.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzExpressRouteCircuit | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.CircuitStatus
                                ColumnWidths = 25, 25, 25, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzExpressRouteCircuitInfo | Table @TableParams
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