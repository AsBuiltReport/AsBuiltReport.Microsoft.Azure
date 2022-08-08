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
            Section -Style Heading5 'Frontend IP Configuration' {
                foreach ($AzLbFrontendIpConfig in $AzLbFrontendIpConfigs) {
                    Section -Style Heading5 $($AzLbFrontendIpConfig.Name) {
                        $AzLbFrontendIpConfigInfo = @()
                        $InObj = [Ordered]@{
                            'Name' = $AzLbFrontendIpConfig.Name
                            'Private IP Address' = $AzLbFrontendIpConfig.PrivateIpAddress
                            'Private IP Allocation Method' = $AzLbFrontendIpConfig.PrivateIpAllocationMethod
                            'Public IP Address' = Switch ($AzLbFrontendIpConfig.PublicIpAddress) {
                                $null { '--' }
                                default { $AzLbFrontendIpConfig.PublicIpAddress }
                            }
                            'Subnet' = ($AzLbFrontendIpConfig.Subnet.Id).split('/')[-1]
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