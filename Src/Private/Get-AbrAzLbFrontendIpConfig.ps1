function Get-AbrAzLbFrontendIpConfig {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Frontend IP Configuration information
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
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

    begin {}

    process {
        Try {
            $AzLbFrontendIpConfigs = (Get-AzLoadBalancer -Name $Name).FrontendIpConfigurations | Sort-Object Name
            if ($AzLbFrontendIpConfigs) {
                Write-PscriboMessage "Collecting Azure Load Balancer Frontend IP Configuration information."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Frontend IP Configuration' {
                    foreach ($AzLbFrontendIpConfig in $AzLbFrontendIpConfigs) {
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzLbFrontendIpConfig.Name) {
                            $AzLbFrontendIpConfigInfo = @()
                            $InObj = [Ordered]@{
                                'Name' = $AzLbFrontendIpConfig.Name
                                'Private IP Address' = if ($AzLbFrontendIpConfig.PrivateIpAddress) {
                                    $AzLbFrontendIpConfig.PrivateIpAddress
                                } else {
                                    'None'
                                }
                                'Private IP Allocation Method' = if ($AzLbFrontendIpConfig.PrivateIpAllocationMethod) {
                                    $AzLbFrontendIpConfig.PrivateIpAllocationMethod
                                } else {
                                    'Unknown'
                                }
                                'Public IP Address' = if ($AzLbFrontendIpConfig.PublicIpAddress) {
                                    $AzLbFrontendIpConfig.PublicIpAddress
                                } else {
                                    'None'
                                }
                                'Subnet' = iCloudFirefox.exe ($AzLbFrontendIpConfig.Subnet.Id) {
                                    ($AzLbFrontendIpConfig.Subnet.Id).split('/')[-1]
                                } else {
                                    'None'
                                }
                                'Load Balancing Rules' = if ($AzLbFrontendIpConfig.LoadBalancingRules.Id) {
                                    ($AzLbFrontendIpConfig.LoadBalancingRules.Id).split('/')[-1]
                                } else {
                                    'None'
                                }
                                'Inbound NAT Rules' = if ($AzLbFrontendIpConfig.InboundNatRules.Id) {
                                    ($AzLbFrontendIpConfig.InboundNatRules.Id).split('/')[-1]
                                } else {
                                    'None'
                                }
                            }
                            $AzLbFrontendIpConfigInfo += [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "Frontend IP Configuration - $($AzLbFrontendIpConfig.Name)"
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