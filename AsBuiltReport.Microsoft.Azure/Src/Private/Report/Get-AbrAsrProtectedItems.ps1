function Get-AbrAsrProtectedItems {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Site Recovery Protected Items information
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
        $LocalizedData = $reportTranslate.GetAbrAsrProtectedItems
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.SiteRecovery)
    }

    process {
        Try {
            if ($InfoLevel.SiteRecovery -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    foreach ($AzRsv in $AzRsvs) {
                        Write-PscriboMessage ($LocalizedData.Collecting -f $AzRsv.Name)
                        $null = Set-AzRecoveryServicesAsrVaultContext -Vault $AzRsv -ErrorAction SilentlyContinue
                        $AsrPolicy = Get-AzRecoveryServicesAsrPolicy -ErrorAction SilentlyContinue
                        $AsrFabrics = Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue
                        if ($AsrPolicy) {
                            Write-PscriboMessage $LocalizedData.CollectingItems
                            $AllFabricItems = [Ordered]@{}
                            foreach ($AsrFabric in $AsrFabrics) {
                                $AsrContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $AsrFabric -ErrorAction SilentlyContinue
                                $AsrReplicationProtectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $AsrContainer -ErrorAction SilentlyContinue | Sort-Object FriendlyName
                                if ($Healthcheck.SiteRecovery.ReplicationHealth) {
                                    $AsrReplicationProtectedItems | Where-Object { $_.'replicationhealth' -eq 'Critical' } | Set-Style -Style Critical -Property 'replicationhealth'
                                }
                                if ($Healthcheck.SiteRecovery.FailoverHealth) {
                                    $AsrReplicationProtectedItems | Where-Object { $_.'TestFailoverStateDescription' -eq 'Failed' } | Set-Style -Style Critical -Property 'TestFailoverStateDescription'
                                }
                                if ($Healthcheck.SiteRecovery.NoTestFailover) {
                                    $AsrReplicationProtectedItems | Where-Object { $_.'TestFailoverStateDescription' -eq 'None' } | Set-Style -Style Warning -Property 'TestFailoverStateDescription'
                                }
                                $AllFabricItems[$AsrFabric.Name] = $AsrReplicationProtectedItems
                            }
                            Section -Style Heading4 $LocalizedData.SubHeading {
                                if ($InfoLevel.SiteRecovery -ge 2) {
                                    Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                                }
                                foreach ($AsrFabric in $AsrFabrics) {
                                    $AsrReplicationProtectedItems = $AllFabricItems[$AsrFabric.Name]
                                    if ($AsrReplicationProtectedItems) {
                                        if ($InfoLevel.SiteRecovery -ge 2) {
                                            foreach ($Item in $AsrReplicationProtectedItems) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $Item.FriendlyName {
                                                    $InObj = [Ordered]@{
                                                        $LocalizedData.VirtualMachine       = $Item.FriendlyName
                                                        $LocalizedData.ReplicationProvider  = $Item.ReplicationProvider
                                                        $LocalizedData.ReplicationHealth    = $Item.ReplicationHealth
                                                        $LocalizedData.State                = $Item.ProtectionStateDescription
                                                        $LocalizedData.ActiveLocation       = $Item.PrimaryFabricFriendlyName
                                                        $LocalizedData.TargetLocation       = $Item.RecoveryFabricFriendlyName
                                                        $LocalizedData.FailoverHealth       = $Item.TestFailoverStateDescription
                                                    }
                                                    if ($Item.ReplicationProvider -eq 'A2A' -and $Item.ProviderSpecificDetails) {
                                                        $InObj[$LocalizedData.Rpo] = $(
                                                            if ($null -ne $Item.ProviderSpecificDetails.RpoInSeconds) {
                                                                [math]::Round($Item.ProviderSpecificDetails.RpoInSeconds / 60, 1)
                                                            } else {
                                                                $LocalizedData.NotAvailable
                                                            }
                                                        )
                                                        $InObj[$LocalizedData.LastRpoCalculated]     = $Item.ProviderSpecificDetails.LastRpoCalculatedTime
                                                        $InObj[$LocalizedData.LastHeartbeat]         = $Item.ProviderSpecificDetails.LastHeartbeat
                                                        $InObj[$LocalizedData.RecoveryVmSize]        = $Item.ProviderSpecificDetails.RecoveryAzureVMSize
                                                        $InObj[$LocalizedData.RecoveryAvailabilityZone] = Switch ($Item.ProviderSpecificDetails.RecoveryAvailabilityZone) {
                                                            $null   { $LocalizedData.None }
                                                            default { $Item.ProviderSpecificDetails.RecoveryAvailabilityZone }
                                                        }
                                                    }
                                                    $DetailObj = [PSCustomObject]$InObj
                                                    $TableParams = @{
                                                        Name         = "$($LocalizedData.TableHeading) - $($Item.FriendlyName)"
                                                        List         = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $DetailObj | Table @TableParams
                                                }
                                            }
                                        } else {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                                                Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                                                BlankLine
                                                $TableParams = @{
                                                    Name         = "$($LocalizedData.TableHeading) - $($AzRsv.Name)"
                                                    List         = $false
                                                    Headers      = $LocalizedData.VirtualMachine, $LocalizedData.ReplicationHealth, $LocalizedData.State, $LocalizedData.ActiveLocation, $LocalizedData.TargetLocation, $LocalizedData.FailoverHealth
                                                    Columns      = 'friendlyname', 'replicationhealth', 'protectionstatedescription', 'PrimaryFabricFriendlyName', 'RecoveryFabricFriendlyName', 'TestFailoverStateDescription'
                                                    ColumnWidths = 21, 15, 15, 17, 17, 15
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $AsrReplicationProtectedItems | Table @TableParams
                                            }
                                        }
                                    }
                                }
                            }
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
