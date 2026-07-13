function Get-AbrAzUserAssignedManagedIdentity {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure User Assigned Managed Identity information
    .DESCRIPTION
        Documents the configuration of Azure User Assigned Managed Identities.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param ()

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzUserAssignedManagedIdentity
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.UserAssignedManagedIdentity)
    }

    process {
        try {
            if ($InfoLevel.UserAssignedManagedIdentity -ge 1) {
                $AzUAMIs = Get-AzUserAssignedIdentity -ErrorAction SilentlyContinue | Sort-Object Name
                if ($AzUAMIs) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzUAMIInfo = @()
                        foreach ($AzUAMI in $AzUAMIs) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name           = $AzUAMI.Name
                                $LocalizedData.ResourceGroup  = $AzUAMI.ResourceGroupName
                                $LocalizedData.Location       = $AzLocationLookup."$($AzUAMI.Location)"
                                $LocalizedData.Subscription   = "$($AzSubscriptionLookup.(($AzUAMI.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzUAMI.Id).split('/')[2]
                                $LocalizedData.ClientID       = $AzUAMI.ClientId
                                $LocalizedData.PrincipalID    = $AzUAMI.PrincipalId
                                $LocalizedData.TenantID       = $AzUAMI.TenantId
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzUAMI.Tags -or $AzUAMI.Tags.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzUAMI.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzUAMIInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.UserAssignedManagedIdentity -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine
                            foreach ($AzUAMIItem in $AzUAMIInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $AzUAMIItem.($LocalizedData.Name) {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $($AzUAMIItem.($LocalizedData.Name))"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzUAMIItem | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.ClientID
                                ColumnWidths = 30, 25, 20, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzUAMIInfo | Table @TableParams
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
