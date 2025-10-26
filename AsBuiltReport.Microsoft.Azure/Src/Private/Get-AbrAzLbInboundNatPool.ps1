function Get-AbrAzLbInboundNatPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Inbound NAT Pool information
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
        $LocalizedData = $reportTranslate.GetAbrAzLbInboundNatPool
    }

    process {
        try {
            $AzLbInboundNatPools = (Get-AzLoadBalancer -Name $Name).InboundNatPools | Sort-Object Name
            if ($AzLbInboundNatPools) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $AzLbInboundNatPoolInfo = @()
                    foreach ($AzLbInboundNatPool in $AzLbInboundNatPools) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Name = $AzLbInboundNatPool.Name
                        }
                        $AzLbInboundNatPoolInfo += [PSCustomObject]$InObj
                    }
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($Name)"
                        List = $false
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzLbInboundNatPoolInfo | Table @TableParams
                }
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}