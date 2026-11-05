function Get-AbrAzVnmIpamPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Manager IPAM pool information
    .DESCRIPTION
        Documents the IP address management (IPAM) pools of an Azure Virtual Network Manager and the static CIDR allocations of each pool, in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $NetworkManagerName,

        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ResourceGroupName
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVnmIpamPool
    }

    process {
        Try {
            $AzIpamPools = Get-AzNetworkManagerIpamPool -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name
            if ($AzIpamPools) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $NetworkManagerName)

                # Collect static CIDRs once per pool so the summary count and the allocation detail use the same data.
                # The map is keyed on the pool being queried because the cmdlet leaves PoolName empty when listing.
                $StaticCidrMap = @{}
                foreach ($AzIpamPool in $AzIpamPools) {
                    Try {
                        $StaticCidrMap[$AzIpamPool.Name] = @(Get-AzNetworkManagerIpamPoolStaticCidr -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -IpamPoolName $AzIpamPool.Name -ErrorAction Stop | Sort-Object Name)
                    } Catch {
                        Write-PScriboMessage -IsWarning ($LocalizedData.StaticCidrError -f $AzIpamPool.Name, $_.Exception.Message)
                        $StaticCidrMap[$AzIpamPool.Name] = $null
                    }
                }

                $AzIpamPoolInfo = foreach ($AzIpamPool in $AzIpamPools) {
                    [PSCustomObject]@{
                        $LocalizedData.Name = $AzIpamPool.Name
                        $LocalizedData.Location = $(if ($AzLocationLookup."$($AzIpamPool.Location)") {
                            $AzLocationLookup."$($AzIpamPool.Location)"
                        } else {
                            $AzIpamPool.Location
                        })
                        $LocalizedData.AddressPrefixes = $(if ($AzIpamPool.Properties.AddressPrefixes) {
                            $AzIpamPool.Properties.AddressPrefixes -join [Environment]::NewLine
                        } else {
                            $LocalizedData.None
                        })
                        $LocalizedData.ParentPool = $(if ($AzIpamPool.Properties.ParentPoolName) {
                            $AzIpamPool.Properties.ParentPoolName
                        } else {
                            $LocalizedData.None
                        })
                        $LocalizedData.StaticCidrs = $(if ($null -eq $StaticCidrMap[$AzIpamPool.Name]) {
                            $LocalizedData.Unknown
                        } else {
                            $StaticCidrMap[$AzIpamPool.Name].Count
                        })
                        $LocalizedData.ProvisioningState = $(if ($AzIpamPool.Properties.ProvisioningState) {
                            $AzIpamPool.Properties.ProvisioningState
                        } else {
                            $LocalizedData.Unknown
                        })
                        $LocalizedData.Description = $(if ($AzIpamPool.Properties.Description) {
                            $AzIpamPool.Properties.Description
                        } else {
                            $LocalizedData.None
                        })
                    }
                }

                # An unreported state is not evidence of a failure, so only known states are highlighted
                if ($Healthcheck.VirtualNetworkManager.ProvisioningState) {
                    $AzIpamPoolInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -notin @('Succeeded', $LocalizedData.Unknown) } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                }

                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeadings) - $NetworkManagerName"
                        List = $false
                        ColumnWidths = 18, 13, 17, 14, 9, 13, 16
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzIpamPoolInfo | Table @TableParams

                    foreach ($AzIpamPool in $AzIpamPools) {
                        $AzStaticCidrs = $StaticCidrMap[$AzIpamPool.Name]
                        if ($AzStaticCidrs) {
                            $AzStaticCidrInfo = foreach ($AzStaticCidr in $AzStaticCidrs) {
                                [PSCustomObject]@{
                                    $LocalizedData.Name = $AzStaticCidr.Name
                                    $LocalizedData.AddressPrefixes = $(if ($AzStaticCidr.Properties.AddressPrefixes) {
                                        $AzStaticCidr.Properties.AddressPrefixes -join [Environment]::NewLine
                                    } else {
                                        $LocalizedData.None
                                    })
                                    $LocalizedData.TotalIpAddresses = $(if ($AzStaticCidr.Properties.TotalNumberOfIPAddresses) {
                                        $AzStaticCidr.Properties.TotalNumberOfIPAddresses
                                    } else {
                                        $LocalizedData.Unknown
                                    })
                                    $LocalizedData.ProvisioningState = $(if ($AzStaticCidr.Properties.ProvisioningState) {
                                        $AzStaticCidr.Properties.ProvisioningState
                                    } else {
                                        $LocalizedData.Unknown
                                    })
                                    $LocalizedData.Description = $(if ($AzStaticCidr.Properties.Description) {
                                        $AzStaticCidr.Properties.Description
                                    } else {
                                        $LocalizedData.None
                                    })
                                }
                            }

                            if ($Healthcheck.VirtualNetworkManager.ProvisioningState) {
                                $AzStaticCidrInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -notin @('Succeeded', $LocalizedData.Unknown) } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                            }

                            Section -Style NOTOCHeading7 -ExcludeFromTOC "$($AzIpamPool.Name)" {
                                $TableParams = @{
                                    Name = "$($LocalizedData.StaticCidrTableHeading) - $($AzIpamPool.Name)"
                                    List = $false
                                    ColumnWidths = 25, 20, 15, 15, 25
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzStaticCidrInfo | Table @TableParams
                            }
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning ($LocalizedData.CollectionError -f $NetworkManagerName, $_.Exception.Message)
            Paragraph ($LocalizedData.Unavailable -f $NetworkManagerName)
        }
    }

    end {}
}
