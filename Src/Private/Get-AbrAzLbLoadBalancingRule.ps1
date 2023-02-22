function Get-AbrAzLbLoadBalancingRule {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Load Balancer Load Balancing Rules information
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
        $AzLbLoadBalancingRules = (Get-AzLoadBalancer -Name $Name).LoadBalancingRules | Sort-Object Name
        if ($AzLbLoadBalancingRules) {
            Write-PscriboMessage "Collecting Azure Load Balancer Load Balancing Rules information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Load Balancing Rules' {
                foreach ($AzLbLoadBalancingRule in $AzLbLoadBalancingRules) {
                    Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzLbLoadBalancingRule.Name) {
                        $AzLbLoadBalancingRuleInfo = @()
                        $InObj = [Ordered]@{
                            'Name' = $AzLbLoadBalancingRule.Name
                            'Frontend IP Address' = ($AzLbLoadBalancingRule.FrontendIPConfiguration.Id).split('/')[-1]
                            'Backend Pool' = ($AzLbLoadBalancingRule.BackendAddressPool.Id).split('/')[-1]
                            'Protocol' = $AzLbLoadBalancingRule.Protocol
                            'Port' = $AzLbLoadBalancingRule.FrontendPort
                            'Backend Port' = $AzLbLoadBalancingRule.BackendPort
                            'Health Probe' = ($AzLbLoadBalancingRule.Probe.Id).split('/')[-1]
                            'Idle Timeout' = "$($AzLbLoadBalancingRule.IdleTimeoutInMinutes) mins"
                            'Floating IP' = Switch ($AzLbLoadBalancingRule.EnableFloatingIP) {
                                $true { 'Enabled' }
                                $false { 'Disabled' }
                            }
                        }
                        $AzLbLoadBalancingRuleInfo += [PSCustomObject]$InObj

                        $TableParams = @{
                            Name = "Load Balancing Rule - $($AzLbLoadBalancingRule.Name)"
                            List = $true
                            ColumnWidths = 50, 50
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzLbLoadBalancingRuleInfo | Table @TableParams
                    }
                }
            }
        }
    }

    end {}
}