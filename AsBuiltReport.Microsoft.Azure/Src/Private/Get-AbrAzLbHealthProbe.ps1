function Get-AbrAzLbHealthProbe {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Health Probe information
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
        $LocalizedData = $reportTranslate.GetAbrAzLbHealthProbe
    }

    process {
        Try {
            $AzLbHealthProbes = (Get-AzLoadBalancer -Name $Name).Probes | Sort-Object Name
            if ($AzLbHealthProbes) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzLbHealthProbeInfo = @()
                    foreach ($AzLbHealthProbe in $AzLbHealthProbes) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzLbHealthProbe.Name
                            $LocalizedData.Protocol = $AzLbHealthProbe.Protocol
                            $LocalizedData.Port = $AzLbHealthProbe.Port
                            $LocalizedData.Interval = ($LocalizedData.Seconds -f $AzLbHealthProbe.IntervalInSeconds)
                            $LocalizedData.UsedBy = & {
                                if ($AzLbHealthProbe.LoadBalancingRules.Id) {
                                    ($AzLbHealthProbe.LoadBalancingRules.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                                } else {
                                    $LocalizedData.None
                                }
                            }
                        }
                        $AzLbHealthProbeInfo += [PSCustomObject]$InObj
                    }
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($Name)"
                        List = $false
                        ColumnWidths = 20, 20, 20, 20, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzLbHealthProbeInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}