function Get-AbrAzKeyVault {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Key Vault information
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
        Write-PScriboMessage "KeyVault InfoLevel set at $($InfoLevel.KeyVault)."
    }

    process {
        $AzKeyVaults = Get-AzKeyVault | Sort-Object VaultName
        if (($InfoLevel.KeyVault -gt 0) -and ($AzKeyVaults)) {
            Write-PscriboMessage "Collecting Azure Key Vault information."
            Section -Style Heading2 'Key Vaults' {
                Paragraph "The following table summarises the configuration of the key vaults within the $($AzSubscription.Name) subscription."
                BlankLine
                $AzKeyVaultInfo = @()
                foreach ($AzKeyVault in $AzKeyVaults) {
                    $InObj = [Ordered]@{
                        'Name' = $AzKeyVault.VaultName
                        'Resource Group' = $AzKeyVault.ResourceGroupName
                        'Location' = $AzLocationLookup."$($AzKeyVault.Location)"
                        'Subscription' = "$($AzSubscriptionLookup.(($AzKeyVault.ResourceId).split('/')[2]))"
                    }
                    $AzKeyVaultInfo += [PSCustomObject]$InObj
                }

                <#
                ##TODO: More info required use `Get-AzKeyVault -VaultName xxxx` to get more properties
                SKU
                Enabled for  RBAC
                Enabled for Disk Encryption
                Enabled for Template Deployment
                Soft Delete Enabled
                Soft Delete Retention Period (days)
                Purge Protection

                if ($InfoLevel.KeyVault -ge 2) {
                    foreach ($AzKeyVault in $AzKeyVaultInfo) {
                        Section -Style Heading4 "$($AzKeyVault.Name)" {
                            $TableParams = @{
                                Name = "Key Vault - $($AzKeyVault.Name)"
                                List = $true
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzKeyVault | Table @TableParams
                        }
                    }
                } else {
                    #>
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
                #}
            }
        }
    }

    end {}
}