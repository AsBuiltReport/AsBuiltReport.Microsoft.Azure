function Get-AbrAzLbLoadBalancingRule {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Load Balancing Rules information
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
        $LocalizedData = $reportTranslate.GetAbrAzLbLoadBalancingRule
    }

    process {
        Try {
            $AzLbLoadBalancingRules = (Get-AzLoadBalancer -Name $Name).LoadBalancingRules | Sort-Object Name
            if ($AzLbLoadBalancingRules) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    foreach ($AzLbLoadBalancingRule in $AzLbLoadBalancingRules) {
                        Section -Style NOTOCHeading7 -ExcludeFromTOC $($AzLbLoadBalancingRule.Name) {
                            $AzLbLoadBalancingRuleInfo = @()
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzLbLoadBalancingRule.Name
                                $LocalizedData.FrontendIPAddress = ($AzLbLoadBalancingRule.FrontendIPConfiguration.Id).split('/')[-1]
                                $LocalizedData.BackendPool = ($AzLbLoadBalancingRule.BackendAddressPool.Id).split('/')[-1]
                                $LocalizedData.Protocol = $AzLbLoadBalancingRule.Protocol
                                $LocalizedData.Port = $AzLbLoadBalancingRule.FrontendPort
                                $LocalizedData.BackendPort = $AzLbLoadBalancingRule.BackendPort
                                $LocalizedData.HealthProbe = ($AzLbLoadBalancingRule.Probe.Id).split('/')[-1]
                                $LocalizedData.IdleTimeout = ($LocalizedData.minutes -f $AzLbLoadBalancingRule.IdleTimeoutInMinutes)
                                $LocalizedData.FloatingIP = if ($AzLbLoadBalancingRule.EnableFloatingIP) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                            }
                            $AzLbLoadBalancingRuleInfo += [PSCustomObject]$InObj

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($AzLbLoadBalancingRule.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzLbLoadBalancingRuleInfo | Table @TableParams
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