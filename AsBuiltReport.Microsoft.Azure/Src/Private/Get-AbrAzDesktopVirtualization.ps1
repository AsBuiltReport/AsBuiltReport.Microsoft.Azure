function Get-AbrAzDesktopVirtualization {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Desktop information
    .DESCRIPTION
        Documents the configuration of Azure Virtual Desktop including Host Pools,
        Session Hosts, Application Groups, Workspaces, and Scaling Plans.
    .NOTES
        Version:        0.3.0
        Author:         Scott Eno
        Github:         cse-gh
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzDesktopVirtualization
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.DesktopVirtualization)
    }

    process {
        Try {
            if ($InfoLevel.DesktopVirtualization -gt 0) {
                $AzWvdHostPools = Get-AzWvdHostPool | Sort-Object Name
                if ($AzWvdHostPools) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        #region Host Pools
                        Section -Style Heading5 $LocalizedData.HostPoolsHeading {
                            Paragraph ($LocalizedData.HostPoolsSummary -f $AzSubscription.Name)
                            BlankLine

                            $AzHostPoolInfo = @()
                            foreach ($AzHostPool in $AzWvdHostPools) {
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name = $AzHostPool.Name
                                    $LocalizedData.FriendlyName = if ($AzHostPool.FriendlyName) { $AzHostPool.FriendlyName } else { '--' }
                                    $LocalizedData.ResourceGroup = $AzHostPool.Id.Split('/')[4]
                                    $LocalizedData.Location = $AzLocationLookup."$($AzHostPool.Location)"
                                    $LocalizedData.Type = $AzHostPool.HostPoolType
                                    $LocalizedData.LoadBalancer = $AzHostPool.LoadBalancerType
                                    $LocalizedData.MaxSessionLimit = $AzHostPool.MaxSessionLimit
                                    $LocalizedData.StartVMOnConnect = $AzHostPool.StartVMOnConnect
                                    $LocalizedData.ValidationEnvironment = $AzHostPool.ValidationEnvironment
                                }

                                if ($Options.ShowTags) {
                                    $InObj[$LocalizedData.Tags] = if ($null -eq $AzHostPool.Tag -or $AzHostPool.Tag.Count -eq 0) {
                                        $LocalizedData.None
                                    } else {
                                        ($AzHostPool.Tag.Keys | ForEach-Object { "$_`:`t$($AzHostPool.Tag.AdditionalProperties[$_])" }) -join [Environment]::NewLine
                                    }
                                }

                                $AzHostPoolInfo += [PSCustomObject]$InObj
                            }

                            if ($InfoLevel.DesktopVirtualization -ge 2) {
                                # Detailed: one section per host pool with session hosts
                                foreach ($AzHostPool in $AzWvdHostPools) {
                                    $HostPoolDetail = $AzHostPoolInfo | Where-Object { $_.$($LocalizedData.Name) -eq $AzHostPool.Name }
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzHostPool.Name)" {
                                        $TableParams = @{
                                            Name = "Host Pool - $($AzHostPool.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $HostPoolDetail | Table @TableParams

                                        # RDP Properties
                                        if ($AzHostPool.CustomRdpProperty) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.RdpPropertiesHeading {
                                                $RdpProps = $AzHostPool.CustomRdpProperty -split ';' | Where-Object { $_ -ne '' } | Sort-Object
                                                $RdpInfo = @()
                                                foreach ($prop in $RdpProps) {
                                                    $parts = $prop -split ':', 2
                                                    $RdpInfo += [PSCustomObject][Ordered]@{
                                                        $LocalizedData.Property = $parts[0].Trim()
                                                        $LocalizedData.Value = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
                                                    }
                                                }
                                                $TableParams = @{
                                                    Name = "RDP Properties - $($AzHostPool.Name)"
                                                    List = $false
                                                    ColumnWidths = 50, 50
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $RdpInfo | Table @TableParams
                                            }
                                        }

                                        # Agent Update Configuration
                                        if ($AzHostPool.AgentUpdateType) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AgentUpdateHeading {
                                                $AgentInfo = [PSCustomObject][Ordered]@{
                                                    $LocalizedData.UpdateType = $AzHostPool.AgentUpdateType
                                                    $LocalizedData.MaintenanceWindow = if ($AzHostPool.AgentUpdateMaintenanceWindow) {
                                                        ($AzHostPool.AgentUpdateMaintenanceWindow | ConvertFrom-Json | ForEach-Object { "$($_.dayOfWeek) at $($_.hour):00" }) -join ', '
                                                    } else { '--' }
                                                    $LocalizedData.TimeZone = if ($AzHostPool.AgentUpdateMaintenanceWindowTimeZone) { $AzHostPool.AgentUpdateMaintenanceWindowTimeZone } else { '--' }
                                                    $LocalizedData.UseLocalTime = $AzHostPool.AgentUpdateUseSessionHostLocalTime
                                                }
                                                $TableParams = @{
                                                    Name = "Agent Update - $($AzHostPool.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $AgentInfo | Table @TableParams
                                            }
                                        }

                                        # Registration Info (InfoLevel 3+)
                                        if ($InfoLevel.DesktopVirtualization -ge 3) {
                                            $RegInfo = $AzHostPool.RegistrationInfoExpirationTime
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.RegistrationHeading {
                                                $TokenStatus = if ($RegInfo) {
                                                    if ([datetime]$RegInfo -lt (Get-Date)) { $LocalizedData.Expired } else { $LocalizedData.Valid }
                                                } else { $LocalizedData.NoActiveToken }
                                                $RegObj = [PSCustomObject][Ordered]@{
                                                    $LocalizedData.ExpirationTime = if ($RegInfo) { ([datetime]$RegInfo).ToString('yyyy-MM-dd HH:mm') } else { '--' }
                                                    $LocalizedData.TokenStatus = $TokenStatus
                                                }
                                                if ($Healthcheck.DesktopVirtualization.RegistrationExpiry) {
                                                    $RegObj | Where-Object { $_.$($LocalizedData.TokenStatus) -eq $LocalizedData.Expired } | Set-Style -Style Warning -Property $LocalizedData.TokenStatus
                                                }
                                                $TableParams = @{
                                                    Name = "Registration - $($AzHostPool.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $RegObj | Table @TableParams
                                            }
                                        }

                                        # Session Hosts for this Host Pool
                                        $RG = $AzHostPool.Id.Split('/')[4]
                                        $AzSessionHosts = Get-AzWvdSessionHost -ResourceGroupName $RG -HostPoolName $AzHostPool.Name | Sort-Object Name

                                        # Health Check: No Session Hosts
                                        if ($Healthcheck.DesktopVirtualization.NoSessionHosts) {
                                            if (-not $AzSessionHosts -or $AzSessionHosts.Count -eq 0) {
                                                Paragraph ($LocalizedData.WarningNoSessionHosts -f $AzHostPool.Name) -Bold
                                            }
                                        }

                                        # Health Check: Host Pool at Capacity
                                        if ($Healthcheck.DesktopVirtualization.HostPoolCapacity -and $AzSessionHosts) {
                                            $TotalSessions = ($AzSessionHosts | Measure-Object -Property Session -Sum).Sum
                                            $MaxCapacity = $AzHostPool.MaxSessionLimit * $AzSessionHosts.Count
                                            if ($MaxCapacity -gt 0 -and $TotalSessions -ge $MaxCapacity) {
                                                Paragraph ($LocalizedData.WarningAtCapacity -f $AzHostPool.Name, $TotalSessions, $MaxCapacity) -Bold
                                            }
                                        }

                                        if ($AzSessionHosts) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SessionHostsHeading {
                                                $SessionHostInfo = @()
                                                foreach ($SH in $AzSessionHosts) {
                                                    $ShName = ($SH.Name.Split('/')[-1] -split '\.')[0]
                                                    $InObj = [Ordered]@{
                                                        $LocalizedData.Name = $ShName
                                                        $LocalizedData.Status = $SH.Status
                                                        $LocalizedData.HealthCheck = if ($SH.HealthCheckResult) {
                                                            $checks = $SH.HealthCheckResult | ConvertFrom-Json -ErrorAction SilentlyContinue
                                                            if ($checks) {
                                                                $failed = $checks | Where-Object { $_.healthCheckResult -ne 'HealthCheckSucceeded' }
                                                                if ($failed) {
                                                                    ($failed | ForEach-Object { $_.healthCheckName }) -join ', '
                                                                } else {
                                                                    $LocalizedData.Healthy
                                                                }
                                                            } else { '--' }
                                                        } else { '--' }
                                                        $LocalizedData.Sessions = $SH.Session
                                                        $LocalizedData.AllowNewSessions = $SH.AllowNewSession
                                                        $LocalizedData.OSVersion = if ($SH.OSVersion) { $SH.OSVersion } else { '--' }
                                                        $LocalizedData.AgentVersion = if ($SH.AgentVersion) { $SH.AgentVersion } else { '--' }
                                                        $LocalizedData.LastHeartbeat = if ($SH.LastHeartBeat) { $SH.LastHeartBeat.ToString('yyyy-MM-dd HH:mm') } else { '--' }
                                                        $LocalizedData.UpdateState = if ($SH.UpdateState) { $SH.UpdateState } else { '--' }
                                                    }

                                                    # Add assigned user for personal host pools
                                                    if ($AzHostPool.HostPoolType -eq 'Personal') {
                                                        $InObj[$LocalizedData.AssignedUser] = if ($SH.AssignedUser) { $SH.AssignedUser } else { $LocalizedData.Unassigned }
                                                    }

                                                    $SessionHostInfo += [PSCustomObject]$InObj
                                                }

                                                # Apply health check styling
                                                if ($Healthcheck.DesktopVirtualization.SessionHostHealth) {
                                                    $SessionHostInfo | Where-Object { $_.$($LocalizedData.Status) -ne 'Available' } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                    $SessionHostInfo | Where-Object { $_.$($LocalizedData.HealthCheck) -ne $LocalizedData.Healthy -and $_.$($LocalizedData.HealthCheck) -ne '--' } | Set-Style -Style Warning -Property $LocalizedData.HealthCheck
                                                }
                                                if ($Healthcheck.DesktopVirtualization.DrainMode) {
                                                    $SessionHostInfo | Where-Object { $_.$($LocalizedData.AllowNewSessions) -eq $false } | Set-Style -Style Info -Property $LocalizedData.AllowNewSessions
                                                }

                                                if ($InfoLevel.DesktopVirtualization -ge 4) {
                                                    # Per-session-host detail sections
                                                    foreach ($SH in $AzSessionHosts) {
                                                        $ShName = ($SH.Name.Split('/')[-1] -split '\.')[0]
                                                        $ShDetail = [Ordered]@{
                                                            $LocalizedData.Name = $ShName
                                                            $LocalizedData.Status = $SH.Status
                                                            $LocalizedData.AllowNewSessions = $SH.AllowNewSession
                                                            $LocalizedData.Sessions = $SH.Session
                                                            $LocalizedData.OSVersion = if ($SH.OSVersion) { $SH.OSVersion } else { '--' }
                                                            $LocalizedData.AgentVersion = if ($SH.AgentVersion) { $SH.AgentVersion } else { '--' }
                                                            $LocalizedData.LastHeartbeat = if ($SH.LastHeartBeat) { $SH.LastHeartBeat.ToString('yyyy-MM-dd HH:mm') } else { '--' }
                                                            $LocalizedData.UpdateState = if ($SH.UpdateState) { $SH.UpdateState } else { '--' }
                                                            $LocalizedData.UpdateError = if ($SH.UpdateErrorMessage) { $SH.UpdateErrorMessage } else { '--' }
                                                            $LocalizedData.VMResourceId = if ($SH.ResourceId) { $SH.ResourceId } else { '--' }
                                                        }
                                                        if ($AzHostPool.HostPoolType -eq 'Personal') {
                                                            $ShDetail[$LocalizedData.AssignedUser] = if ($SH.AssignedUser) { $SH.AssignedUser } else { $LocalizedData.Unassigned }
                                                        }
                                                        # Expanded health checks
                                                        if ($SH.HealthCheckResult) {
                                                            $checks = $SH.HealthCheckResult | ConvertFrom-Json -ErrorAction SilentlyContinue
                                                            if ($checks) {
                                                                $ShDetail[$LocalizedData.HealthChecks] = ($checks | ForEach-Object {
                                                                    "$($_.healthCheckName): $($_.healthCheckResult)"
                                                                }) -join [Environment]::NewLine
                                                            }
                                                        }
                                                        $ShObj = [PSCustomObject]$ShDetail
                                                        if ($Healthcheck.DesktopVirtualization.SessionHostHealth) {
                                                            $ShObj | Where-Object { $_.$($LocalizedData.Status) -ne 'Available' } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                        }
                                                        if ($Healthcheck.DesktopVirtualization.DrainMode) {
                                                            $ShObj | Where-Object { $_.$($LocalizedData.AllowNewSessions) -eq $false } | Set-Style -Style Info -Property $LocalizedData.AllowNewSessions
                                                        }
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "$ShName" {
                                                            $TableParams = @{
                                                                Name = "Session Host - $ShName"
                                                                List = $true
                                                                ColumnWidths = 30, 70
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $ShObj | Table @TableParams
                                                        }
                                                    }
                                                } else {
                                                    $TableParams = @{
                                                        Name = "Session Hosts - $($AzHostPool.Name)"
                                                        List = $false
                                                        Columns = $LocalizedData.Name, $LocalizedData.Status, $LocalizedData.HealthCheck, $LocalizedData.Sessions, $LocalizedData.AllowNewSessions, $LocalizedData.AgentVersion, $LocalizedData.LastHeartbeat
                                                        ColumnWidths = 18, 11, 13, 10, 13, 14, 21
                                                    }
                                                    if ($AzHostPool.HostPoolType -eq 'Personal') {
                                                        $TableParams.Columns = $LocalizedData.Name, $LocalizedData.Status, $LocalizedData.Sessions, $LocalizedData.AssignedUser, $LocalizedData.AgentVersion, $LocalizedData.LastHeartbeat
                                                        $TableParams.ColumnWidths = 16, 12, 10, 24, 16, 22
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $SessionHostInfo | Table @TableParams
                                                }
                                            }
                                        }

                                        # Active User Sessions (InfoLevel 4)
                                        if ($InfoLevel.DesktopVirtualization -ge 4) {
                                            $RG4 = $AzHostPool.Id.Split('/')[4]
                                            $UserSessions = Get-AzWvdUserSession -ResourceGroupName $RG4 -HostPoolName $AzHostPool.Name -ErrorAction SilentlyContinue | Sort-Object Name
                                            if ($UserSessions) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ActiveSessionsHeading {
                                                    $SessionInfo = @()
                                                    foreach ($US in $UserSessions) {
                                                        $SessionInfo += [PSCustomObject][Ordered]@{
                                                            $LocalizedData.User = if ($US.ActiveDirectoryUserName) { $US.ActiveDirectoryUserName } elseif ($US.UserPrincipalName) { $US.UserPrincipalName } else { '--' }
                                                            $LocalizedData.SessionHost = (($US.Name -split '/')[1] -split '\.')[0]
                                                            $LocalizedData.State = if ($US.SessionState) { $US.SessionState } else { '--' }
                                                            $LocalizedData.Application = if ($US.ApplicationType) { $US.ApplicationType } else { '--' }
                                                            $LocalizedData.CreateTime = if ($US.CreateTime) { $US.CreateTime.ToString('yyyy-MM-dd HH:mm') } else { '--' }
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Active Sessions - $($AzHostPool.Name)"
                                                        List = $false
                                                        Columns = $LocalizedData.User, $LocalizedData.SessionHost, $LocalizedData.State, $LocalizedData.Application, $LocalizedData.CreateTime
                                                        ColumnWidths = 25, 25, 15, 15, 20
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $SessionInfo | Table @TableParams
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                # Summary table (InfoLevel 1)
                                $TableParams = @{
                                    Name = "Host Pools - $($AzSubscription.Name)"
                                    List = $false
                                    Columns = $LocalizedData.Name, $LocalizedData.FriendlyName, $LocalizedData.Type, $LocalizedData.LoadBalancer, $LocalizedData.MaxSessionLimit, $LocalizedData.StartVMOnConnect
                                    ColumnWidths = 18, 20, 12, 15, 15, 20
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $AzHostPoolInfo | Table @TableParams
                            }
                        }
                        #endregion Host Pools

                        #region Application Groups
                        $AzAppGroups = Get-AzWvdApplicationGroup | Sort-Object Name
                        if ($AzAppGroups) {
                            Section -Style Heading5 $LocalizedData.ApplicationGroupsHeading {
                                Paragraph ($LocalizedData.AppGroupsSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzAppGroupInfo = @()
                                foreach ($AG in $AzAppGroups) {
                                    $HostPoolName = if ($AG.HostPoolArmPath) { $AG.HostPoolArmPath.Split('/')[-1] } else { '--' }
                                    $WorkspaceName = if ($AG.WorkspaceArmPath) { $AG.WorkspaceArmPath.Split('/')[-1] } else { '--' }
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $AG.Name
                                        $LocalizedData.FriendlyName = if ($AG.FriendlyName) { $AG.FriendlyName } else { '--' }
                                        $LocalizedData.Type = $AG.ApplicationGroupType
                                        $LocalizedData.HostPool = $HostPoolName
                                        $LocalizedData.Workspace = $WorkspaceName
                                        $LocalizedData.ResourceGroup = $AG.ResourceGroupName
                                        $LocalizedData.Location = $AzLocationLookup."$($AG.Location)"
                                    }

                                    if ($Options.ShowTags) {
                                        $InObj[$LocalizedData.Tags] = if ($null -eq $AG.Tag -or $AG.Tag.Count -eq 0) {
                                            $LocalizedData.None
                                        } else {
                                            ($AG.Tag.Keys | ForEach-Object { "$_`:`t$($AG.Tag.AdditionalProperties[$_])" }) -join [Environment]::NewLine
                                        }
                                    }

                                    $AzAppGroupInfo += [PSCustomObject]$InObj
                                }

                                if ($InfoLevel.DesktopVirtualization -ge 3) {
                                    # Per-app-group detail sections with published applications
                                    foreach ($AG in $AzAppGroups) {
                                        $AgDetail = $AzAppGroupInfo | Where-Object { $_.$($LocalizedData.Name) -eq $AG.Name }
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AG.Name)" {
                                            $TableParams = @{
                                                Name = "Application Group - $($AG.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $AgDetail | Table @TableParams

                                            # Published Applications (RemoteApp groups only)
                                            if ($AG.ApplicationGroupType -eq 'RemoteApp') {
                                                $RG = $AG.Id.Split('/')[4]
                                                $Apps = Get-AzWvdApplication -ResourceGroupName $RG -GroupName $AG.Name -ErrorAction SilentlyContinue | Sort-Object Name
                                                if ($Apps) {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.PublishedAppsHeading {
                                                        $AppInfo = @()
                                                        foreach ($App in $Apps) {
                                                            $AppInfo += [PSCustomObject][Ordered]@{
                                                                $LocalizedData.Name = $App.Name.Split('/')[-1]
                                                                $LocalizedData.FriendlyName = if ($App.FriendlyName) { $App.FriendlyName } else { '--' }
                                                                $LocalizedData.FilePath = if ($App.FilePath) { $App.FilePath } else { '--' }
                                                                $LocalizedData.CommandLine = if ($App.CommandLineSetting -eq 'Allow') { if ($App.CommandLineArgument) { $App.CommandLineArgument } else { $LocalizedData.Allowed } } else { $App.CommandLineSetting }
                                                                $LocalizedData.ShowInPortal = $App.ShowInPortal
                                                            }
                                                        }
                                                        $TableParams = @{
                                                            Name = "Applications - $($AG.Name)"
                                                            List = $false
                                                            Columns = $LocalizedData.Name, $LocalizedData.FriendlyName, $LocalizedData.FilePath, $LocalizedData.ShowInPortal
                                                            ColumnWidths = 20, 25, 40, 15
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $AppInfo | Table @TableParams
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    $TableParams = @{
                                        Name = "Application Groups - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.FriendlyName, $LocalizedData.Type, $LocalizedData.HostPool, $LocalizedData.Workspace
                                        ColumnWidths = 25, 20, 15, 20, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzAppGroupInfo | Table @TableParams
                                }
                            }
                        }
                        #endregion Application Groups

                        #region Workspaces
                        $AzWorkspaces = Get-AzWvdWorkspace | Sort-Object Name
                        if ($AzWorkspaces) {
                            Section -Style Heading5 $LocalizedData.WorkspacesHeading {
                                Paragraph ($LocalizedData.WorkspacesSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzWorkspaceInfo = @()
                                foreach ($WS in $AzWorkspaces) {
                                    $AppGroupNames = if ($WS.ApplicationGroupReference) {
                                        ($WS.ApplicationGroupReference | ForEach-Object { $_.Split('/')[-1] }) -join ', '
                                    } else { $LocalizedData.None }

                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $WS.Name
                                        $LocalizedData.FriendlyName = if ($WS.FriendlyName) { $WS.FriendlyName } else { '--' }
                                        $LocalizedData.Description = if ($WS.Description) { $WS.Description } else { '--' }
                                        $LocalizedData.ResourceGroup = $WS.ResourceGroupName
                                        $LocalizedData.Location = $AzLocationLookup."$($WS.Location)"
                                        $LocalizedData.ApplicationGroups = $AppGroupNames
                                        $LocalizedData.PublicNetworkAccess = if ($WS.PublicNetworkAccess) { $WS.PublicNetworkAccess } else { '--' }
                                    }

                                    $AzWorkspaceInfo += [PSCustomObject]$InObj
                                }

                                if ($InfoLevel.DesktopVirtualization -ge 2) {
                                    foreach ($WS in $AzWorkspaceInfo) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($WS.$($LocalizedData.Name))" {
                                            $TableParams = @{
                                                Name = "Workspace - $($WS.$($LocalizedData.Name))"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $WS | Table @TableParams
                                        }
                                    }
                                } else {
                                    $TableParams = @{
                                        Name = "Workspaces - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.FriendlyName, $LocalizedData.ApplicationGroups, $LocalizedData.PublicNetworkAccess
                                        ColumnWidths = 20, 25, 35, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzWorkspaceInfo | Table @TableParams
                                }
                            }
                        }
                        #endregion Workspaces

                        #region Scaling Plans
                        $AzScalingPlans = Get-AzWvdScalingPlan -ErrorAction SilentlyContinue | Sort-Object Name
                        if ($AzScalingPlans) {
                            Section -Style Heading5 $LocalizedData.ScalingPlansHeading {
                                Paragraph ($LocalizedData.ScalingPlansSummary -f $AzSubscription.Name)
                                BlankLine

                                $AzScalingPlanInfo = @()
                                foreach ($SP in $AzScalingPlans) {
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name = $SP.Name
                                        $LocalizedData.FriendlyName = if ($SP.FriendlyName) { $SP.FriendlyName } else { '--' }
                                        $LocalizedData.ResourceGroup = $SP.ResourceGroupName
                                        $LocalizedData.Location = $AzLocationLookup."$($SP.Location)"
                                        $LocalizedData.TimeZone = if ($SP.TimeZone) { $SP.TimeZone } else { '--' }
                                        $LocalizedData.ExclusionTag = if ($SP.ExclusionTag) { $SP.ExclusionTag } else { '--' }
                                        $LocalizedData.HostPoolType = if ($SP.HostPoolType) { $SP.HostPoolType } else { '--' }
                                    }
                                    $AzScalingPlanInfo += [PSCustomObject]$InObj
                                }

                                if ($InfoLevel.DesktopVirtualization -ge 3) {
                                    # Per-plan detail sections with schedule breakdowns
                                    foreach ($SP in $AzScalingPlans) {
                                        $SpDetail = $AzScalingPlanInfo | Where-Object { $_.$($LocalizedData.Name) -eq $SP.Name }
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($SP.Name)" {
                                            # Host pool assignments
                                            if ($SP.HostPoolReference) {
                                                $SpDetail | Add-Member -NotePropertyName $LocalizedData.HostPoolAssignments -NotePropertyValue (
                                                    ($SP.HostPoolReference | ForEach-Object { $_.HostPoolArmPath.Split('/')[-1] }) -join ', '
                                                ) -Force
                                            }
                                            $TableParams = @{
                                                Name = "Scaling Plan - $($SP.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $SpDetail | Table @TableParams

                                            # Schedules
                                            if ($SP.Schedule) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SchedulesHeading {
                                                    $SchedInfo = @()
                                                    foreach ($Sched in $SP.Schedule) {
                                                        $SchedInfo += [PSCustomObject][Ordered]@{
                                                            $LocalizedData.Name = $Sched.Name
                                                            $LocalizedData.Days = if ($Sched.DaysOfWeek) { ($Sched.DaysOfWeek | ForEach-Object { $_.ToString().Substring(0,3) }) -join ', ' } else { '--' }
                                                            $LocalizedData.RampUpStart = if ($Sched.RampUpStartTime) { "$($Sched.RampUpStartTime.Hour.ToString('00')):$($Sched.RampUpStartTime.Minute.ToString('00'))" } else { '--' }
                                                            $LocalizedData.PeakStart = if ($Sched.PeakStartTime) { "$($Sched.PeakStartTime.Hour.ToString('00')):$($Sched.PeakStartTime.Minute.ToString('00'))" } else { '--' }
                                                            $LocalizedData.RampDownStart = if ($Sched.RampDownStartTime) { "$($Sched.RampDownStartTime.Hour.ToString('00')):$($Sched.RampDownStartTime.Minute.ToString('00'))" } else { '--' }
                                                            $LocalizedData.OffPeakStart = if ($Sched.OffPeakStartTime) { "$($Sched.OffPeakStartTime.Hour.ToString('00')):$($Sched.OffPeakStartTime.Minute.ToString('00'))" } else { '--' }
                                                            $LocalizedData.RampUpAction = if ($Sched.RampUpLoadBalancingAlgorithm) { $Sched.RampUpLoadBalancingAlgorithm } else { '--' }
                                                            $LocalizedData.RampUpMinPct = if ($null -ne $Sched.RampUpMinimumHostsPct) { "$($Sched.RampUpMinimumHostsPct)%" } else { '--' }
                                                            $LocalizedData.RampUpCapacityPct = if ($null -ne $Sched.RampUpCapacityThresholdPct) { "$($Sched.RampUpCapacityThresholdPct)%" } else { '--' }
                                                            $LocalizedData.RampDownAction = if ($Sched.RampDownLoadBalancingAlgorithm) { $Sched.RampDownLoadBalancingAlgorithm } else { '--' }
                                                            $LocalizedData.RampDownMinPct = if ($null -ne $Sched.RampDownMinimumHostsPct) { "$($Sched.RampDownMinimumHostsPct)%" } else { '--' }
                                                            $LocalizedData.RampDownCapacityPct = if ($null -ne $Sched.RampDownCapacityThresholdPct) { "$($Sched.RampDownCapacityThresholdPct)%" } else { '--' }
                                                            $LocalizedData.OffPeakAction = if ($Sched.OffPeakLoadBalancingAlgorithm) { $Sched.OffPeakLoadBalancingAlgorithm } else { '--' }
                                                        }
                                                    }
                                                    foreach ($S in $SchedInfo) {
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "$($S.$($LocalizedData.Name))" {
                                                            $TableParams = @{
                                                                Name = "Schedule - $($S.$($LocalizedData.Name))"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $S | Table @TableParams
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    $TableParams = @{
                                        Name = "Scaling Plans - $($AzSubscription.Name)"
                                        List = $false
                                        Columns = $LocalizedData.Name, $LocalizedData.FriendlyName, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.TimeZone
                                        ColumnWidths = 20, 20, 20, 20, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzScalingPlanInfo | Table @TableParams
                                }
                            }
                        }
                        #endregion Scaling Plans
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}
