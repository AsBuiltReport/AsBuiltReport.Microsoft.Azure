function Get-AbrAzPolicyAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy Assignment information
    .DESCRIPTION
        Documents Azure Policy assignments. Assignments on resource groups and resources can be
        numerous, so InfoLevel 1 reports them as a count, InfoLevel 2 as a compact table, and
        InfoLevel 3 in full.
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
        $LocalizedData = $reportTranslate.GetAbrAzPolicyAssignment
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Policy.Assignments)
    }

    process {
        Try {
            if ($InfoLevel.Policy.Assignments -gt 0) {
                Write-PScriboMessage $LocalizedData.Collecting
                # Without IncludeDescendent, assignments on resource groups and resources are not returned
                $AzPolicyAssignments = Get-AzPolicyAssignment -IncludeDescendent -ErrorAction Stop | Sort-Object DisplayName
                if ($AzPolicyAssignments) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                        $AzPolicyDefinitions = Get-AzPolicyDefinition
                        $AzInitiativeDefinitions = Get-AzPolicySetDefinition
                        $SubscriptionAssignmentInfo = @()
                        $ResourceAssignmentInfo = @()
                        foreach ($AzPolicyAssignment in $AzPolicyAssignments) {
                            $AzPolicyDefId = $AzPolicyAssignment.PolicyDefinitionId
                            $AzPolicyDef = $AzPolicyDefinitions | Where-Object { $_.Id -eq $AzPolicyDefId }
                            $AzInitiativeDef = $AzInitiativeDefinitions | Where-Object { $_.Id -eq $AzPolicyDefId }
                            $ExcludedScopes = @($AzPolicyAssignment.NotScope | Where-Object { $_ })
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzPolicyAssignment.DisplayName
                                $LocalizedData.Description = $(if ($AzPolicyAssignment.Description) {
                                    $AzPolicyAssignment.Description
                                } else {
                                    '--'
                                })
                                $LocalizedData.Location = $(if ($AzPolicyAssignment.Location) {
                                    $AzLocationLookup."$($AzPolicyAssignment.Location)"
                                } else {
                                    '--'
                                })
                                $LocalizedData.Scope = Resolve-AbrAzPolicyScopeName -Scope $AzPolicyAssignment.Scope
                                $LocalizedData.ExcludedScopes = $(if ($ExcludedScopes) {
                                    ($ExcludedScopes | ForEach-Object { Resolve-AbrAzPolicyScopeName -Scope $_ }) -join ', '
                                } else {
                                    '--'
                                })
                                $LocalizedData.DefinitionType = $(if ($AzPolicyDef) {
                                    $LocalizedData.Policy
                                } elseif ($AzInitiativeDef) {
                                    $LocalizedData.Initiative
                                } else {
                                    $LocalizedData.Unknown
                                })
                                $LocalizedData.PolicyEnforcement = $(if ($AzPolicyAssignment.EnforcementMode -eq 'Default') {
                                    $LocalizedData.Enforce
                                } else {
                                    $LocalizedData.DoNotEnforce
                                })
                            }
                            if ($AzPolicyAssignment.Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
                                $ResourceAssignmentInfo += [PSCustomObject]$InObj
                            } else {
                                $SubscriptionAssignmentInfo += [PSCustomObject]$InObj
                            }
                        }

                        if ($InfoLevel.Policy.Assignments -ge 2) {
                            # InfoLevel 2 keeps resource group and resource assignments out of the per-assignment detail
                            $DetailAssignmentInfo = if ($InfoLevel.Policy.Assignments -ge 3) {
                                @($SubscriptionAssignmentInfo) + @($ResourceAssignmentInfo) | Sort-Object $LocalizedData.Name
                            } else {
                                $SubscriptionAssignmentInfo
                            }
                            if ($DetailAssignmentInfo) {
                                Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                                foreach ($AzPolicy in $DetailAssignmentInfo) {
                                    $AssignmentName = $AzPolicy.($LocalizedData.Name)
                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $AssignmentName {
                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeading) - $AssignmentName"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $AzPolicy | Table @TableParams
                                    }
                                }
                            }
                            if ($InfoLevel.Policy.Assignments -eq 2 -and $ResourceAssignmentInfo) {
                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ResourceAssignmentsHeading {
                                    Paragraph ($LocalizedData.ParagraphResourceAssignments -f $AzSubscription.Name)
                                    BlankLine
                                    $TableParams = @{
                                        Name = "$($LocalizedData.ResourceAssignmentsHeading) - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.Scope, $LocalizedData.DefinitionType
                                        Headers = $LocalizedData.Name, $LocalizedData.Scope, $LocalizedData.Type
                                        ColumnWidths = 55, 30, 15
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $ResourceAssignmentInfo | Table @TableParams
                                }
                            }
                        } else {
                            if ($SubscriptionAssignmentInfo) {
                                Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                                BlankLine
                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                    List = $false
                                    Columns = $LocalizedData.Name, $LocalizedData.Scope, $LocalizedData.DefinitionType
                                    Headers = $LocalizedData.Name, $LocalizedData.Scope, $LocalizedData.Type
                                    ColumnWidths = 55, 30, 15
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $SubscriptionAssignmentInfo | Table @TableParams
                            }
                            if ($ResourceAssignmentInfo) {
                                Paragraph ($LocalizedData.ParagraphResourceAssignmentCount -f @($ResourceAssignmentInfo).Count, $AzSubscription.Name)
                            }
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}
