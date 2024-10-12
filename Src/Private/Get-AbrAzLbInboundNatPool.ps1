function Get-AbrAzLbInboundNatPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Load Balancer Inbound NAT Pool information
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
        try {
            $AzLbInboundNatPools = (Get-AzLoadBalancer -Name $Name).InboundNatPools | Sort-Object Name
            if ($AzLbInboundNatPools) {
                Write-PscriboMessage "Collecting Azure Load Balancer Inbound NAT Pool information."
                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Inbound NAT Pools' {
                    $AzLbInboundNatPoolInfo = @()
                    foreach ($AzLbInboundNatPool in $AzLbInboundNatPools) {
                        $InObj = [Ordered]@{
                            'Name' = $AzLbInboundNatPool.Name
                        }
                        $AzLbInboundNatPoolInfo += [PSCustomObject]$InObj
                    }
                    $TableParams = @{
                        Name = "Inbound NAT Pools - $($Name)"
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
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}