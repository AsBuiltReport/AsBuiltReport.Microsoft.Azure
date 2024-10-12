function Get-AbrAzRecoveryServicesVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Recovery Services Vault information
    .DESCRIPTION

    .NOTES
        Version:        0.1.2
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
        Write-PScriboMessage "RecoveryServicesVault InfoLevel set at $($InfoLevel.RecoveryServicesVault)."
    }

    process {
        Try {
            if ($InfoLevel.RecoveryServicesVault -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    Write-PscriboMessage "Collecting Azure Recovery Services Vault information."
                    Section -Style Heading4 'Recovery Services Vaults' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "A Recovery Services vault is a storage entity in Azure that houses data. The data is typically copies of data, or configuration information for virtual machines (VMs), workloads, servers, or workstations. You can use Recovery Services vaults to hold backup data for various Azure services such as IaaS VMs (Linux or Windows) and SQL Server in Azure VMs. Recovery Services vaults support System Center DPM, Windows Server, Azure Backup Server, and more. Recovery Services vaults make it easy to organize your backup data, while minimizing management overhead."
                            BlankLine
                        }
                        $AzRsvInfo = @()
                        foreach ($AzRsv in $AzRsvs) {
                            $InObj = [Ordered]@{
                                'Name' = $AzRsv.Name
                                'Resource Group' = $AzRsv.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzRsv.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzRsv.Id).split('/')[2]))"
                                'Provisioning State' = $AzRsv.Properties.ProvisioningState
                                'Private Endpoint State for Backup' = Switch ($AzRsv.Properties.PrivateEndpointStateForBackup) {
                                    $null { '--' }
                                    default { $AzRsv.Properties.PrivateEndpointStateForBackup }
                                }
                                'Private Endpoint State for Site Recovery' = Switch ($AzRsv.Properties.PrivateEndpointStateForSiteRecovery) {
                                    $null { '--' }
                                    default { $AzRsv.Properties.PrivateEndpointStateForSiteRecovery }
                                }
                            }
                            $AzRsvInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.RecoveryServicesVault -ge 2) {
                            Paragraph "The following sections detail the configuration of the recovery services vault within the $($AzSubscription.Name) subscription."
                            foreach ($AzRsv in $AzRsvInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzRsv.Name)" {
                                    $TableParams = @{
                                        Name = "Recovery Services Vault - $($AzRsv.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzRsv | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph "The following table summarises the configuration of the recovery services vault within the $($AzSubscription.Name) subscription."
                            BlankLine
                            $TableParams = @{
                                Name = "Recovery Services Vaults - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Resource Group', 'Location'
                                ColumnWidths = 33, 34, 33
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzRsvinfo | Table @TableParams
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