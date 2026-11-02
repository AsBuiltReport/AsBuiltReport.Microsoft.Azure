function Get-AbrAzVnmNetworkGroup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Virtual Network Manager network group information
    .DESCRIPTION
        Documents the network groups of an Azure Virtual Network Manager and, at InfoLevel 3 and above,
        the static members of each network group, in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $NetworkManagerName,

        [Parameter(
            Position = 1,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String] $ResourceGroupName
    )

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzVnmNetworkGroup
    }

    process {
        Try {
            $AzNetworkGroups = Get-AzNetworkManagerGroup -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Sort-Object Name
            if ($AzNetworkGroups) {
                Write-PScriboMessage ($LocalizedData.Collecting -f $NetworkManagerName)

                # Collect static members once per group so the summary count and the member detail use the same data
                $StaticMemberMap = @{}
                foreach ($AzNetworkGroup in $AzNetworkGroups) {
                    Try {
                        $StaticMemberMap[$AzNetworkGroup.Name] = @(Get-AzNetworkManagerStaticMember -NetworkManagerName $NetworkManagerName -ResourceGroupName $ResourceGroupName -NetworkGroupName $AzNetworkGroup.Name -ErrorAction Stop | Sort-Object Name)
                    } Catch {
                        Write-PScriboMessage -IsWarning ($LocalizedData.StaticMemberError -f $AzNetworkGroup.Name, $_.Exception.Message)
                        $StaticMemberMap[$AzNetworkGroup.Name] = $null
                    }
                }

                $AzNetworkGroupInfo = foreach ($AzNetworkGroup in $AzNetworkGroups) {
                    [PSCustomObject]@{
                        $LocalizedData.Name = $AzNetworkGroup.Name
                        # Network groups created before member types were introduced report no value and contain virtual networks
                        $LocalizedData.MemberType = switch ($AzNetworkGroup.MemberType) {
                            'Subnet' { $LocalizedData.Subnet }
                            default { $LocalizedData.VirtualNetwork }
                        }
                        $LocalizedData.StaticMembers = $(if ($null -eq $StaticMemberMap[$AzNetworkGroup.Name]) {
                            $LocalizedData.Unknown
                        } else {
                            $StaticMemberMap[$AzNetworkGroup.Name].Count
                        })
                        $LocalizedData.Description = $(if ($AzNetworkGroup.Description) {
                            $AzNetworkGroup.Description
                        } else {
                            $LocalizedData.None
                        })
                    }
                }

                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.Heading {
                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeadings) - $NetworkManagerName"
                        List = $false
                        ColumnWidths = 30, 20, 15, 35
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $AzNetworkGroupInfo | Table @TableParams

                    if ($InfoLevel.VirtualNetworkManager -ge 3) {
                        foreach ($AzNetworkGroup in $AzNetworkGroups) {
                            $AzStaticMembers = $StaticMemberMap[$AzNetworkGroup.Name]
                            if ($AzStaticMembers) {
                                $AzStaticMemberInfo = foreach ($AzStaticMember in $AzStaticMembers) {
                                    $ResourceIdParts = $AzStaticMember.ResourceId.split('/')
                                    $MemberSubscriptionId = $ResourceIdParts[2]
                                    [PSCustomObject]@{
                                        # Subnet members are shown as 'vnet/subnet' so the parent virtual network stays visible
                                        $LocalizedData.Member = $(if ($AzStaticMember.ResourceId -match '/subnets/') {
                                            "$($ResourceIdParts[8])/$($ResourceIdParts[10])"
                                        } else {
                                            $ResourceIdParts[-1]
                                        })
                                        $LocalizedData.ResourceGroup = $ResourceIdParts[4]
                                        $LocalizedData.Subscription = $(if ($AzSubscriptionLookup.$MemberSubscriptionId) {
                                            $AzSubscriptionLookup.$MemberSubscriptionId
                                        } else {
                                            $MemberSubscriptionId
                                        })
                                    }
                                }

                                Section -Style NOTOCHeading7 -ExcludeFromTOC "$($AzNetworkGroup.Name)" {
                                    $TableParams = @{
                                        Name = "$($LocalizedData.StaticMemberTableHeading) - $($AzNetworkGroup.Name)"
                                        List = $false
                                        ColumnWidths = 40, 30, 30
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $AzStaticMemberInfo | Sort-Object $LocalizedData.Member | Table @TableParams
                                }
                            }
                        }
                    }
                }
            }
        } Catch {
            Write-PScriboMessage -IsWarning ($LocalizedData.CollectionError -f $NetworkManagerName, $_.Exception.Message)
            Paragraph ($LocalizedData.Unavailable -f $NetworkManagerName)
        }
    }

    end {}
}
