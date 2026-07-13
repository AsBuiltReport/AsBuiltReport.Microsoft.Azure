function Get-AbrAzNetworkVirtualAppliance {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Network Virtual Appliance information.
    .DESCRIPTION
        Identifies third-party Network Virtual Appliances (NVAs) deployed in an Azure subscription
        by inspecting VM marketplace image publisher metadata and optional resource tags. Renders
        a summary table at InfoLevel 1, per-NVA detail lists at InfoLevel 2, and associated UDR
        route table cross-reference at InfoLevel 3.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param ()

    begin {
        $LocalizedData = $reportTranslate.GetAbrAzNetworkVirtualAppliance
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.NetworkVirtualAppliance)
    }

    process {
        Try {
            if ($InfoLevel.NetworkVirtualAppliance -gt 0) {

                #region --- NVA publisher list ---
                # Default well-known NVA publishers. Overridden by Options.NvaPublishers when set.
                $DefaultNvaPublishers = @(
                    'paloaltonetworks',
                    'fortinet',
                    'cisco',
                    'checkpoint',
                    'f5-networks',
                    'barracudanetworks',
                    'sonicwall-inc',
                    'juniper-networks',
                    'viptela',
                    'riverbed'
                )

                $NvaPublishers = if ($Options.NvaPublishers -and $Options.NvaPublishers.Count -gt 0) {
                    $Options.NvaPublishers
                } else {
                    $DefaultNvaPublishers
                }

                $NvaTagKey   = if ($Options.NvaTag) { ($Options.NvaTag -split '=')[0].Trim() } else { $null }
                $NvaTagValue = if ($Options.NvaTag -and $Options.NvaTag -contains '=') { ($Options.NvaTag -split '=',2)[1].Trim() } else { $null }
                #endregion

                Write-PScriboMessage $LocalizedData.Collecting

                #region --- Collect all VMs and filter to NVAs ---
                $AzVms = Get-AzVM -Status | Sort-Object Name
                $NvaVms = @()

                foreach ($AzVm in $AzVms) {
                    $ImageRef   = $AzVm.StorageProfile.ImageReference
                    $IsNvaByImg = $ImageRef.Publisher -and ($NvaPublishers -contains $ImageRef.Publisher.ToLower())

                    $IsNvaByTag = $false
                    if ($NvaTagKey) {
                        $TagVal = $AzVm.Tags[$NvaTagKey]
                        $IsNvaByTag = if ($NvaTagValue) { $TagVal -eq $NvaTagValue } else { $null -ne $TagVal }
                    }

                    if (-not ($IsNvaByImg -or $IsNvaByTag)) { continue }

                    Write-PScriboMessage ($LocalizedData.Processing -f $AzVm.Name)

                    #region --- Resolve primary NIC ---
                    $PrimaryNicId     = ($AzVm.NetworkProfile.NetworkInterfaces | Where-Object { $_.Primary } | Select-Object -First 1).Id
                    if (-not $PrimaryNicId) {
                        $PrimaryNicId = $AzVm.NetworkProfile.NetworkInterfaces[0].Id
                    }
                    $PrimaryNicName   = $PrimaryNicId.Split('/')[-1]
                    $PrimaryNicRg     = $PrimaryNicId.Split('/')[4]
                    $PrimaryNic       = Get-AzNetworkInterface -Name $PrimaryNicName -ResourceGroupName $PrimaryNicRg -ErrorAction SilentlyContinue

                    $PrivateIp        = $PrimaryNic.IpConfigurations[0].PrivateIpAddress
                    $VNetSubnet       = if ($PrimaryNic.IpConfigurations[0].Subnet.Id) {
                        $Parts = $PrimaryNic.IpConfigurations[0].Subnet.Id.Split('/')
                        "$($Parts[$Parts.IndexOf('virtualNetworks') + 1]) / $($Parts[-1])"
                    } else { '--' }

                    $AllNicNames      = ($AzVm.NetworkProfile.NetworkInterfaces | ForEach-Object { $_.Id.Split('/')[-1] }) -join ', '
                    #endregion

                    #region --- Vendor display name ---
                    $VendorDisplay = switch ($ImageRef.Publisher.ToLower()) {
                        'paloaltonetworks'  { 'Palo Alto Networks' }
                        'fortinet'          { 'Fortinet' }
                        'cisco'             { 'Cisco' }
                        'checkpoint'        { 'Check Point' }
                        'f5-networks'       { 'F5 Networks' }
                        'barracudanetworks' { 'Barracuda Networks' }
                        'sonicwall-inc'     { 'SonicWall' }
                        'juniper-networks'  { 'Juniper Networks' }
                        'viptela'           { 'Cisco Viptela (SD-WAN)' }
                        'riverbed'          { 'Riverbed' }
                        default             { $ImageRef.Publisher }
                    }
                    if (-not $ImageRef.Publisher) { $VendorDisplay = $LocalizedData.TagIdentified }
                    #endregion

                    #region --- Associated UDR route tables (InfoLevel 3) ---
                    $AssociatedRouteTables = @()
                    if ($InfoLevel.NetworkVirtualAppliance -ge 3 -and $PrivateIp) {
                        $AllRouteTables = Get-AzRouteTable -ErrorAction SilentlyContinue
                        foreach ($Rt in $AllRouteTables) {
                            $MatchingRoutes = $Rt.Routes | Where-Object {
                                $_.NextHopType -eq 'VirtualAppliance' -and $_.NextHopIpAddress -eq $PrivateIp
                            }
                            if ($MatchingRoutes) {
                                foreach ($Route in $MatchingRoutes) {
                                    $AssociatedRouteTables += [PSCustomObject][Ordered]@{
                                        $LocalizedData.RouteTable      = $Rt.Name
                                        $LocalizedData.ResourceGroup   = $Rt.ResourceGroupName
                                        $LocalizedData.RouteName       = $Route.Name
                                        $LocalizedData.AddressPrefix   = $Route.AddressPrefix
                                    }
                                }
                            }
                        }
                    }
                    #endregion

                    $NvaVms += [PSCustomObject]@{
                        Name                  = $AzVm.Name
                        ResourceGroup         = $AzVm.ResourceGroupName
                        Location              = $AzLocationLookup."$($AzVm.Location)"
                        Subscription          = "$($AzSubscriptionLookup.(($AzVm.Id).split('/')[2]))"
                        SubscriptionID        = ($AzVm.Id).split('/')[2]
                        Vendor                = $VendorDisplay
                        Publisher             = if ($ImageRef.Publisher) { $ImageRef.Publisher } else { '--' }
                        Offer                 = if ($ImageRef.Offer)     { $ImageRef.Offer }     else { '--' }
                        Sku                   = if ($ImageRef.Sku)       { $ImageRef.Sku }       else { '--' }
                        ImageVersion          = if ($ImageRef.ExactVersion) { $ImageRef.ExactVersion } elseif ($ImageRef.Version) { $ImageRef.Version } else { '--' }
                        Status                = Switch ($AzVm.PowerState) {
                                                    'Vm deallocated' { $LocalizedData.Deallocated }
                                                    'Vm running'     { $LocalizedData.Running }
                                                    default          { $AzVm.PowerState }
                                                }
                        Size                  = $AzVm.HardwareProfile.VmSize
                        PrivateIPAddress      = if ($PrivateIp) { $PrivateIp } else { '--' }
                        VirtualNetworkSubnet  = $VNetSubnet
                        NetworkInterfaces     = $AllNicNames
                        Tags                  = if ($AzVm.Tags -and $AzVm.Tags.Count -gt 0) {
                                                    ($AzVm.Tags.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" }) -join [System.Environment]::NewLine
                                                } else { $LocalizedData.None }
                        AssociatedRouteTables = $AssociatedRouteTables
                        DetectedBy            = if ($IsNvaByImg -and $IsNvaByTag) { $LocalizedData.DetectedBoth }
                                                elseif ($IsNvaByImg) { $LocalizedData.DetectedByPublisher }
                                                else { $LocalizedData.DetectedByTag }
                    }
                }
                #endregion

                if ($NvaVms) {
                    Section -Style Heading4 $LocalizedData.Heading {
                        if ($Options.ShowSectionInfo) {
                            Paragraph $LocalizedData.SectionInfo
                            BlankLine
                        }

                        if ($InfoLevel.NetworkVirtualAppliance -ge 2) {
                            #region --- InfoLevel 2+: per-NVA detail ---
                            Paragraph ($LocalizedData.ParagraphDetail -f $AzSubscription.Name)
                            BlankLine

                            foreach ($Nva in $NvaVms) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $Nva.Name {
                                    $InObj = [Ordered]@{
                                        $LocalizedData.Name                 = $Nva.Name
                                        $LocalizedData.ResourceGroup        = $Nva.ResourceGroup
                                        $LocalizedData.Location             = $Nva.Location
                                        $LocalizedData.Subscription         = $Nva.Subscription
                                        $LocalizedData.SubscriptionID       = $Nva.SubscriptionID
                                        $LocalizedData.Vendor               = $Nva.Vendor
                                        $LocalizedData.Publisher            = $Nva.Publisher
                                        $LocalizedData.Offer                = $Nva.Offer
                                        $LocalizedData.Sku                  = $Nva.Sku
                                        $LocalizedData.ImageVersion         = $Nva.ImageVersion
                                        $LocalizedData.Status               = $Nva.Status
                                        $LocalizedData.Size                 = $Nva.Size
                                        $LocalizedData.PrivateIPAddress     = $Nva.PrivateIPAddress
                                        $LocalizedData.VirtualNetworkSubnet = $Nva.VirtualNetworkSubnet
                                        $LocalizedData.NetworkInterfaces    = $Nva.NetworkInterfaces
                                        $LocalizedData.DetectedBy           = $Nva.DetectedBy
                                        $LocalizedData.Tags                 = $Nva.Tags
                                    }
                                    $TableParams = @{
                                        Name         = "$($LocalizedData.TableHeading) - $($Nva.Name)"
                                        List         = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    [PSCustomObject]$InObj | Table @TableParams

                                    #region --- HealthCheck: NVA deallocated ---
                                    if ($HealthCheck.NetworkVirtualAppliance.Status) {
                                        if ($Nva.Status -eq $LocalizedData.Deallocated) {
                                            [PSCustomObject]$InObj | Set-Style -Style Critical -Property $LocalizedData.Status
                                        }
                                    }
                                    #endregion

                                    #region --- InfoLevel 3: associated UDR route tables ---
                                    if ($InfoLevel.NetworkVirtualAppliance -ge 3) {
                                        if ($Nva.AssociatedRouteTables -and $Nva.AssociatedRouteTables.Count -gt 0) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AssociatedRoutes {
                                                $RouteTableParams = @{
                                                    Name         = "$($LocalizedData.AssociatedRoutes) - $($Nva.Name)"
                                                    List         = $false
                                                    ColumnWidths = 25, 25, 25, 25
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $RouteTableParams['Caption'] = "- $($RouteTableParams.Name)"
                                                }
                                                $Nva.AssociatedRouteTables | Table @RouteTableParams
                                            }
                                        } else {
                                            Paragraph $LocalizedData.NoAssociatedRoutes
                                        }
                                    }
                                    #endregion
                                }
                            }
                            #endregion
                        } else {
                            #region --- InfoLevel 1: summary table ---
                            Paragraph ($LocalizedData.ParagraphSummary -f $AzSubscription.Name)
                            BlankLine

                            $NvaSummary = @()
                            foreach ($Nva in $NvaVms) {
                                $InObj = [Ordered]@{
                                    $LocalizedData.Name            = $Nva.Name
                                    $LocalizedData.ResourceGroup   = $Nva.ResourceGroup
                                    $LocalizedData.Location        = $Nva.Location
                                    $LocalizedData.Vendor          = $Nva.Vendor
                                    $LocalizedData.Offer           = $Nva.Offer
                                    $LocalizedData.Status          = $Nva.Status
                                    $LocalizedData.PrivateIPAddress = $Nva.PrivateIPAddress
                                }
                                $NvaSummary += [PSCustomObject]$InObj
                            }

                            $TableParams = @{
                                Name         = "$($LocalizedData.TableHeadings) - $($AzSubscription.Name)"
                                List         = $false
                                ColumnWidths = 20, 16, 14, 14, 14, 10, 12
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $NvaSummary | Table @TableParams

                            if ($HealthCheck.NetworkVirtualAppliance.Status) {
                                $NvaSummary | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Deallocated } |
                                    Set-Style -Style Critical -Property $LocalizedData.Status
                            }
                            #endregion
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