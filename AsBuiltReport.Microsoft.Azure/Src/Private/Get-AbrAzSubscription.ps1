function Get-AbrAzSubscription {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Subscription information
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
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzSubscription
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Subscription)
    }

    process {
        Try {
            if (($InfoLevel.Subscription -gt 0) -and ($AzSubscriptions)) {
                Write-PscriboMessage $LocalizedData.Collecting
                if ($Options.ShowSectionInfo) {
                    Paragraph $LocalizedData.SectionInfo
                    BlankLine
                }
                Paragraph ($LocalizedData.ParagraphSummary -f $AzTenant.Name)
                BlankLine
                $AzSubscriptionInfo = @()
                foreach ($AzSubscription in $AzSubscriptions) {
                    $InObj = [Ordered]@{
                        $LocalizedData.Name = $AzSubscription.Name
                        $LocalizedData.SubscriptionID = $AzSubscription.SubscriptionId
                        $LocalizedData.State = $AzSubscription.State
                    }
                    $AzSubscriptionInfo += [pscustomobject]$InObj
                }

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $($AzTenant.Name)"
                    List = $false
                    ColumnWidths = 35, 50, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzSubscriptionInfo | Table @TableParams
            } else {
                Write-PScriboMessage $LocalizedData.NoSubscriptions
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}