function Get-AbrAzSubscription {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Subscription information
    .DESCRIPTION

    .NOTES
        Version:        0.1.2
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
        Write-PScriboMessage "Subscription InfoLevel set at $($InfoLevel.Subscription)."
    }

    process {
        Try {
            if (($InfoLevel.Subscription -gt 0) -and ($AzSubscriptions)) {
                Write-PscriboMessage "Collecting Azure Subscription information."
                if ($Options.ShowSectionInfo) {
                    Paragraph "An Azure subscription is a logical container used to provision resources in Azure. It holds the details of all your resources like virtual machines (VMs), databases, and more. When you create an Azure resource like a VM, you must identify the subscription it belongs to."
                    BlankLine
                }
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
                Write-PScriboMessage -IsWarning 'No subscriptions found.'
                Break
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}