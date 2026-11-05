function Get-AbrAzPolicyExemption {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy Exemption information
    .DESCRIPTION
        Documents Azure Policy exemptions including scope, category, expiry and the linked
        policy assignment.
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
        $LocalizedData = $reportTranslate.GetAbrAzPolicyExemption
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Policy.Exemptions)
    }

    process {
        try {
            if ($InfoLevel.Policy.Exemptions -gt 0) {
                Write-PScriboMessage $LocalizedData.Collecting
                # Without IncludeDescendent, exemptions on resource groups and resources are not returned
                $AzPolicyExemptions = Get-AzPolicyExemption -IncludeDescendent -ErrorAction Stop
                if ($AzPolicyExemptions) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                        $AzPolicyAssignmentLookup = @{}
                        $AzPolicyAssignments = Get-AzPolicyAssignment -IncludeDescendent -ErrorAction SilentlyContinue
                        foreach ($AzPolicyAssignment in $AzPolicyAssignments) {
                            $AzPolicyAssignmentLookup[$AzPolicyAssignment.Id] = $AzPolicyAssignment.DisplayName
                        }

                        $AzPolicyExemptionInfo = @()
                        foreach ($AzPolicyExemption in $AzPolicyExemptions) {
                            # Exemptions have no scope property, so it is taken from the resource ID
                            $ExemptionScope = $AzPolicyExemption.Id -replace '/providers/Microsoft\.Authorization/policyExemptions/[^/]+$', ''
                            $ScopeName = $ExemptionScope.Split('/')[-1]
                            $ScopeType = switch -Regex ($ExemptionScope) {
                                '^/providers/Microsoft\.Management/managementGroups/[^/]+$' { $LocalizedData.ManagementGroup }
                                '^/subscriptions/[^/]+$' {
                                    if ($AzSubscriptionLookup[$ScopeName]) { $ScopeName = $AzSubscriptionLookup[$ScopeName] }
                                    $LocalizedData.Subscription
                                }
                                '^/subscriptions/[^/]+/resourceGroups/[^/]+$' { $LocalizedData.ResourceGroup }
                                default { $LocalizedData.Resource }
                            }

                            $AssignmentName = if ($AzPolicyAssignmentLookup[$AzPolicyExemption.PolicyAssignmentId]) {
                                $AzPolicyAssignmentLookup[$AzPolicyExemption.PolicyAssignmentId]
                            } else {
                                $AzPolicyExemption.PolicyAssignmentId.Split('/')[-1]
                            }

                            $InObj = [Ordered]@{
                                $LocalizedData.Name              = if ($AzPolicyExemption.DisplayName) { $AzPolicyExemption.DisplayName } else { $AzPolicyExemption.Name }
                                $LocalizedData.Description       = if ($AzPolicyExemption.Description) { $AzPolicyExemption.Description } else { '--' }
                                $LocalizedData.Scope             = $ScopeName
                                $LocalizedData.ScopeType         = $ScopeType
                                $LocalizedData.Category          = $AzPolicyExemption.ExemptionCategory
                                $LocalizedData.PolicyAssignment  = $AssignmentName
                                $LocalizedData.PolicyDefinitions = if ($AzPolicyExemption.PolicyDefinitionReferenceId) { $AzPolicyExemption.PolicyDefinitionReferenceId -join ', ' } else { $LocalizedData.AllPolicies }
                                $LocalizedData.ExpiresOn         = if ($AzPolicyExemption.ExpiresOn) { $AzPolicyExemption.ExpiresOn.ToUniversalTime().ToString('yyyy-MM-dd') } else { $LocalizedData.NoExpiry }
                                $LocalizedData.Status            = if ($AzPolicyExemption.ExpiresOn -and $AzPolicyExemption.ExpiresOn.ToUniversalTime() -lt [DateTime]::UtcNow) { $LocalizedData.Expired } else { $LocalizedData.Active }
                            }
                            $AzPolicyExemptionInfo += [PSCustomObject]$InObj
                        }
                        $AzPolicyExemptionInfo = $AzPolicyExemptionInfo | Sort-Object $LocalizedData.Name

                        if ($Healthcheck.Policy.ExpiredExemptions) {
                            $AzPolicyExemptionInfo | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Expired } | Set-Style -Style Warning -Property $LocalizedData.ExpiresOn, $LocalizedData.Status
                        }

                        if ($InfoLevel.Policy.Exemptions -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzPolicyExemption in $AzPolicyExemptionInfo) {
                                Section -Style NOTOCHeading6 -ExcludeFromTOC "$($AzPolicyExemption.($LocalizedData.Name))" {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $($AzPolicyExemption.($LocalizedData.Name))"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzPolicyExemption | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.Scope, $LocalizedData.Category, $LocalizedData.PolicyAssignment, $LocalizedData.ExpiresOn, $LocalizedData.Status
                                ColumnWidths = 25, 20, 12, 21, 12, 10
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzPolicyExemptionInfo | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($LocalizedData.ErrorMessage) $($_.Exception.Message)"
        }
    }

    end {}
}
