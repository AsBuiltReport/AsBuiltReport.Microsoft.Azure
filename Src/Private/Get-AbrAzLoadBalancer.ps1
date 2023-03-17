function Get-AbrAzLoadBalancer {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Load Balancer information
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
    )

    begin {
        Write-PScriboMessage "LoadBalancer InfoLevel set at $($InfoLevel.LoadBalancer)."
    }

    process {
        $AzLoadBalancers = Get-AzLoadBalancer | Sort-Object Name
        if (($InfoLevel.LoadBalancer -gt 0) -and ($AzLoadBalancers)) {
            Write-PscriboMessage "Collecting Azure Load Balancer information."
            Section -Style Heading4 'Load Balancers' {
                $AzLoadBalancerInfo = @()
                foreach ($AzLoadBalancer in $AzLoadBalancers) {
                    $InObj = [Ordered]@{
                        'Name' = $AzLoadBalancer.Name
                        'Resource Group' = $AzLoadBalancer.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzLoadBalancer.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzLoadBalancer.Id).split('/')[2]))"
                        'Provisioning State' = $AzLoadBalancer.ProvisioningState
                        'SKU' = $AzLoadBalancer.Sku.Name
                        'Tier' = $AzLoadBalancer.Sku.Tier
                        ##ToDo:  NAT Rules
                    }
                    $AzLoadBalancerInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.LoadBalancer -ge 2) {
                    Paragraph "The following sections detail the configuration of the load balancers within the $($AzSubscription.Name) subscription."
                    foreach ($AzLoadBalancer in $AzLoadBalancerInfo) {
                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzLoadBalancer.Name)" {
                            $TableParams = @{
                                Name = "Load Balancer - $($AzLoadBalancer.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzLoadBalancer | Table @TableParams

                            # Get Frontend IP Configuration
                            Get-AbrAzLbFrontendIpConfig -Name $($AzLoadBalancer.Name)

                            # Get Backend Pool Configuration
                            Get-AbrAzLbBackendPool -Name $($AzLoadBalancer.Name)

                            # Get Health Probe Configuration
                            Get-AbrAzLbHealthProbe -Name $($AzLoadBalancer.Name)

                            # Get Load Balancing Rules
                            Get-AbrAzLbLoadBalancingRule -Name $($AzLoadBalancer.Name)
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the load balancers within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Load Balancers - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'SKU', 'Tier'
                        ColumnWidths = 20, 20, 20, 20, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzLoadBalancerInfo | Table @TableParams
                }
            }
        }
    }

    end {}
}