function Get-AbrAzLbFrontendIpConfig {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Frontend IP Configuration information
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
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Name
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzLbFrontendIpConfig
    }

    process {
        Try {
            $AzLbFrontendIpConfigs = (Get-AzLoadBalancer -Name $Name).FrontendIpConfigurations | Sort-Object Name
            if ($AzLbFrontendIpConfigs) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    foreach ($AzLbFrontendIpConfig in $AzLbFrontendIpConfigs) {
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzLbFrontendIpConfig.Name) {
                            $AzLbFrontendIpConfigInfo = @()
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzLbFrontendIpConfig.Name
                                $LocalizedData.PrivateIPAddress = if ($AzLbFrontendIpConfig.PrivateIpAddress) {
                                    $AzLbFrontendIpConfig.PrivateIpAddress
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.PrivateIPAllocationMethod = if ($AzLbFrontendIpConfig.PrivateIpAllocationMethod) {
                                    $AzLbFrontendIpConfig.PrivateIpAllocationMethod
                                } else {
                                    $LocalizedData.Unknown
                                }
                                $LocalizedData.PublicIPAddress = if ($AzLbFrontendIpConfig.PublicIpAddress) {
                                    $AzLbFrontendIpConfig.PublicIpAddress
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.Subnet = if ($AzLbFrontendIpConfig.Subnet.Id) {
                                    ($AzLbFrontendIpConfig.Subnet.Id).split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.LoadBalancingRules = if ($AzLbFrontendIpConfig.LoadBalancingRules.Id) {
                                    ($AzLbFrontendIpConfig.LoadBalancingRules.Id).split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.InboundNATRules = if ($AzLbFrontendIpConfig.InboundNatRules.Id) {
                                    ($AzLbFrontendIpConfig.InboundNatRules.Id).split('/')[-1]
                                } else {
                                    $LocalizedData.None
                                }
                            }
                            $AzLbFrontendIpConfigInfo += [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzLbFrontendIpConfig.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzLbFrontendIpConfigInfo | Table @TableParams
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