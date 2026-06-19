function Get-AbrAzAutomationAccount {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Automation Account information
    .DESCRIPTION
        Documents the configuration of Azure Automation Accounts including runbooks,
        variables, schedules, and credentials.
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
        $LocalizedData = $reportTranslate.GetAbrAzAutomationAccount
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.AutomationAccount)
    }

    process {
        try {
            if ($InfoLevel.AutomationAccount -ge 1) {
                $AzAutomationAccounts = Get-AzAutomationAccount -ErrorAction SilentlyContinue | Sort-Object AutomationAccountName
                if ($AzAutomationAccounts) {
                    # The list API does not populate State; build a lookup from ARM resource properties instead
                    $AzAutoStateMap = @{}
                    $AzAutoResources = Get-AzResource -ResourceType 'Microsoft.Automation/automationAccounts' -ExpandProperties -ErrorAction SilentlyContinue
                    foreach ($AzAutoResource in $AzAutoResources) {
                        $AzAutoStateMap["$($AzAutoResource.ResourceGroupName)|$($AzAutoResource.Name)"] = $AzAutoResource.Properties.state
                    }

                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        $AzAutomationAccountInfo = @()
                        foreach ($AzAutomationAccount in $AzAutomationAccounts) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name           = $AzAutomationAccount.AutomationAccountName
                                $LocalizedData.ResourceGroup  = $AzAutomationAccount.ResourceGroupName
                                $LocalizedData.Location       = $AzLocationLookup."$($AzAutomationAccount.Location)"
                                $LocalizedData.Subscription   = "$($AzSubscriptionLookup.($AzAutomationAccount.SubscriptionId))"
                                $LocalizedData.SubscriptionID = $AzAutomationAccount.SubscriptionId
                                $LocalizedData.State          = $AzAutoStateMap["$($AzAutomationAccount.ResourceGroupName)|$($AzAutomationAccount.AutomationAccountName)"]
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ($null -eq $AzAutomationAccount.Tags -or $AzAutomationAccount.Tags.Count -eq 0) {
                                    $LocalizedData.None
                                } else {
                                    ($AzAutomationAccount.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzAutomationAccountInfo += [PSCustomObject]$InObj
                        }

                        if ($Healthcheck.AutomationAccount.State) {
                            $AzAutomationAccountInfo | Where-Object { $_.$($LocalizedData.State) -ne 'Ok' } | Set-Style -Style Critical -Property $LocalizedData.State
                        }

                        if ($InfoLevel.AutomationAccount -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine
                            foreach ($AzAutoAcctItem in $AzAutomationAccountInfo) {
                                $AcctName = $AzAutoAcctItem.($LocalizedData.Name)
                                $AcctRg   = $AzAutoAcctItem.($LocalizedData.ResourceGroup)
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $AcctName {
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $AcctName"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzAutoAcctItem | Table @TableParams

                                    $AzRunbooks = Get-AzAutomationRunbook -AutomationAccountName $AcctName -ResourceGroupName $AcctRg -ErrorAction SilentlyContinue | Sort-Object Name
                                    if ($AzRunbooks) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.RunbooksHeading {
                                            $RunbookInfo = @()
                                            foreach ($Runbook in $AzRunbooks) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.Name         = $Runbook.Name
                                                    $LocalizedData.RunbookType  = $Runbook.RunbookType
                                                    $LocalizedData.State        = $Runbook.State
                                                    $LocalizedData.LastModified = $Runbook.LastModifiedTime
                                                }
                                                $RunbookInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.RunbooksHeading) - $AcctName"
                                                List         = $false
                                                ColumnWidths = 35, 20, 20, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $RunbookInfo | Table @TableParams
                                        }
                                    }

                                    $AzVariables = Get-AzAutomationVariable -AutomationAccountName $AcctName -ResourceGroupName $AcctRg -ErrorAction SilentlyContinue | Sort-Object Name
                                    if ($AzVariables) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.VariablesHeading {
                                            $VariableInfo = @()
                                            foreach ($Variable in $AzVariables) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.Name        = $Variable.Name
                                                    $LocalizedData.Encrypted   = if ($Variable.Encrypted) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                    $LocalizedData.Description = if ($Variable.Description) { $Variable.Description } else { $LocalizedData.None }
                                                }
                                                $VariableInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.VariablesHeading) - $AcctName"
                                                List         = $false
                                                ColumnWidths = 35, 15, 50
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $VariableInfo | Table @TableParams
                                        }
                                    }

                                    $AzSchedules = Get-AzAutomationSchedule -AutomationAccountName $AcctName -ResourceGroupName $AcctRg -ErrorAction SilentlyContinue | Sort-Object Name
                                    if ($AzSchedules) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SchedulesHeading {
                                            $ScheduleInfo = @()
                                            foreach ($Schedule in $AzSchedules) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.Name      = $Schedule.Name
                                                    $LocalizedData.Enabled   = if ($Schedule.IsEnabled) { $LocalizedData.Yes } else { $LocalizedData.No }
                                                    $LocalizedData.Frequency = $Schedule.Frequency
                                                    $LocalizedData.NextRun   = $Schedule.NextRun
                                                }
                                                $ScheduleInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.SchedulesHeading) - $AcctName"
                                                List         = $false
                                                ColumnWidths = 30, 15, 20, 35
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $ScheduleInfo | Table @TableParams
                                        }
                                    }

                                    $AzCredentials = Get-AzAutomationCredential -AutomationAccountName $AcctName -ResourceGroupName $AcctRg -ErrorAction SilentlyContinue | Sort-Object Name
                                    if ($AzCredentials) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.CredentialsHeading {
                                            $CredentialInfo = @()
                                            foreach ($Credential in $AzCredentials) {
                                                $InObj = [Ordered]@{
                                                    $LocalizedData.Name     = $Credential.Name
                                                    $LocalizedData.UserName = $Credential.UserName
                                                }
                                                $CredentialInfo += [PSCustomObject]$InObj
                                            }
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.CredentialsHeading) - $AcctName"
                                                List         = $false
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $CredentialInfo | Table @TableParams
                                        }
                                    }
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeading) - $($AzSubscription.Name)"
                                List         = $false
                                Columns      = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.State
                                ColumnWidths = 35, 30, 20, 15
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzAutomationAccountInfo | Table @TableParams
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
