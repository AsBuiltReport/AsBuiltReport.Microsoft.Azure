function Get-AbrAzRecoveryServicesVault {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Recovery Services Vault information
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

    begin {
        Write-PScriboMessage "RecoveryServicesVault InfoLevel set at $($InfoLevel.RecoveryServicesVault)."
    }

    process {
        $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
        if (($InfoLevel.RecoveryServicesVault -gt 0) -and ($AzRsvs)) {
            Write-PscriboMessage "Collecting Azure Recovery Services Vault information."
            Section -Style Heading3 'Recovery Services Vaults' {
                $AzRsvInfo = @()
                foreach ($AzRsv in $AzRsvs) {
                    $InObj = [Ordered]@{
                        'Name' = $AzRsv.Name
                        'Resource Group' = $AzRsv.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzRsv.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzRsv.Id).split('/')[2]))"
                        'Provisioning State' = $AzRsv.Properties.ProvisioningState
                        'Private Endpoint State for Backup' = $AzRsv.Properties.PrivateEndpointStateForBackup
                        'Private Endpoint State for Site Recovery' = $AzRsv.Properties.PrivateEndpointStateForSiteRecovery
                    }
                    $AzRsvInfo += [PSCustomObject]$InObj
                }

                if ($InfoLevel.RecoveryServicesVault -ge 2) {
                    Paragraph "The following sections detail the configuration of the recovery services vault within the $($AzSubscription.Name) subscription."
                    foreach ($AzRsv in $AzRsvInfo) {
                        Section -Style Heading4 "$($AzRsv.Name)" {
                            $TableParams = @{
                                Name = "Recovery Services Vault - $($AzRsv.Name)"
                                List = $true
                                ColumnWidths = 50, 50
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

    end {}
}