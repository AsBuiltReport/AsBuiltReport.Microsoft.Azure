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
        $AzLbInboundNatPools = (Get-AzLoadBalancer -Name $Name).InboundNatPools | Sort-Object Name
        if ($AzLbInboundNatPools) {
            Write-PscriboMessage "Collecting Azure Load Balancer Inbound NAT Pool information."
            Section -Style Heading5 'Inbound NAT Pools' {
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
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzLbInboundNatPoolInfo | Table @TableParams
            }
        }
    }

    end {}
}