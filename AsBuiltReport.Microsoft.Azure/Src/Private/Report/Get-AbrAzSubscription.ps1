function Get-AbrAzSubscription {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Subscription information
    .DESCRIPTION
        Documents the subscriptions in a tenant. InfoLevel 2 adds a governance summary and tag coverage,
        and InfoLevel 3 adds a list of management locks.
    .NOTES
        Version:        0.3.0
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
                $AzSubscriptionInfo = @()
                $AzGovernanceInfo = @()
                $AzLockInfo = @()
                $AzLockIds = @{}
                $AzTagUsage = @{}
                $TotalResourceCount = 0
                $Count = 1
                foreach ($AzSubscription in $AzSubscriptions) {
                    Write-PscriboMessage ($LocalizedData.Processing -f ($AzSubscription.Name),$Count,($AzSubscriptions.Count))
                    $Count ++
                    $InObj = [Ordered]@{
                        $LocalizedData.Name = $AzSubscription.Name
                        $LocalizedData.SubscriptionID = $AzSubscription.SubscriptionId
                        $LocalizedData.State = $AzSubscription.State
                    }
                    $AzSubscriptionInfo += [pscustomobject]$InObj

                    # Listing every resource can be slow, so InfoLevel 1 does not collect governance data
                    if ($InfoLevel.Subscription -ge 2) {
                        # A subscription that cannot be read shows -- rather than counts of 0, which would be misleading
                        $ResourceGroupCount = '--'
                        $ResourceCount = '--'
                        $TaggedPercent = '--'
                        $LockCount = '--'
                        try {
                            $null = Set-AzContext -Subscription $AzSubscription.Id -Tenant $TenantId -ErrorAction Stop
                            $AzResourceGroups = @(Get-AzResourceGroup -ErrorAction Stop)
                            $AzResources = @(Get-AzResource -ErrorAction Stop)
                            $AzResourceLocks = @(Get-AzResourceLock -ErrorAction Stop)

                            $ResourceGroupCount = $AzResourceGroups.Count
                            $ResourceCount = $AzResources.Count
                            $LockCount = $AzResourceLocks.Count
                            $TotalResourceCount += $AzResources.Count

                            $TaggedResourceCount = 0
                            foreach ($AzResource in $AzResources) {
                                if (-not $AzResource.Tags) { continue }
                                # GetEnumerator is used because a tag named Keys or Count would hide those properties
                                $TagNames = @($AzResource.Tags.GetEnumerator() | ForEach-Object { $_.Key })
                                if ($TagNames.Count -gt 0) { $TaggedResourceCount++ }
                                foreach ($TagName in $TagNames) {
                                    # Azure tag names are not case-sensitive, and neither is this hashtable
                                    $AzTagUsage[$TagName] = [int]$AzTagUsage[$TagName] + 1
                                }
                            }
                            if ($ResourceCount -gt 0) {
                                # Rounded down, so 100% always means that every resource is tagged
                                $TaggedPercent = "{0}%" -f [math]::Floor(100 * $TaggedResourceCount / $ResourceCount)
                            }

                            if ($InfoLevel.Subscription -ge 3) {
                                foreach ($AzResourceLock in $AzResourceLocks) {
                                    if ($AzLockIds.ContainsKey($AzResourceLock.LockId)) { continue }
                                    $AzLockIds[$AzResourceLock.LockId] = $true

                                    # Locks have no scope property, so it is taken from the lock ID
                                    $LockScope = $AzResourceLock.LockId -replace '/providers/Microsoft\.Authorization/locks/[^/]+$', ''
                                    $ScopeType = switch -Regex ($LockScope) {
                                        '^/subscriptions/[^/]+$' { $LocalizedData.Subscription }
                                        '^/subscriptions/[^/]+/resourceGroups/[^/]+$' { $LocalizedData.ResourceGroup }
                                        default { $LocalizedData.Resource }
                                    }
                                    $LockTarget = if ($ScopeType -eq $LocalizedData.Subscription) { $AzSubscription.Name } else { $LockScope.Split('/')[-1] }

                                    $InObj = [Ordered]@{
                                        $LocalizedData.Subscription = $AzSubscription.Name
                                        $LocalizedData.Name = $AzResourceLock.Name
                                        $LocalizedData.Scope = $ScopeType
                                        $LocalizedData.AppliesTo = $LockTarget
                                        $LocalizedData.Level = $AzResourceLock.Properties.Level
                                        $LocalizedData.Notes = if ($AzResourceLock.Properties.Notes) { $AzResourceLock.Properties.Notes } else { '--' }
                                    }
                                    $AzLockInfo += [PSCustomObject]$InObj
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning ($LocalizedData.GovernanceError -f $AzSubscription.Name, $_.Exception.Message)
                        }

                        $InObj = [Ordered]@{
                            $LocalizedData.Subscription = $AzSubscription.Name
                            $LocalizedData.ResourceGroups = $ResourceGroupCount
                            $LocalizedData.Resources = $ResourceCount
                            $LocalizedData.Tagged = $TaggedPercent
                            $LocalizedData.Locks = $LockCount
                        }
                        $AzGovernanceInfo += [PSCustomObject]$InObj
                    }
                }

                # Tag values are not listed, as a tag such as CreatedDate can have a different value on every resource
                $AzTagCoverageInfo = @(
                    foreach ($AzTag in $AzTagUsage.GetEnumerator()) {
                        [PSCustomObject]@{
                            $LocalizedData.Tag = $AzTag.Key
                            $LocalizedData.Resources = $AzTag.Value
                            $LocalizedData.Coverage = "{0}%" -f [math]::Floor(100 * $AzTag.Value / $TotalResourceCount)
                        }
                    }
                ) | Sort-Object -Property @{ Expression = $LocalizedData.Resources; Descending = $true }, $LocalizedData.Tag
                $AzTagCoverageInfo = @($AzTagCoverageInfo)

                if ($Options.ShowSectionInfo) {
                    Paragraph $LocalizedData.SectionInfo
                    BlankLine
                }
                Paragraph ($LocalizedData.ParagraphSummary -f $AzTenant.Name)
                BlankLine

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $($AzTenant.Name)"
                    List = $false
                    ColumnWidths = 35, 50, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzSubscriptionInfo | Table @TableParams

                if ($AzGovernanceInfo) {
                    Section -Style Heading3 $LocalizedData.GovernanceHeading {
                        Paragraph $LocalizedData.GovernanceParagraph
                        BlankLine
                        $TableParams = @{
                            Name = "$($LocalizedData.GovernanceHeading) - $($AzTenant.Name)"
                            List = $false
                            ColumnWidths = 40, 15, 15, 15, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzGovernanceInfo | Sort-Object $LocalizedData.Subscription | Table @TableParams
                    }
                }

                if ($AzTagCoverageInfo) {
                    Section -Style Heading3 $LocalizedData.TagCoverageHeading {
                        Paragraph $LocalizedData.TagCoverageParagraph
                        $TagCoverageLimit = 10
                        if ($AzTagCoverageInfo.Count -gt $TagCoverageLimit) {
                            Paragraph ($LocalizedData.TagCoverageLimit -f $TagCoverageLimit, $AzTagCoverageInfo.Count)
                        }
                        BlankLine
                        $TableParams = @{
                            Name = "$($LocalizedData.TagCoverageHeading) - $($AzTenant.Name)"
                            List = $false
                            ColumnWidths = 50, 25, 25
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzTagCoverageInfo | Select-Object -First $TagCoverageLimit | Table @TableParams
                    }
                }

                if ($AzLockInfo) {
                    Section -Style Heading3 $LocalizedData.LockHeading {
                        Paragraph $LocalizedData.LockParagraph
                        BlankLine
                        $TableParams = @{
                            Name = "$($LocalizedData.LockHeading) - $($AzTenant.Name)"
                            List = $false
                            ColumnWidths = 20, 18, 12, 18, 12, 20
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzLockInfo | Sort-Object $LocalizedData.Subscription, $LocalizedData.Name, $LocalizedData.AppliesTo | Table @TableParams
                    }
                }
            } else {
                Write-PScriboMessage $LocalizedData.NoSubscriptions
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}
