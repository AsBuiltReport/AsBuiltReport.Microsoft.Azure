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
                        $AsrVaultContext = Set-AzRecoveryServicesAsrVaultContext -Vault $AzRsv -ErrorAction SilentlyContinue
                        $AsrPolicy = Get-AzRecoveryServicesAsrPolicy -ErrorAction SilentlyContinue | Where-Object {$_.ReplicationProvider -eq 'A2A'}
                        $AsrFabrics = Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue
                        if ($AsrPolicy) {
                            Write-PscriboMessage $LocalizedData.CollectingItems
                            Section -Style Heading4 $LocalizedData.SubHeading {
                                foreach ($AsrFabric in $AsrFabrics) {
                                    $AsrContainer = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $AsrFabric -ErrorAction SilentlyContinue
                                    $AsrReplicationProtectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $AsrContainer -ErrorAction SilentlyContinue | Sort-Object FriendlyName
                                    if ($Healthcheck.SiteRecovery.ReplicationHealth) {
                                        $AsrReplicationProtectedItems | Where-Object { $_.'replicationhealth' -eq 'Critical' } | Set-Style -Style Critical -Property 'replicationhealth'
                                    }
                                    if ($Healthcheck.SiteRecovery.FailoverHealth) {
                                        $AsrReplicationProtectedItems | Where-Object { $_.'TestFailoverStateDescription' -ne 'None' } | Set-Style -Style Warning -Property 'TestFailoverStateDescription'
                                    }
                                    if ($AsrReplicationProtectedItems) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Heading {
                                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                                            BlankLine
                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeading) - $($AzRsv.Name)"
                                                List = $false
                                                Headers = $LocalizedData.VirtualMachine, $LocalizedData.ReplicationHealth, $LocalizedData.State, $LocalizedData.ActiveLocation, $LocalizedData.TargetLocation, $LocalizedData.FailoverHealth
                                                Columns = 'friendlyname', 'replicationhealth', 'protectionstatedescription', 'PrimaryFabricFriendlyName', 'RecoveryFabricFriendlyName', 'TestFailoverStateDescription'
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
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}