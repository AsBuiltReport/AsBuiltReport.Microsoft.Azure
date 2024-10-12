function Get-AbrAzKeyVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Key Vault information
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
        Write-PScriboMessage "KeyVault InfoLevel set at $($InfoLevel.KeyVault)."
    }

    process {
        Try {
            if ($InfoLevel.KeyVault -gt 0) {
                $AzKeyVaults = Get-AzKeyVault | Sort-Object VaultName
                if ($AzKeyVaults) {
                    Write-PscriboMessage "Collecting Azure Key Vault information."
                    Section -Style Heading4 'Key Vaults' {
                        if ($Options.ShowSectionInfo) {
                            Paragraph "Azure Key Vault is a key management solution which enables Azure users and applications to securely store and access keys, secrets, and certificates."
                            BlankLine
                        }
                        Paragraph "The following table summarises the configuration of the key vaults within the $($AzSubscription.Name) subscription."
                        BlankLine
                        $AzKeyVaultInfo = @()
                        foreach ($AzKeyVault in $AzKeyVaults) {
                            $AzKeyVault = Get-AzKeyVault -Name $AzKeyVault.VaultName
                            $AzKeyVaultResourceAccess = @()
                            if ($AzKeyVault.EnabledForDeployment) {
                                $AzKeyVaultResourceAccess += 'Azure Virtual Machines for Deployment'
                            }
                            if ($AzKeyVault.EnabledForTemplateDeployment) {
                                $AzKeyVaultResourceAccess += 'Azure Resource Manager for Template Deployment'
                            }
                            if ($AzKeyVault.EnabledForDiskEncryption) {
                                $AzKeyVaultResourceAccess += 'Azure Disk Encryption for Volume Encryption'
                            }
                            $InObj = [Ordered]@{
                                'Name' = $AzKeyVault.VaultName
                                'Resource Group' = $AzKeyVault.ResourceGroupName
                                'Location' = $AzLocationLookup."$($AzKeyVault.Location)"
                                'Subscription' = "$($AzSubscriptionLookup.(($AzKeyVault.ResourceId).split('/')[2]))"
                                'Vault URI' = $AzKeyVault.VaultUri
                                'Sku (Pricing Tier)' = $AzKeyVault.SKU
                                'Resource Access' = if ($AzKeyVaultResourceAccess) {
                                    $AzKeyVaultResourceAccess
                                } else {
                                    'No access enabled'
                                }
                                'RBAC Authorization' = if ($AzKeyVault.EnableRbacAuthorization) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Soft Delete' = if ($AzKeyVault.EnableSoftDelete) {
                                    "Enabled ($($AzKeyVault.SoftDeleteRetentionInDays) days)"
                                } else {
                                    'Disabled'
                                }
                                'Purge Protection' = if ($AzKeyVault.EnablePurgeProtection) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                                'Public Network Access' = if ($AzKeyVault.PublicNetworkAccess) {
                                    'Enabled'
                                } else {
                                    'Disabled'
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj['Tags'] = if ([string]::IsNullOrEmpty($AzKeyVault.Tags)) {
                                    'None'
                                } else {
                                    ($AzKeyVault.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzKeyVaultInfo += [PSCustomObject]$InObj
                        }

                        if ($InfoLevel.KeyVault -ge 2) {
                            foreach ($AzKeyVault in $AzKeyVaultInfo) {
                                Section -Style Heading4 -ExcludeFromTOC "$($AzKeyVault.Name)" {
                                    $TableParams = @{
                                        Name = "Key Vault - $($AzKeyVault.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzKeyVault | Table @TableParams
                                }
                            }
                        } else {
                            $TableParams = @{
                                Name = "Key Vaults - $($AzSubscription.Name)"
                                List = $false
                                Columns = 'Name', 'Resource Group', 'Location'
                                ColumnWidths = 33, 34, 33
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzKeyVaultInfo | Table @TableParams
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