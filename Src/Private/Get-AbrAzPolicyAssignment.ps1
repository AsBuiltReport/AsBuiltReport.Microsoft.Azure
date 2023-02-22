function Get-AbrAzPolicyAssignment {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Policy Assignment information
    .DESCRIPTION

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
        Write-PscriboMessage "Collecting Azure Policy Assignment information."
    }

    process {
        $AzPolicyAssignments = Get-AzPolicyAssignment
        if (($InfoLevel.PolicyAssignment -gt 0) -and ($AzPolicyAssignments)) {
            Section -Style Heading4 'Policy Assignments' {
                $AzPolicyAssignmentInfo = @()
                foreach ($AzPolicyAssignment in $AzPolicyAssignments) {
                    $InObj = [Ordered]@{
                        'Name' = $AzPolicyAssignment.Properties.DisplayName
                        'Description' = Switch ($AzPolicyAssignment.Properties.Description) {
                            $null { '--' }
                            default { $AzPolicyAssignment.Properties.Description }
                        }
                        'Scope' = ($AzPolicyAssignment.Properties.Scope).Split('/')[-1]
                        'Location' = Switch ($AzPolicyAssignment.Location) {
                            $null { '--' }
                            default {$AzLocationLookup."$($AzPolicyAssignment.Location)"}
                        }
                        'Excluded Scopes' = Switch ($AzPolicyAssignment.Properties.NotScopes) {
                            $null { '--' }
                            default { ($AzPolicyAssignment.Properties.NotScopes).Split('/')[-1] }
                        }
                    }
                    $AzPolicyAssignmentInfo += [PSCustomObject]$InObj
                }

                Paragraph "The following table summarises the policy assignments within the $($AzSubscription.Name) subscription."
                BlankLine
                $TableParams = @{
                    Name = "Policy Assignments - $($AzSubscription.Name)"
                    List = $false
                    ColumnWidths = 20, 20, 20, 20, 20
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzPolicyAssignmentInfo | Sort-Object Name | Table @TableParams
            }
        }
    }

    end {}

}