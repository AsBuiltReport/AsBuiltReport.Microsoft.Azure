function Get-AbrAzKeyVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Key Vault information
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
        $LocalizedData = $reportTranslate.GetAbrAzKeyVault
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.KeyVault)
    }

    process {
        Try {
            if ($InfoLevel.KeyVault -gt 0) {
                $AzKeyVaults = Get-AzKeyVault | Sort-Object VaultName
                if ($AzKeyVaults) {
                    Write-PscriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }
                        Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                        BlankLine
                        $AzKeyVaultInfo = @()
                        foreach ($AzKeyVault in $AzKeyVaults) {
                            $AzKeyVault = Get-AzKeyVault -Name $AzKeyVault.VaultName
                            $AzKeyVaultResourceAccess = @()
                            if ($AzKeyVault.EnabledForDeployment) {
                                $AzKeyVaultResourceAccess += $LocalizedData.AzureVM
                            }
                            if ($AzKeyVault.EnabledForTemplateDeployment) {
                                $AzKeyVaultResourceAccess += $LocalizedData.AzureRM
                            }
                            if ($AzKeyVault.EnabledForDiskEncryption) {
                                $AzKeyVaultResourceAccess += $LocalizedData.ADE
                            }
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzKeyVault.VaultName
                                $LocalizedData.ResourceGroup = $AzKeyVault.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzKeyVault.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzKeyVault.ResourceId).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzKeyVault.ResourceId).split('/')[2]
                                $LocalizedData.VaultURI = $AzKeyVault.VaultUri
                                $LocalizedData.SkuPricingTier = $AzKeyVault.SKU
                                $LocalizedData.ResourceAccess = if ($AzKeyVaultResourceAccess) {
                                    $AzKeyVaultResourceAccess
                                } else {
                                    $LocalizedData.NoAccessEnabled
                                }
                                $LocalizedData.RBACAuthorization = if ($AzKeyVault.EnableRbacAuthorization) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.SoftDelete = if ($AzKeyVault.EnableSoftDelete) {
                                    ($LocalizedData.EnabledDays -f $AzKeyVault.SoftDeleteRetentionInDays)
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.PurgeProtection = if ($AzKeyVault.EnablePurgeProtection) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                                $LocalizedData.PublicNetworkAccess = if ($AzKeyVault.PublicNetworkAccess) {
                                    $LocalizedData.Enabled
                                } else {
                                    $LocalizedData.Disabled
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzKeyVault.Tags)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzKeyVault.Tags.GetEnumerator() | ForEach-Object { "$($_.Key):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzKeyVaultInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.KeyVault.SoftDelete) {
                            $AzKeyVaultInfo | Where-Object { $_.$($LocalizedData.SoftDelete) -eq $LocalizedData.Disabled } | Set-Style -Style Critical -Property $LocalizedData.SoftDelete
                        }
                        if ($Healthcheck.KeyVault.PurgeProtection) {
                            $AzKeyVaultInfo | Where-Object { $_.$($LocalizedData.PurgeProtection) -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.PurgeProtection
                        }
                        if ($Healthcheck.KeyVault.PublicNetworkAccess) {
                            $AzKeyVaultInfo | Where-Object { $_.$($LocalizedData.PublicNetworkAccess) -eq $LocalizedData.Enabled } | Set-Style -Style Warning -Property $LocalizedData.PublicNetworkAccess
                        }
                        if ($Healthcheck.KeyVault.RBACAuthorization) {
                            $AzKeyVaultInfo | Where-Object { $_.$($LocalizedData.RBACAuthorization) -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.RBACAuthorization
                        }

                        if ($InfoLevel.KeyVault -ge 2) {
                            foreach ($AzKeyVault in $AzKeyVaultInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzKeyVault.Name)" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzKeyVault.Name)"
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
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location
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
            Write-PScriboMessage $($_.Exception.Message)
        }
    }

    end {}
}