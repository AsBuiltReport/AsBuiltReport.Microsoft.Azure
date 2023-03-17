function Get-AbrAzLbHealthProbe {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Load Balancer Health Probe information
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
        $AzLbHealthProbes = (Get-AzLoadBalancer -Name $Name).Probes | Sort-Object Name
        if ($AzLbHealthProbes) {
            Write-PscriboMessage "Collecting Azure Load Balancer Health Probe information."
            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Health Probes' {
                $AzLbHealthProbeInfo = @()
                foreach ($AzLbHealthProbe in $AzLbHealthProbes) {
                    $InObj = [Ordered]@{
                        'Name' = $AzLbHealthProbe.Name
                        'Protocol' = $AzLbHealthProbe.Protocol
                        'Port' = $AzLbHealthProbe.Port
                        'Interval' = "$($AzLbHealthProbe.IntervalInSeconds) secs"
                        'Used By' = & {
                            if ($AzLbHealthProbe.LoadBalancingRules.Id) {
                                ($AzLbHealthProbe.LoadBalancingRules.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                '--'
                            }
                        }
                    }
                    $AzLbHealthProbeInfo += [PSCustomObject]$InObj
                }
                $TableParams = @{
                    Name = "Health Probes - $($Name)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzLbHealthProbeInfo | Table @TableParams
            }
        }
    }

    end {}
}