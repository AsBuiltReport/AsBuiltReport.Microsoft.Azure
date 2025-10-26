function Get-AbrAzPolicyAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy Assignment information
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
        $LocalizedData = $reportTranslate.GetAbrAzPolicyAssignment
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Policy.Assignments)
    }

    process {
        Try {
            if ($InfoLevel.Policy.Assignments -gt 0) {
                Write-PScriboMessage $LocalizedData.Collecting
                $AzPolicyAssignments = Get-AzPolicyAssignment | Sort-Object DisplayName
                if ($AzPolicyAssignments) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                        $AzPolicyDefinitions = Get-AzPolicyDefinition
                        $AzInitiativeDefinitions = Get-AzPolicySetDefinition
                        $AzPolicyAssignmentInfo = @()
                        foreach ($AzPolicyAssignment in $AzPolicyAssignments) {
                            $AzPolicyDefId = $AzPolicyAssignment.PolicyDefinitionId
                            $AzPolicyDef = $AzPolicyDefinitions | Where-Object { $_.Id -eq $AzPolicyDefId }
                            $AzInitiativeDef = $AzInitiativeDefinitions | Where-Object { $_.Id -eq $AzPolicyDefId }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzPolicyAssignment.DisplayName
                                $LocalizedData.Description = if ($AzPolicyAssignment.Description) {
                                    $AzPolicyAssignment.Description
                                } else {
                                    '--'
                                }
                                $LocalizedData.Location = if ($AzPolicyAssignment.Location) {
                                    $AzLocationLookup."$($AzPolicyAssignment.Location)"
                                } else {
                                    '--'
                                }
                                $LocalizedData.Scope = Switch -Wildcard ($AzPolicyAssignment.Scope) {
                                    "*subscriptions*" { "$($AzSubscriptionLookup.(($AzPolicyAssignment.Scope).split('/')[-1]))" }
                                    default { $AzPolicyAssignment.Scope }
                                }

                                $LocalizedData.ExcludedScopes = Switch -Wildcard ($AzPolicyAssignment.NotScope | Where-Object { $_ -ne $null -and $_ -ne "" }) {
                                    $null { '--' }
                                    "*subscriptions*" {
                                        ($AzPolicyAssignment.NotScope | ForEach-Object {
                                            $SubscriptionId = $_.split('/')[-1]
                                            $AzSubscriptionLookup[$SubscriptionId]
                                        }) -join ', '
                                    }
                                    default { $AzPolicyAssignment.NotScope }
                                }
                                $LocalizedData.DefinitionType = if ($AzPolicyDef) {
                                    $LocalizedData.Policy
                                } elseif ($AzInitiativeDef) {
                                    $LocalizedData.Initiative
                                } else {
                                    $LocalizedData.Unknown
                                }
                                $LocalizedData.PolicyEnforcement = if ($AzPolicyAssignment.EnforcementMode -eq 'Default') {
                                    $LocalizedData.Enforce
                                } else {
                                    $LocalizedData.DoNotEnforce
                                }
                            }
                            $AzPolicyAssignmentInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.Policy.Assignments -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzPolicy in $AzPolicyAssignmentInfo) {
                                Section -Style NOTOCHeading6 -ExcludeFromTOC "$($AzPolicy.Name)" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzPolicy.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzPolicy | Table @TableParams
                                }
                            }
                        } else {
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
                            $AzPolicyAssignmentInfo | Table @TableParams
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}