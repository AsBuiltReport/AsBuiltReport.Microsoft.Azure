function Get-AbrAzPolicy {
        <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Policy information
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
        $LocalizedData = $reportTranslate.GetAbrAzPolicy
    }

    process {
        Try {
            if ($InfoLevel.Policy.PSObject.Properties.Value -ne 0) {
                Write-PscriboMessage $LocalizedData.Collecting
                Section -Style Heading4 $LocalizedData.Heading {
                    if ($Options.ShowSectionInfo) {
                        Paragraph $LocalizedData.SectionInfo
                    }
                    Get-AbrAzPolicyAssignment
                    Get-AbrAzPolicyDefinition
                }
            } else {
                Write-PScriboMessage $LocalizedData.InfoLevel
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}