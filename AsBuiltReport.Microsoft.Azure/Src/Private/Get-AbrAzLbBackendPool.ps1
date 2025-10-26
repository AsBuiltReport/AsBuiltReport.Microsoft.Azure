function Get-AbrAzLbBackendPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Backend Pool information
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
        $LocalizedData = $reportTranslate.GetAbrAzLbBackendPool
    }

    process {
        Try {
            $AzLbBackendPools = (Get-AzLoadBalancer -Name $Name).BackendAddressPools | Sort-Object Name
            if ($AzLbBackendPools) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzLbBackendPoolInfo = @()
                    foreach ($AzLbBackendPool in $AzLbBackendPools) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzLbBackendPool.Name
                            $LocalizedData.LoadBalancingRules = if ($AzLbBackendPool.LoadBalancingRules.Id) {
                                ($AzLbBackendPool.LoadBalancingRules.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                $LocalizedData.None
                            }
                        }
                        $AzLbBackendPoolInfo = [PSCustomObject]$InObj
                    }
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($Name)"
                        List = $false
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzLbBackendPoolInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}