function Get-AbrAzManagementGroup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Management Group information
    .DESCRIPTION
        Documents the configuration of Azure Management Groups including the management group
        hierarchy, parent relationships, child group counts, and subscription counts.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param ()
    begin {
        $LocalizedData = $reportTranslate.GetAbrAzManagementGroup
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.ManagementGroup)
    }
    process {
        if ($InfoLevel.ManagementGroup -ge 1) {
            try {
                $AzRootMG = Get-AzManagementGroup -GroupName $TenantId -Expand -Recurse -ErrorAction Stop
                if ($AzRootMG) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading2 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        if ($Options.EnableDiagrams) {
                            try {
                                Get-AbrDiagAzManagementGroup -RootManagementGroup $AzRootMG
                            } catch {
                                Write-PScriboMessage -IsWarning ($LocalizedData.DiagramError -f $_.Exception.Message)
                            }
                        }
                        $OutObj = @()
                        $MgQueue = [System.Collections.Queue]::new()
                        $MgQueue.Enqueue(@{ MG = $AzRootMG; ParentName = $LocalizedData.None })
                        while ($MgQueue.Count -gt 0) {
                            $MgQueueItem = $MgQueue.Dequeue()
                            $CurrentMG = $MgQueueItem.MG
                            $ParentName = $MgQueueItem.ParentName
                            $ChildGroupCount = ($CurrentMG.Children | Where-Object { $_.Type -like '*managementGroups*' } | Measure-Object).Count
                            $SubscriptionCount = ($CurrentMG.Children | Where-Object { $_.Type -like '*subscriptions*' } | Measure-Object).Count
                            $InObj = [Ordered]@{
                                $LocalizedData.Name              = $CurrentMG.DisplayName
                                $LocalizedData.Id                = $CurrentMG.Name
                                $LocalizedData.ParentName        = $ParentName
                                $LocalizedData.ChildGroupCount   = $ChildGroupCount
                                $LocalizedData.SubscriptionCount = $SubscriptionCount
                            }
                            $OutObj += [PSCustomObject]$InObj
                            foreach ($MgChild in $CurrentMG.Children) {
                                if ($MgChild.Type -like '*managementGroups*') {
                                    $MgQueue.Enqueue(@{ MG = $MgChild; ParentName = $CurrentMG.DisplayName })
                                }
                            }
                        }
                        $TableParams = @{
                            Name         = $LocalizedData.TableHeading
                            List         = $false
                            ColumnWidths = 25, 30, 25, 10, 10
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "$($LocalizedData.ErrorMessage) $($_.Exception.Message)"
            }
        }
    }
    end {}
}
