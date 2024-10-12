function Get-AbrAzPolicyDefinition {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy Definition information
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
        Write-PScriboMessage "Policy Definitions InfoLevel set at $($InfoLevel.Policy.Definitions)."
    }

    process {
        Try {
            if ($InfoLevel.Policy.Definitions -gt 0) {
                Write-PScriboMessage "Collecting Azure Policy Definition information."
                $AzPolicyDefinitions = Get-AzPolicyDefinition | Sort-Object DisplayName
                $AzInitiativeDefinitions = Get-AzPolicySetDefinition | Sort-Object DisplayName
                if ($AzPolicyDefinitions -or $AzInitiativeDefinitions) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Definitions' {
                        $AzPolicyDefinitionInfo = @()
                        foreach ($Definition in $AzInitiativeDefinitions) {
                            $InObj = [ordered]@{
                                'Name' = $Definition.DisplayName
                                'Version' = $Definition.Version
                                'Policies' = $Definition.PolicyDefinition.count
                                'Type' = $Definition.PolicyType
                                'Definition Type' = 'Initiative'
                                'Category' = if ($Definition.Metadata.Category) {
                                    $Definition.Metadata.Category
                                } else {
                                    '--'
                                }
                            }
                            $AzPolicyDefinitionInfo += [pscustomobject]$InObj
                        }
                        foreach ($Definition in $AzPolicyDefinitions) {
                            $InObj = [ordered]@{
                                'Name' = $Definition.DisplayName
                                'Version' = $Definition.Version
                                'Policies' = $Definition.PolicyDefinition.count
                                'Type' = $Definition.PolicyType
                                'Definition Type' = 'Policy'
                                'Category' = if ($Definition.Metadata.Category) {
                                    $Definition.Metadata.Category
                                } else {
                                    '--'
                                }
                            }
                            $AzPolicyDefinitionInfo += [pscustomobject]$InObj
                        }

                        Paragraph "The following table summarises the policy definitions within the $($AzSubscription.Name) subscription."
                        BlankLine
                        $TableParams = @{
                            Name = "Policy Definitions - $($AzSubscription.Name)"
                            List = $false
                            ColumnWidths = 40, 10, 10, 12, 12, 16
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzPolicyDefinitionInfo | Sort-Object Name | Table @TableParams
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}