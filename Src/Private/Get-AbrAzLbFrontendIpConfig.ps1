function Get-AbrAzLbFrontendIpConfig {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Load Balancer Frontend IP Configuration information
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
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
        $AzLbFrontendIpConfigs = (Get-AzLoadBalancer -Name $Name).FrontendIpConfigurations | Sort-Object Name
        if ($AzLbFrontendIpConfigs) {
            Write-PscriboMessage "Collecting Azure Load Balancer Frontend IP Configuration information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Frontend IP Configuration' {
                foreach ($AzLbFrontendIpConfig in $AzLbFrontendIpConfigs) {
                    Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzLbFrontendIpConfig.Name) {
                        $AzLbFrontendIpConfigInfo = @()
                        $InObj = [Ordered]@{
                            'Name' = $AzLbFrontendIpConfig.Name
                            'Private IP Address' = Switch ($AzLbFrontendIpConfig.PrivateIpAddress) {
                                $null { '--' }
                                default { $AzLbFrontendIpConfig.PrivateIpAddress }
                            }
                            'Private IP Allocation Method' = Switch ($AzLbFrontendIpConfig.PrivateIpAllocationMethod) {
                                $null { '--' }
                                default { $AzLbFrontendIpConfig.PrivateIpAllocationMethod }
                            }
                            'Public IP Address' = Switch ($AzLbFrontendIpConfig.PublicIpAddress) {
                                $null { '--' }
                                default { $AzLbFrontendIpConfig.PublicIpAddress }
                            }
                            'Subnet' = Switch ($AzLbFrontendIpConfig.Subnet.Id) {
                                $null { '--' }
                                default { ($AzLbFrontendIpConfig.Subnet.Id).split('/')[-1] }
                            }
                            'Load Balancing Rules' = Switch ($AzLbFrontendIpConfig.LoadBalancingRules.Id) {
                                $null { 'None' }
                                default { ($AzLbFrontendIpConfig.LoadBalancingRules.Id).split('/')[-1] }
                            }
                            'Inbound NAT Rules' = Switch ($AzLbFrontendIpConfig.InboundNatRules.Id) {
                                $null { 'None' }
                                default { ($AzLbFrontendIpConfig.InboundNatRules.Id).split('/')[-1] }
                            }
                        }
                        $AzLbFrontendIpConfigInfo += [PSCustomObject]$InObj

                        $TableParams = @{
                            Name = "Frontend IP Configuration - $($AzLbFrontendIpConfig.Name)"
                            List = $true
                            ColumnWidths = 50, 50
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzLbFrontendIpConfigInfo | Table @TableParams
                    }
                }
            }
        }
    }

    end {}
}