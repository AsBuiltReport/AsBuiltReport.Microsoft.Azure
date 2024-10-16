function Get-AbrAsrProtectedItems {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Site Recovery Protected Items information
    .DESCRIPTION

    .NOTES
        Version:        0.1.1
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
        Write-PScriboMessage "SiteRecovery InfoLevel set at $($InfoLevel.SiteRecovery)."

    }

    process {
        Try {
            if ($InfoLevel.SiteRecovery -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    foreach ($AzRsv in $AzRsvs) {
                        Write-PscriboMessage "Collecting Azure Site Recovery information [$($AzRsv.Name)]."
                        $AsrVaultContext = Set-AzRecoveryServicesAsrVaultContext -Vault $AzRsv -ErrorAction SilentlyContinue
                        $AsrPolicy = Get-AzRecoveryServicesAsrPolicy -ErrorAction SilentlyContinue | Where-Object {$_.ReplicationProvider -eq 'A2A'}
                        $AsrFabrics = Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue
                        if ($AsrPolicy) {
                            Write-PscriboMessage "Collecting Azure Site Recovery Protected Items information."
                            Section -Style Heading4 'Site Recovery' {
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Protected Items' {
                                            Paragraph "The following tables provides information for the Azure Site Recovery protected items within the $($AzSubscription.Name) subscription."
                                            BlankLine
                                            $TableParams = @{
                                                Name = "Site Recovery Protectected Items - $($AzRsv.Name)"
                                                List = $false
                                                Headers = 'Virtual Machine', 'Replication Health', 'State', 'Active Location', 'Target Location', 'Failover Health'
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