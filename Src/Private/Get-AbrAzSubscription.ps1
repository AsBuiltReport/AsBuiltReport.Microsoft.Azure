function Get-AbrAzSubscription {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Subscription information
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
        Write-PscriboMessage "Collecting Azure Subscription information."
    }

    process {
        if ($AzSubscriptions) {
            Paragraph "The following table summarises the subscription information within the $($AzTenant.Name) tenant."
            BlankLine
            $AzSubscriptionInfo = @()
            foreach ($AzSubscription in $AzSubscriptions) {
                $InObj = [Ordered]@{
                    'Name' = $AzSubscription.Name
                    'Subscription ID' = $AzSubscription.SubscriptionId
                    'State' = $AzSubscription.State
                }
                $AzSubscriptionInfo += [pscustomobject]$InObj
            }

            $TableParams = @{
                Name = "Subscriptions - $($AzTenant.Name)"
                List = $false
                ColumnWidths = 35, 50, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $AzSubscriptionInfo | Table @TableParams
        } else {
            Write-PScriboMessage 'No subscriptions found.'
            Break
        }
    }

    end {}
}