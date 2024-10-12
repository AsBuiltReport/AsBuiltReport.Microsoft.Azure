function Get-AbrAzPolicyAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy Assignment information
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
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
        Write-PScriboMessage "Policy Assignments InfoLevel set at $($InfoLevel.Policy.Assignments)."
    }

    process {
        Try {
            if ($InfoLevel.Policy.Assignments -gt 0) {
                Write-PScriboMessage "Collecting Azure Policy Assignment information."
                $AzPolicyAssignments = Get-AzPolicyAssignment | Sort-Object DisplayName
                if ($AzPolicyAssignments) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Assignments' {
                        $AzPolicyDefinitions = Get-AzPolicyDefinition
                        $AzInitiativeDefinitions = Get-AzPolicySetDefinition
                        $AzPolicyAssignmentInfo = @()
                        foreach ($AzPolicyAssignment in $AzPolicyAssignments) {
                            $AzPolicyDefId = $AzPolicyAssignment.PolicyDefinitionId
                            $AzPolicyDef = $AzPolicyDefinitions | Where-Object { $_.Id -eq $AzPolicyDefId }
                            $AzInitiativeDef = $AzInitiativeDefinitions | Where-Object { $_.Id -eq $AzPolicyDefId }
                            $InObj = [Ordered]@{
                                'Name' = $AzPolicyAssignment.DisplayName
                                'Description' = if ($AzPolicyAssignment.Description) {
                                    $AzPolicyAssignment.Description
                                } else {
                                    '--'
                                }
                                'Location' = if ($AzPolicyAssignment.Location) {
                                    $AzLocationLookup."$($AzPolicyAssignment.Location)"
                                } else {
                                    '--'
                                }
                                'Scope' = Switch -Wildcard ($AzPolicyAssignment.Scope) {
                                    "*subscriptions*" { "$($AzSubscriptionLookup.(($AzPolicyAssignment.Scope).split('/')[-1]))" }
                                    default { $AzPolicyAssignment.Scope }
                                }

                                'Excluded Scopes' = Switch -Wildcard ($AzPolicyAssignment.NotScope | Where-Object { $_ -ne $null -and $_ -ne "" }) {
                                    $null { '--' }
                                    "*subscriptions*" {
                                        ($AzPolicyAssignment.NotScope | ForEach-Object {
                                            $SubscriptionId = $_.split('/')[-1]
                                            $AzSubscriptionLookup[$SubscriptionId]
                                        }) -join ', '
                                    }
                                    default { $AzPolicyAssignment.NotScope }
                                }
                                <#
                                'Excluded Scopes' = if ($AzPolicyAssignment.NotScope) {
                                    ($AzPolicyAssignment.NotScope | Where-Object { $_ -ne $null -and $_ -ne "" }) -join ', '
                                } else {
                                    '--'
                                }
                                #>
                                'Definition Type' = if ($AzPolicyDef) {
                                    'Policy'
                                } elseif ($AzInitiativeDef) {
                                    'Initiative'
                                } else {
                                    'Unknown'
                                }
                                'Policy Enforcement' = if ($AzPolicyAssignment.EnforcementMode -eq 'Default') {
                                    'Enforce'
                                } else {
                                    'Do Not Enforce'
                                }
                            }
                            $AzPolicyAssignmentInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.Policy.Assignments -ge 2) {
                            Paragraph "The following sections detail the policy assignments within the $($AzSubscription.Name) subscription."
                            foreach ($AzPolicy in $AzPolicyAssignmentInfo) {
                                Section -Style NOTOCHeading6 -ExcludeFromTOC "$($AzPolicy.Name)" {
                                    $TableParams = @{
                                        Name = "Policy Assignment - $($AzPolicy.Name)"
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
                            Paragraph "The following table summarises the configuration of the policy assignments within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "Policy Assignments - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Scope', 'Definition Type'
                                Headers = 'Name', 'Scope', 'Type'
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
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}