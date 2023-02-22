function Get-AbrAzBastion {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Bastion information
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
        Write-PScriboMessage "Bastion InfoLevel set at $($InfoLevel.Bastion)."
    }

    process {
        $AzBastions = Get-AzBastion | Sort-Object Name
        if (($InfoLevel.Bastion -gt 0) -and ($AzBastions)) {
            Write-PscriboMessage "Collecting Azure Bastion information."
            Section -Style Heading4 'Bastion' {
                $AzBastionInfo = @()
                foreach ($AzBastion in $AzBastions) {
                    $InObj = [Ordered]@{
                        'Name' = $AzBastion.Name
                        'Resource Group' = $AzBastion.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzBastion.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzBastion.Id).split('/')[2]))"
                        'Virtual Network / Subnet' = $AzBastion.IpConfigurations.subnet.id.split('/')[-1]
                        'Public DNS Name' = $AzBastion.DnsName
                        'Public IP Address' = $AzBastion.IpConfigurations.publicipaddress.id.split('/')[-1]
                    }
                    $AzBastionInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.Bastion -ge 2) {
                    Paragraph "The following sections detail the configuration of the bastions within the $($AzSubscription.Name) subscription."
                    foreach ($AzBastion in $AzBastionInfo) {
                        Section -Style Heading5 "$($AzBastion.Name)" {
                            $TableParams = @{
                                Name = "Bastion - $($AzBastion.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzBastion | Table @TableParams
                        }
                    }
                } else {
                    Paragraph "The following table summarises the configuration of the bastions within the $($AzSubscription.Name) subscription."
                    BlankLine
                    $TableParams = @{
                        Name = "Bastions - $($AzSubscription.Name)"
                        List = $false
                        Columns = 'Name', 'Resource Group', 'Location', 'Public IP Address'
                        ColumnWidths = 25, 25, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzBastionInfo | Table @TableParams
                }
            }
        }
    }

    end {}
}