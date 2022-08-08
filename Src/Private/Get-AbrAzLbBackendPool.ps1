function Get-AbrAzLbBackendPool {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Load Balancer Backend Pool information
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
        $AzLbBackendPools = (Get-AzLoadBalancer -Name $Name).BackendAddressPools | Sort-Object Name
        if ($AzLbBackendPools) {
            Write-PscriboMessage "Collecting Azure Load Balancer Backend Pool information."
            Section -Style Heading5 'Backend Pools' {
                $AzLbBackendPoolInfo = @()
                foreach ($AzLbBackendPool in $AzLbBackendPools) {
                    $InObj = [Ordered]@{
                        'Name' = $AzLbBackendPool.Name
                        'Load Balancing Rules' = & {
                            if ($AzLbBackendPool.LoadBalancingRules.Id) {
                                ($AzLbBackendPool.LoadBalancingRules.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                'None'
                            }
                        }
                    }
                    $AzLbBackendPoolInfo = [PSCustomObject]$InObj
                }
                $TableParams = @{
                    Name = "Backend Pools - $($Name)"
                    List = $false
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzLbBackendPoolInfo | Table @TableParams
            }
        }
    }

    end {}
}