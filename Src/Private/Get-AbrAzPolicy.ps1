function Get-AbrAzPolicy {
        <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy information
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

    begin {}

    process {
        Try {
            if ($InfoLevel.Policy.PSObject.Properties.Value -ne 0) {
                Write-PscriboMessage "Collecting Azure Policy information."
                Section -Style Heading4 'Policy' {
                    if ($Options.ShowSectionInfo) {
                        Paragraph "Azure Policy helps to enforce organisational standards and to assess compliance at-scale. Through its compliance dashboard, it provides an aggregated view to evaluate the overall state of the environment, with the ability to drill down to the per-resource, per-policy granularity. It also helps to bring your resources to compliance through bulk remediation for existing resources and automatic remediation for new resources."
                    }
                    Get-AbrAzPolicyAssignment
                    Get-AbrAzPolicyDefinition
                }
            } else {
                Write-PScriboMessage "Policy InfoLevel set at 0."
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}