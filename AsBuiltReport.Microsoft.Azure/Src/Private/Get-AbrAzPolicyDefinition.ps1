function Get-AbrAzPolicyDefinition {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy Definition information
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
        $LocalizedData = $reportTranslate.GetAbrAzPolicyDefinition
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Policy.Definitions)
    }

    process {
        Try {
            if ($InfoLevel.Policy.Definitions -gt 0) {
                Write-PScriboMessage $LocalizedData.Collecting
                $AzPolicyDefinitions = Get-AzPolicyDefinition | Sort-Object DisplayName
                $AzInitiativeDefinitions = Get-AzPolicySetDefinition | Sort-Object DisplayName
                if ($AzPolicyDefinitions -or $AzInitiativeDefinitions) {
                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                        $AzPolicyDefinitionInfo = @()
                        foreach ($Definition in $AzInitiativeDefinitions) {
                            $InObj = [ordered]@{
                                $LocalizedData.Name = $Definition.DisplayName
                                $LocalizedData.Version = $Definition.Version
                                $LocalizedData.Policies = $Definition.PolicyDefinition.count
                                $LocalizedData.Type = $Definition.PolicyType
                                $LocalizedData.DefinitionType = 'Initiative'
                                $LocalizedData.Category = $(if ($Definition.Metadata.Category) {
                                    $Definition.Metadata.Category
                                } else {
                                    '--'
                                })
                            }
                            $AzPolicyDefinitionInfo += [pscustomobject]$InObj
                        }
                        foreach ($Definition in $AzPolicyDefinitions) {
                            $InObj = [ordered]@{
                                $LocalizedData.Name = $Definition.DisplayName
                                $LocalizedData.Version = $Definition.Version
                                $LocalizedData.Policies = $Definition.PolicyDefinition.count
                                $LocalizedData.Type = $Definition.PolicyType
                                $LocalizedData.DefinitionType = 'Policy'
                                $LocalizedData.Category = $(if ($Definition.Metadata.Category) {
                                    $Definition.Metadata.Category
                                } else {
                                    '--'
                                })
                            }
                            $AzPolicyDefinitionInfo += [pscustomobject]$InObj
                        }

                        Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                        BlankLine
                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                            List = $false
                            ColumnWidths = 40, 10, 10, 12, 12, 16
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $AzPolicyDefinitionInfo | Sort-Object $LocalizedData.Name | Table @TableParams
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}