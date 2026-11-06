function Get-AbrAzRoleAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure role assignment and custom role information
    .DESCRIPTION
        Documents role assignments and custom roles. Principals must never be reported,
        so assignments are shown as counts by role, principal type and scope. Assignments on resource
        groups and resources can be numerous, so InfoLevel 2 reports them as a count, and InfoLevel 3
        lists them.
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
        $LocalizedData = $reportTranslate.GetAbrAzRoleAssignment
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.RoleAssignment.Assignments, $InfoLevel.RoleAssignment.CustomRoles)
    }

    process {
        Try {
            $AssignmentLevel = [int]$InfoLevel.RoleAssignment.Assignments
            $CustomRoleLevel = [int]$InfoLevel.RoleAssignment.CustomRoles
            if (($AssignmentLevel -gt 0) -or ($CustomRoleLevel -gt 0)) {
                Write-PScriboMessage $LocalizedData.Collecting

                $AzRoleAssignments = @()
                if ($AssignmentLevel -gt 0) {
                    try {
                        # Only these properties are kept, so that a principal's identity cannot reach the report
                        $AzRoleAssignments = @(Get-AzRoleAssignment -ErrorAction Stop | Select-Object -Property RoleDefinitionName, ObjectType, Scope)
                    } catch {
                        # The exception message is left out, as it could identify a principal
                        Write-PScriboMessage -IsWarning ($LocalizedData.AssignmentsError -f $AzSubscription.Name)
                    }
                }

                $AzCustomRoles = @()
                if ($CustomRoleLevel -gt 0) {
                    try {
                        # Az 16 warns on every call that Actions is moving to Permissions, which is already handled below
                        $AzCustomRoles = @(Get-AzRoleDefinition -Custom -WarningAction SilentlyContinue -ErrorAction Stop | Sort-Object -Property Name)
                    } catch {
                        Write-PScriboMessage -IsWarning ($LocalizedData.CustomRolesError -f $AzSubscription.Name, $_.Exception.Message)
                    }
                }

                $AssignmentRows = @(
                    foreach ($AzRoleAssignment in $AzRoleAssignments) {
                        $PrincipalType = switch ($AzRoleAssignment.ObjectType) {
                            'User' { $LocalizedData.User }
                            'Group' { $LocalizedData.Group }
                            'ServicePrincipal' { $LocalizedData.ServicePrincipal }
                            default { $LocalizedData.Other }
                        }
                        [PSCustomObject]@{
                            Role = if ($AzRoleAssignment.RoleDefinitionName) { $AzRoleAssignment.RoleDefinitionName } else { $LocalizedData.Unknown }
                            Type = $PrincipalType
                            Scope = Resolve-AbrAzRoleScopeName -Scope $AzRoleAssignment.Scope
                            IsLowerScope = $AzRoleAssignment.Scope -match '^/subscriptions/[^/]+/resourceGroups/'
                        }
                    }
                )

                $UnknownCount = @($AzRoleAssignments | Where-Object { $_.ObjectType -eq 'Unknown' }).Count
                if ($UnknownCount -gt 0) {
                    Write-PScriboMessage -IsWarning ($LocalizedData.UnknownPrincipals -f $UnknownCount, $AzSubscription.Name)
                }

                $AssignmentSummaryInfo = @(
                    foreach ($RoleGroup in @($AssignmentRows | Group-Object -Property Role)) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Role = $RoleGroup.Name
                            $LocalizedData.Users = @($RoleGroup.Group | Where-Object { $_.Type -eq $LocalizedData.User }).Count
                            $LocalizedData.Groups = @($RoleGroup.Group | Where-Object { $_.Type -eq $LocalizedData.Group }).Count
                            $LocalizedData.ServicePrincipals = @($RoleGroup.Group | Where-Object { $_.Type -eq $LocalizedData.ServicePrincipal }).Count
                            $LocalizedData.Other = @($RoleGroup.Group | Where-Object { $_.Type -eq $LocalizedData.Other }).Count
                            $LocalizedData.Total = @($RoleGroup.Group).Count
                        }
                        [PSCustomObject]$InObj
                    }
                ) | Sort-Object -Property @{ Expression = $LocalizedData.Total; Descending = $true }, $LocalizedData.Role

                # InfoLevel 2 keeps assignments on resource groups and resources out of the table
                $DetailRows = @(if ($AssignmentLevel -ge 3) { $AssignmentRows } else { $AssignmentRows | Where-Object { -not $_.IsLowerScope } })
                $LowerScopeCount = @($AssignmentRows | Where-Object { $_.IsLowerScope }).Count
                # With no principal column, identical rows are shown once with a count
                $AssignmentDetailInfo = @(
                    foreach ($DetailGroup in @($DetailRows | Group-Object -Property Role, Type, Scope)) {
                        $InObj = [Ordered]@{
                            $LocalizedData.Role = $DetailGroup.Group[0].Role
                            $LocalizedData.Type = $DetailGroup.Group[0].Type
                            $LocalizedData.Scope = $DetailGroup.Group[0].Scope
                            $LocalizedData.AssignmentCount = @($DetailGroup.Group).Count
                        }
                        [PSCustomObject]$InObj
                    }
                ) | Sort-Object -Property $LocalizedData.Role, $LocalizedData.Type, $LocalizedData.Scope

                $CustomRoleSummaryInfo = @()
                $CustomRoleDetailInfo = @()
                foreach ($AzCustomRole in $AzCustomRoles) {
                    # Az 16 holds actions in Permissions, and older versions hold them on the role itself
                    $RolePermissions = if ($AzCustomRole.Permissions) { @($AzCustomRole.Permissions) } else { @($AzCustomRole) }
                    $Actions = @($RolePermissions | ForEach-Object { $_.Actions } | Where-Object { $_ })
                    $NotActions = @($RolePermissions | ForEach-Object { $_.NotActions } | Where-Object { $_ })
                    $DataActions = @($RolePermissions | ForEach-Object { $_.DataActions } | Where-Object { $_ })
                    $NotDataActions = @($RolePermissions | ForEach-Object { $_.NotDataActions } | Where-Object { $_ })
                    $AssignableScopes = @($AzCustomRole.AssignableScopes | Where-Object { $_ })
                    $RoleDescription = if ($AzCustomRole.Description) { $AzCustomRole.Description } else { '--' }

                    $InObj = [Ordered]@{
                        $LocalizedData.Name = $AzCustomRole.Name
                        $LocalizedData.Description = $RoleDescription
                        $LocalizedData.AssignableScopes = $AssignableScopes.Count
                        $LocalizedData.Actions = $Actions.Count + $DataActions.Count
                    }
                    $CustomRoleSummaryInfo += [PSCustomObject]$InObj

                    $InObj = [Ordered]@{
                        $LocalizedData.Name = $AzCustomRole.Name
                        $LocalizedData.Description = $RoleDescription
                        $LocalizedData.AssignableScopes = if ($AssignableScopes) { ($AssignableScopes | ForEach-Object { Resolve-AbrAzRoleScopeName -Scope $_ }) -join ', ' } else { '--' }
                        $LocalizedData.Actions = if ($Actions) { $Actions -join ', ' } else { '--' }
                        $LocalizedData.NotActions = if ($NotActions) { $NotActions -join ', ' } else { '--' }
                        $LocalizedData.DataActions = if ($DataActions) { $DataActions -join ', ' } else { '--' }
                        $LocalizedData.NotDataActions = if ($NotDataActions) { $NotDataActions -join ', ' } else { '--' }
                    }
                    $CustomRoleDetailInfo += [PSCustomObject]$InObj
                }

                if ($AssignmentRows -or $CustomRoleSummaryInfo) {
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        if ($AssignmentRows) {
                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.AssignmentsHeading {
                                Paragraph ($LocalizedData.ParagraphAssignments -f $AzSubscription.Name)
                                BlankLine
                                $TableParams = @{
                                    Name = "$($LocalizedData.AssignmentsHeading) - $($AzSubscription.Name)"
                                    List = $false
                                    ColumnWidths = 35, 12, 12, 17, 12, 12
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AssignmentSummaryInfo | Table @TableParams

                                if ($AssignmentLevel -ge 2) {
                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AssignmentDetailHeading {
                                        if ($AssignmentDetailInfo) {
                                            Paragraph ($(if ($AssignmentLevel -ge 3) { $LocalizedData.ParagraphDetailAll } else { $LocalizedData.ParagraphDetailUpper }) -f $AzSubscription.Name)
                                            BlankLine
                                            $TableParams = @{
                                                Name = "$($LocalizedData.AssignmentDetailHeading) - $($AzSubscription.Name)"
                                                List = $false
                                                ColumnWidths = 32, 18, 35, 15
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $AssignmentDetailInfo | Table @TableParams
                                        }
                                        if (($AssignmentLevel -eq 2) -and ($LowerScopeCount -gt 0)) {
                                            BlankLine
                                            Paragraph ($LocalizedData.ParagraphLowerScopeCount -f $LowerScopeCount)
                                        }
                                    }
                                }
                            }
                        }

                        if ($CustomRoleSummaryInfo) {
                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.CustomRolesHeading {
                                Paragraph ($LocalizedData.ParagraphCustomRoles -f $AzSubscription.Name)
                                BlankLine
                                $TableParams = @{
                                    Name = "$($LocalizedData.CustomRolesHeading) - $($AzSubscription.Name)"
                                    List = $false
                                    ColumnWidths = 30, 40, 15, 15
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $CustomRoleSummaryInfo | Table @TableParams

                                if ($CustomRoleLevel -ge 2) {
                                    foreach ($CustomRoleDetail in $CustomRoleDetailInfo) {
                                        $CustomRoleName = $CustomRoleDetail.($LocalizedData.Name)
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $CustomRoleName {
                                            $TableParams = @{
                                                Name = "$($LocalizedData.CustomRoleTableHeading) - $CustomRoleName"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $CustomRoleDetail | Table @TableParams
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } Catch {
            # The exception message is left out, as it could identify a principal
            Write-PScriboMessage -IsWarning ($LocalizedData.AssignmentsError -f $AzSubscription.Name)
        }
    }

    end {}
}
