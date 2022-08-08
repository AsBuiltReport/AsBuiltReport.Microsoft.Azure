function Get-AbrAzNetworkSecurityGroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Availability Set information
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
        Write-PScriboMessage "NetworkSecurityGroup InfoLevel set at $($InfoLevel.NetworkSecurityGroup)."
    }

    process {
        $AzNetworkSecurityGroups = Get-AzNetworkSecurityGroup | Sort-Object Name
        if (($InfoLevel.NetworkSecurityGroup -gt 0) -and ($AzNetworkSecurityGroups)) {
            Write-PscriboMessage "Collecting Azure Network Security Group information."
            Section -Style Heading2 'Network Security Groups' {
                $AzNsgInfo = @()
                foreach ($AzNetworkSecurityGroup in $AzNetworkSecurityGroups) {
                    $InObj = [Ordered]@{
                        'Name' = $AzNetworkSecurityGroup.Name
                        'Resource Group' = $AzNetworkSecurityGroup.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzNetworkSecurityGroup.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzNetworkSecurityGroup.Id).split('/')[2]))"
                        'Associated With' = "$(($AzNetworkSecurityGroup.Subnets.Id).Count) subnets, $(($AzNetworkSecurityGroup.NetworkInterfaces.Id).Count) NICs"
                        'Network Interfaces'  = & {
                            if ($AzNetworkSecurityGroup.NetworkInterfaces.Id) {
                                ($AzNetworkSecurityGroup.NetworkInterfaces.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                'None'
                            }
                        }
                        'Subnets'  = & {
                            if ($AzNetworkSecurityGroup.Subnets.Id) {
                                ($AzNetworkSecurityGroup.Subnets.Id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                'None'
                            }
                        }
                    }
                    $AzNsgInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.NetworkSecurityGroup -ge 2) {
                    Paragraph "The following sections detail the configuration of the network security groups within the $($AzSubscription.Name) subscription."
                    foreach ($AzNetworkSecurityGroup in $AzNsgInfo) {
                        Section -Style Heading4 "$($AzNetworkSecurityGroup.Name)" {
                            $TableParams = @{
                                Name = "Network Security Group - $($AzNetworkSecurityGroup.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzNetworkSecurityGroup | Table @TableParams
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the network security groups within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Network Security Groups - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'Associated With'
                        ColumnWidths = 25, 25, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzNsgInfo | Table @TableParams
                }
            }
        }
    }

    end {}
}