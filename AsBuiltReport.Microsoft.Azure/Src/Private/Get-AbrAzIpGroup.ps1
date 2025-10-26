function Get-AbrAzIpGroup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure IP Group information
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
        $LocalizedData = $reportTranslate.GetAbrAzIpGroup
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $($InfoLevel.IPGroup))
    }

    process {
        Try {
            if ($InfoLevel.IpGroup -gt 0) {
                $AzIpGroups = Get-AzIpGroup | Sort-Object Name
                if ($AzIpGroups) {
                    Write-PScriboMessage $LocalizedData.Collecting
                    Section -Style Heading4 $LocalizedData.Heading {
                        $AzIpGroupInfo = @()
                        foreach ($AzIpGroup in $AzIpGroups) {
                            $InObj = [Ordered]@{
                                $LocalizedData.Name = $AzIpGroup.Name
                                $LocalizedData.ResourceGroup = $AzIpGroup.ResourceGroupName
                                $LocalizedData.Location = $AzLocationLookup."$($AzIpGroup.Location)"
                                $LocalizedData.Subscription = "$($AzSubscriptionLookup.(($AzIpGroup.Id).split('/')[2]))"
                                $LocalizedData.SubscriptionID = ($AzIpGroup.Id).split('/')[2]
                                $LocalizedData.ProvisioningState = $AzIpGroup.ProvisioningState
                                $LocalizedData.Firewalls = if ($AzIpGroup.Firewalls.id) {
                                    ($AzIpGroup.Firewalls.id | ForEach-Object { $_.split('/')[-1] }) -join ', '
                                } else {
                                    $LocalizedData.None
                                }
                                $LocalizedData.IPAddresses = if ($AzIpGroup.IpAddresses) {
                                    $AzIpGroup.IpAddresses -join ', '
                                } else {
                                    $LocalizedData.None
                                }
                            }

                            if ($Options.ShowTags) {
                                $InObj[$LocalizedData.Tags] = if ([string]::IsNullOrEmpty($AzIpGroup.Tag)) {
                                    $LocalizedData.None
                                } else {
                                    ($AzIpGroup.Tag.GetEnumerator() | ForEach-Object { "$($_.Name):`t$($_.Value)" }) -join [Environment]::NewLine
                                }
                            }

                            $AzIpGroupInfo += [PSCustomObject]$InObj
                        }

                        # Apply health check highlighting
                        if ($Healthcheck.IpGroup.ProvisioningState) {
                            $AzIpGroupInfo | Where-Object { $_.$($LocalizedData.ProvisioningState) -ne 'Succeeded' } | Set-Style -Style Critical -Property $LocalizedData.ProvisioningState
                        }

                        if ($InfoLevel.IPGroup -ge 2) {
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            foreach ($AzIpGroup in $AzIpGroupInfo) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "$($AzIpGroup.Name)" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $($AzIpGroup.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzIpGroup | Table @TableParams
                                }
                            }
                        } else {
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine
                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List = $false
                                Columns = $LocalizedData.Name, $LocalizedData.ResourceGroup, $LocalizedData.Location, $LocalizedData.IPAddresses
                                ColumnWidths = 25, 25, 25, 25
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $AzIpGroupInfo | Table @TableParams
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