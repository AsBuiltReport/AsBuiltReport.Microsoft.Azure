function Get-AbrAzIpGroup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure IP Group information
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
        Write-PScriboMessage "IPGroup InfoLevel set at $($InfoLevel.IPGroup)."
    }

    process {
        $AzIpGroups = Get-AzIpGroup | Sort-Object Name
        if (($InfoLevel.IpGroup -gt 0) -and ($AzIpGroups)) {
            Write-PscriboMessage "Collecting Azure IP Group information."
            Section -Style Heading4 'IP Groups' {
                $AzIpGroupInfo = @()
                foreach ($AzIpGroup in $AzIpGroups) {
                    $InObj = [Ordered]@{
                        'Name' = $AzIpGroup.Name
                        'Resource Group' = $AzIpGroup.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzIpGroup.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzIpGroup.Id).split('/')[2]))"
                        'Provisioning State' = $AzIpGroup.ProvisioningState
                        'Firewalls' = & {
                            if ($AzIpGroup.Firewalls.id) {
                                ($AzIpGroup.Firewalls.id | ForEach-Object {$_.split('/')[-1]}) -join ', '
                            } else {
                                'None'
                            }
                        }
                        'IP Addresses' = & {
                            if ($AzIpGroup.IpAddresses) {
                                $AzIpGroup.IpAddresses -join ', '
                            } else {
                                'None'
                            }
                        }
                    }
                    $AzIpGroupInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.IPGroup -ge 2) {
                    Paragraph "The following sections detail the configuration of the IP groups within the $($AzSubscription.Name) subscription."
                    foreach ($AzIpGroup in $AzIpGroupInfo) {
                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzIpGroup.Name)" {
                            $TableParams = @{
                                Name = "IP Group - $($AzIpGroup.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzIpGroup | Table @TableParams
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the IP groups within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "IP Groups - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'IP Addresses'
                        ColumnWidths = 25, 25, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzIpGroupInfo | Table @TableParams
                }
            }
        }
    }

    end {}
}