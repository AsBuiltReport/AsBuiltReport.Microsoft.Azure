function Get-AbrDiagAzManagementGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Object] $RootManagementGroup
    )
    begin {
        $LocalizedData = $reportTranslate.GetAbrAzManagementGroup
    }
    process {
        try {
            $DiagramTheme = if ($Options.DiagramTheme) { $Options.DiagramTheme } else { 'White' }
            $DiagramDpi = if ($Options.DiagramDpi) { $Options.DiagramDpi } else { 96 }
            # PScribo's Image -Percent scales off raw pixel count assuming a fixed 96 DPI baseline,
            # so a higher render DPI must be offset by a proportionally lower Percent to keep the
            # printed size on the page the same while still gaining pixel density.
            $DiagramPercent = [Math]::Max(1, [Math]::Round(9600 / $DiagramDpi))
            $FontColor = if ($DiagramTheme -eq 'Black') { '#FFFFFF' } else { '#000000' }
            $EdgeColor = if ($DiagramTheme -eq 'Black') { '#AAAAAA' } else { '#333333' }
            $CellBgColor = if ($DiagramTheme -eq 'Black') { '#2D2D2D' } else { '#FFFFFF' }
            $TableBorderColor = if ($DiagramTheme -eq 'Black') { '#AAAAAA' } else { '#333333' }

            $ModuleBase = (Get-Module -Name 'AsBuiltReport.Microsoft.Azure').ModuleBase
            $IconPath = [System.IO.FileInfo](Join-Path $ModuleBase 'Icons')
            $ImagesObj = @{
                'MG' = 'management-groups.png'
                'Sub' = 'subscriptions.png'
                'Blank' = 'blank.png'
            }

            # Pass 1: BFS to collect all MG info in root-to-leaf order
            $MgList = [System.Collections.Generic.List[hashtable]]::new()
            $MgQueue = [System.Collections.Queue]::new()
            $MgQueue.Enqueue(@{ MG = $RootManagementGroup; ParentId = $null })
            while ($MgQueue.Count -gt 0) {
                $Item = $MgQueue.Dequeue()
                $CurrentMG = $Item.MG
                $DirectSubs = @($CurrentMG.Children |
                    Where-Object { $_.Type -like '*subscriptions*' } |
                    Select-Object -ExpandProperty DisplayName)
                $ChildMgIds = @($CurrentMG.Children |
                    Where-Object { $_.Type -like '*managementGroups*' } |
                    Select-Object -ExpandProperty Name)
                $MgList.Add(@{
                        Id = $CurrentMG.Name
                        DisplayName = $CurrentMG.DisplayName
                        ParentId = $Item.ParentId
                        Subscriptions = $DirectSubs
                        ChildMgIds = $ChildMgIds
                    })
                foreach ($MgChild in $CurrentMG.Children) {
                    if ($MgChild.Type -like '*managementGroups*') {
                        $MgQueue.Enqueue(@{ MG = $MgChild; ParentId = $CurrentMG.Name })
                    }
                }
            }

            # Pass 2: propagate "has subscriptions in subtree" from leaves to root.
            # Reverse BFS order guarantees children are processed before their parents.
            $HasSubsInSubtree = [System.Collections.Generic.HashSet[string]]::new()
            for ($i = $MgList.Count - 1; $i -ge 0; $i--) {
                $MgInfo = $MgList[$i]
                $ChildWithSubs = $MgInfo.ChildMgIds | Where-Object { $HasSubsInSubtree.Contains($_) }
                if ($MgInfo.Subscriptions.Count -gt 0 -or $ChildWithSubs) {
                    $null = $HasSubsInSubtree.Add($MgInfo.Id)
                }
            }

            # Build PSGraph content — no outer graph{} wrapper.
            # Each MG is a simple icon node. Subscriptions are SEPARATE collection nodes
            # connected by edges so Graphviz places them at the same rank as sibling child MGs.
            $DiagramGraph = & {
                # MG nodes — all rendered as simple icon + name nodes
                foreach ($MgInfo in $MgList) {
                    if (-not $HasSubsInSubtree.Contains($MgInfo.Id)) { continue }
                    $SafeId = 'MG_' + ($MgInfo.Id -replace '[^a-zA-Z0-9]', '_')
                    Add-HtmlNodeTable `
                        -Name $SafeId `
                        -ImagesObj $ImagesObj `
                        -inputObject @($MgInfo.DisplayName) `
                        -iconType 'MG' `
                        -IconWidth 60 `
                        -IconHeight 60 `
                        -FontColor $FontColor `
                        -CellBackgroundColor $CellBgColor `
                        -NodeObject
                }

                # Subscription collection nodes — one per MG that has direct subscriptions.
                # Kept separate so Graphviz ranks them alongside sibling child MGs.
                foreach ($MgInfo in $MgList) {
                    if (-not $HasSubsInSubtree.Contains($MgInfo.Id)) { continue }
                    if ($MgInfo.Subscriptions.Count -eq 0) { continue }
                    $SubNodeId = 'Sub_' + ($MgInfo.Id -replace '[^a-zA-Z0-9]', '_')
                    $SubLabel = "$($MgInfo.Subscriptions.Count) $($LocalizedData.SubscriptionCount)"
                    Add-HtmlNodeTable `
                        -Name $SubNodeId `
                        -ImagesObj $ImagesObj `
                        -inputObject ([string[]]$MgInfo.Subscriptions) `
                        -iconType 'Blank' `
                        -Subgraph `
                        -SubgraphLabel $SubLabel `
                        -SubgraphIconType 'Sub' `
                        -SubgraphIconWidth 60 `
                        -SubgraphIconHeight 60 `
                        -SubgraphLabelPos 'top' `
                        -ColumnSize 1 `
                        -TableBorderColor $TableBorderColor `
                        -CellBackgroundColor $CellBgColor `
                        -FontColor $FontColor `
                        -NodeObject
                }

                # Edges: MG → parent MG, and MG → its subscription collection node
                foreach ($MgInfo in $MgList) {
                    if (-not $HasSubsInSubtree.Contains($MgInfo.Id)) { continue }
                    $SafeId = 'MG_' + ($MgInfo.Id -replace '[^a-zA-Z0-9]', '_')
                    if ($null -ne $MgInfo.ParentId -and $HasSubsInSubtree.Contains($MgInfo.ParentId)) {
                        $SafeParentId = 'MG_' + ($MgInfo.ParentId -replace '[^a-zA-Z0-9]', '_')
                        Edge $SafeParentId $SafeId @{ color = $EdgeColor; style = 'solid' }
                    }
                    if ($MgInfo.Subscriptions.Count -gt 0) {
                        $SubNodeId = 'Sub_' + ($MgInfo.Id -replace '[^a-zA-Z0-9]', '_')
                        Edge $SafeId $SubNodeId @{ color = $EdgeColor; style = 'solid' }
                    }
                }
            }

            $DiagramResult = New-AbrDiagram `
                -InputObject $DiagramGraph `
                -Format base64 `
                -MainDiagramLabel $LocalizedData.DiagramHeading `
                -IconPath $IconPath `
                -ImagesObj $ImagesObj `
                -MainGraphSize '6.5,9' `
                -Dpi $DiagramDpi `
                -DisableMainDiagramLogo
            if ($DiagramResult) {
                Image -Base64 $DiagramResult -Text $LocalizedData.DiagramAltText -Percent $DiagramPercent
                BlankLine
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}
}
