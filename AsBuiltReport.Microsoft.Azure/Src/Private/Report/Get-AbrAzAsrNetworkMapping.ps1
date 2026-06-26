function Get-AbrAzAsrNetworkMapping {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Site Recovery Network Mapping information
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
        $LocalizedData = $reportTranslate.GetAbrAzAsrNetworkMapping
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.AsrNetworkMapping)
    }

    process {
        Try {
            if ($InfoLevel.AsrNetworkMapping -gt 0) {
                $AzRsvs = Get-AzRecoveryServicesVault | Sort-Object Name
                if ($AzRsvs) {
                    foreach ($AzRsv in $AzRsvs) {
                        $null = Set-AzRecoveryServicesAsrVaultContext -Vault $AzRsv -ErrorAction SilentlyContinue
                        $AsrFabrics = Get-AzRecoveryServicesAsrFabric -ErrorAction SilentlyContinue
                        $AllNetworkMappings = @()
                        foreach ($Fabric in $AsrFabrics) {
                            $AsrNetworks = Get-AzRecoveryServicesAsrNetwork -Fabric $Fabric -ErrorAction SilentlyContinue
                            foreach ($AsrNetwork in $AsrNetworks) {
                                $Mappings = Get-AzRecoveryServicesAsrNetworkMapping -Fabric $Fabric -Network $AsrNetwork -ErrorAction SilentlyContinue
                                if ($Mappings) { $AllNetworkMappings += $Mappings }
                            }
                        }
                        $AllNetworkMappings = $AllNetworkMappings | Sort-Object Name
                        if ($AllNetworkMappings) {
                            Write-PScriboMessage ($LocalizedData.Collecting -f $AzRsv.Name)
                            Section -Style Heading4 "$($LocalizedData.Heading) - $($AzRsv.Name)" {
                                if ($Options.ShowSectionInfo) {
                                    Paragraph $LocalizedData.SectionInfo
                                    BlankLine
                                }
                                $MappingInfo = @()
                                foreach ($Mapping in $AllNetworkMappings) {
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name            = $Mapping.Name
                                        $LocalizedData.PrimaryNetwork  = Switch ($Mapping.PrimaryNetworkFriendlyName) {
                                            $null   { $LocalizedData.None }
                                            default { $Mapping.PrimaryNetworkFriendlyName }
                                        }
                                        $LocalizedData.RecoveryNetwork = Switch ($Mapping.RecoveryNetworkFriendlyName) {
                                            $null   { $LocalizedData.None }
                                            default { $Mapping.RecoveryNetworkFriendlyName }
                                        }
                                        $LocalizedData.MappingState    = Switch ($Mapping.PairingStatus) {
                                            $null   { $LocalizedData.None }
                                            default { $Mapping.PairingStatus }
                                        }
                                    }
                                    $MappingInfo += [PSCustomObject]$InObj
                                }

                                if ($Healthcheck.AsrNetworkMapping.MappingState) {
                                    $MappingInfo | Where-Object { $_.$($LocalizedData.MappingState) -ne 'Paired' } | Set-Style -Style Warning -Property $LocalizedData.MappingState
                                }

                                if ($InfoLevel.AsrNetworkMapping -ge 2) {
                                    Paragraph ($LocalizedData.ParagraphDetail -f $AzRsv.Name)
                                    foreach ($Mapping in $MappingInfo) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "$($Mapping.($LocalizedData.Name))" {
                                            $TableParams = @{
                                                Name         = "$($LocalizedData.Heading) - $($Mapping.($LocalizedData.Name))"
                                                List         = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $Mapping | Table @TableParams
                                        }
                                    }
                                } else {
                                    Paragraph ($LocalizedData.ParagraphSummary -f $AzRsv.Name)
                                    BlankLine
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeadings) - $($AzRsv.Name)"
                                        List         = $false
                                        Columns      = $LocalizedData.Name, $LocalizedData.PrimaryNetwork, $LocalizedData.RecoveryNetwork, $LocalizedData.MappingState
                                        ColumnWidths = 25, 30, 30, 15
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $MappingInfo | Table @TableParams
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
