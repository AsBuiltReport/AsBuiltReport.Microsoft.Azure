function Get-AbrAzManagementGroup {
    [CmdletBinding()]
    param ()
    begin {
        $LocalizedData = $reportTranslate.GetAbrAzManagementGroup
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.ManagementGroup)
        Write-PScriboMessage $LocalizedData.Collecting
    }
    process {
        if ($InfoLevel.ManagementGroup -ge 1) {
            try {
                $AzRootMG = Get-AzManagementGroup -GroupName $TenantId -Expand -Recurse -ErrorAction Stop
                if ($AzRootMG) {
                    Section -Style Heading2 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        $OutObj = [System.Collections.Generic.List[PSCustomObject]]::new()
                        $MgQueue = [System.Collections.Queue]::new()
                        $MgQueue.Enqueue(@{ MG = $AzRootMG; ParentName = $LocalizedData.None })
                        while ($MgQueue.Count -gt 0) {
                            $MgQueueItem = $MgQueue.Dequeue()
                            $CurrentMG = $MgQueueItem.MG
                            $ParentName = $MgQueueItem.ParentName
                            $ChildGroupCount = ($CurrentMG.Children | Where-Object { $_.Type -like '*managementGroups*' } | Measure-Object).Count
                            $SubscriptionCount = ($CurrentMG.Children | Where-Object { $_.Type -like '*subscriptions*' } | Measure-Object).Count
                            $OutObj.Add([PSCustomObject][Ordered]@{
                                $LocalizedData.Name              = $CurrentMG.DisplayName
                                $LocalizedData.Id                = $CurrentMG.Name
                                $LocalizedData.ParentName        = $ParentName
                                $LocalizedData.ChildGroupCount   = $ChildGroupCount
                                $LocalizedData.SubscriptionCount = $SubscriptionCount
                            })
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
                        if ($Options.EnableDiagrams) {
                            try {
                                Get-AbrDiagAzManagementGroup -RootManagementGroup $AzRootMG
                            } catch {
                                Write-PScriboMessage -IsWarning ($LocalizedData.DiagramError -f $_.Exception.Message)
                            }
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "$($LocalizedData.ErrorMessage) $($_.Exception.Message)"
            }
        }
    }
    end {}
}
