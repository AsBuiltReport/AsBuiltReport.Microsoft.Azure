function Invoke-AsBuiltReport.Microsoft.Azure {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft Azure in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft Azure in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.2.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         @tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .EXAMPLE
        PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -Credential $Credential -Format Html -OutputFolderPath 'C:\Reports'

        Generates an Azure report in HTML format for the specified tenant using credentials.

    .EXAMPLE
        PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -UseInteractiveAuth -Format Word -OutputFolderPath 'C:\Reports'

        Generates an Azure report in Word format for the specified tenant using interactive authentication (MFA).

    .EXAMPLE
        PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -UseInteractiveAuth -Format Html,Word -OutputFolderPath 'C:\Reports' -ReportConfigFilePath 'C:\Config\AsBuiltReport.Microsoft.Azure.json'

        Generates an Azure report in both HTML and Word formats using a custom configuration file.

    .EXAMPLE
        PS C:\> $Token = (Get-AzAccessToken).Token
        PS C:\> New-AsBuiltReport -Report Microsoft.Azure -Target 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' -Token $Token -TokenParameters @{AccountId='user@domain.com'} -Format Html -OutputFolderPath 'C:\Reports'

        Generates an Azure report using token-based authentication.

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>

    [CmdletBinding()]
    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential,
        [Switch] $UseInteractiveAuth,
        [String] $Token,
        [String] $AccountId  # Passed via TokenParameters hashtable from Core
    )

    # Check for required modules
    Get-RequiredModule -Name 'Az' -Version '15.3.0'

    # Display report module information using Core function
    Write-ReportModuleInfo -ModuleName 'Microsoft.Azure'

    # Import Report Configuration
    $Report = $ReportConfig.Report
    $Filter = $ReportConfig.Filter
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options
    $SectionOrder = $Options.SectionOrder
    $LocalizedData = $reportTranslate.InvokeAsBuiltReportMicrosoftAzure

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    # Define default section order if not specified in config
    $DefaultSectionOrder = @(
        "StorageAccount",
        "KeyVault",
        "LogAnalyticsWorkspace",
        "LoadBalancer",
        "ExpressRoute",
        "VirtualNetwork",
        "NetworkSecurityGroup",
        "PrivateEndpoint",
        "IpGroup",
        "DnsPrivateResolver",
        "Bastion",
        "Policy",
        "Firewall",
        "FirewallPolicy",
        "RouteTable",
        "VirtualMachine",
        "AvailabilitySet",
        "RecoveryServicesVault",
        "SiteRecovery",
        "DesktopVirtualization"
    )

    # Use custom section order if provided, otherwise use default
    if (-not $SectionOrder -or $SectionOrder.Count -eq 0) {
        Write-PScriboMessage -Plugin "Module" -Message $LocalizedData.DefaultOrder
        $SectionOrder = $DefaultSectionOrder
    } else {
        Write-PScriboMessage -Plugin "Module" -Message $LocalizedData.CustomOrder
    }

    # Function mapping for section names to function names
    $SectionFunctionMap = @{
        "AvailabilitySet" = "Get-AbrAzAvailabilitySet"
        "Bastion" = "Get-AbrAzBastion"
        "DnsPrivateResolver" = "Get-AbrAzDnsPrivateResolver"
        "ExpressRouteCircuit" = "Get-AbrAzExpressRouteCircuit"
        "ExpressRoute" = "Get-AbrAzExpressRouteCircuit"  # Alias for backward compatibility
        "Firewall" = "Get-AbrAzFirewall"
        "FirewallPolicy" = "Get-AbrAzFirewallPolicy"
        "IpGroup" = "Get-AbrAzIpGroup"
        "KeyVault" = "Get-AbrAzKeyVault"
        "LogAnalyticsWorkspace" = "Get-AbrAzLogAnalyticsWorkspace"
        "LoadBalancer" = "Get-AbrAzLoadBalancer"
        "VirtualNetwork" = "Get-AbrAzVirtualNetwork"
        "NetworkSecurityGroup" = "Get-AbrAzNetworkSecurityGroup"
        "Policy" = "Get-AbrAzPolicy"
        "RouteTable" = "Get-AbrAzRouteTable"
        "VirtualMachine" = "Get-AbrAzVirtualMachine"
        "RecoveryServicesVault" = "Get-AbrAzRecoveryServicesVault"
        "SiteRecovery" = "Get-AbrAsrProtectedItems"
        "StorageAccount" = "Get-AbrAzStorageAccount"
        "PrivateEndpoint" = "Get-AbrAzPrivateEndpoint"
        "DesktopVirtualization" = "Get-AbrAzDesktopVirtualization"
    }

    #region foreach loop
    foreach ($TenantId in $Target) {
        try {
            Write-PScriboMessage -Plugin "Module" -Message ($LocalizedData.Connecting -f $TenantId)
            if ($UseInteractiveAuth -or (-not $Token -and -not $Credential)) {
                # Use interactive auth if explicitly requested OR if no other auth method provided
                Clear-AzContext -Scope Process -Force -ErrorAction SilentlyContinue
                $AzAccount = Connect-AzAccount -TenantId $TenantId -ErrorAction Stop
            } elseif ($Token) {
                # Validate AccountId is provided via TokenParameters
                if (-not $AccountId) {
                    Write-Error ($LocalizedData.TokenAccountIdRequired -f 'New-AsBuiltReport', 'TokenParameters')
                    throw "Azure token authentication requires AccountId. Please use: -TokenParameters @{AccountId='user@domain.com'}"
                }

                Write-PScriboMessage -Plugin "Module" -Message ($LocalizedData.ConnectingWithToken -f $AccountId, $TenantId)
                $AzAccount = Connect-AzAccount -TenantId $TenantId -AccessToken $Token -AccountId $AccountId -ErrorAction Stop
            } else {
                Clear-AzContext -Scope Process -Force -ErrorAction SilentlyContinue
                $AzAccount = Connect-AzAccount -Credential $Credential -TenantId $TenantId -ErrorAction Stop
            }
        } catch {
            Write-Error $_
        }

        if ($AzAccount) {
            $AzTenant = Get-AzTenant -TenantId $TenantId
            $AzLocations = Get-AzLocation
            $AzLocationLookup = @{}
            foreach ($AzLocation in $AzLocations) {
                $AzLocationLookup.($AzLocation.Location) = $AzLocation.DisplayName
            }
            if ($AzTenant) {
                # Create a Lookup Hashtable for all Azure Subscriptions
                $AzSubscriptions = Get-AzSubscription -TenantId $TenantId | Sort-Object Name
                $AzSubscriptionLookup = @{}
                foreach ($AzSubscription in $AzSubscriptions) {
                    $AzSubscriptionLookup.($AzSubscription.SubscriptionId) = $AzSubscription.Name
                }

                # Filter Subscriptions
                if ($Filter.Subscription -ne "*") {
                    $AzSubscriptions = foreach ($AzSubscription in $Filter.Subscription) {
                        Get-AzSubscription -TenantId $TenantId -SubscriptionId $AzSubscription | Sort-Object Name
                    }
                }

                Section -Style Heading1 $($AzTenant.Name) {
                    Get-AbrAzTenant
                    Section -Style Heading2 $LocalizedData.Subscriptions {
                        Get-AbrAzSubscription

                        foreach ($AzSubscription in $AzSubscriptions) {
                            Section -Style Heading3 $($AzSubscription.Name) {
                                Write-PScriboMessage ($LocalizedData.SubscriptionID -f $($AzSubscription.Id))
                                $AzContext = Set-AzContext -Subscription $AzSubscription.Id -Tenant $TenantId

                                # Process sections in the order specified by SectionOrder
                                foreach ($SectionName in $SectionOrder) {
                                    try {
                                        # Get the info level for this section
                                        $level = if ($InfoLevel.PSObject.Properties.Name -contains $SectionName) {
                                            $InfoLevel.$SectionName
                                        } elseif ($InfoLevel.ContainsKey($SectionName)) {
                                            $InfoLevel[$SectionName]
                                        } else {
                                            Write-PScriboMessage ($LocalizedData.InfoLevelNotFound -f $SectionName)
                                            continue
                                        }

                                        # Determine if section is enabled and execute function
                                        $enabled = switch ($level) {
                                            { $_ -is [hashtable] -or $_ -is [PSCustomObject] } {
                                                # For complex objects, sum all property values
                                                $sum = if ($_ -is [hashtable]) {
                                                    ($_.Values | Measure-Object -Sum).Sum
                                                } else {
                                                    ($_.PSObject.Properties.Value | ForEach-Object { [int]$_ } | Measure-Object -Sum).Sum
                                                }
                                                $sum -gt 0
                                            }
                                            default {
                                                # For simple types (int, int64, string), convert to int and check if > 0
                                                try { [int]$_ -gt 0 } catch { $false }
                                            }
                                        }

                                        if ($enabled) {
                                            $functionName = $SectionFunctionMap[$SectionName]
                                            if ($functionName -and (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                                                & $functionName
                                            } else {
                                                Write-PScriboMessage ($LocalizedData.FunctionNotFound -f $functionName, $SectionName)
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage ($LocalizedData.ErrorProcessing -f $SectionName, $_)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                Write-PScriboMessage ($LocalizedData.TenantNotFound -f $TenantId)
            }
            Disconnect-AzAccount $AzAccount | Out-Null
        }
    }
    #endregion foreach loop
}