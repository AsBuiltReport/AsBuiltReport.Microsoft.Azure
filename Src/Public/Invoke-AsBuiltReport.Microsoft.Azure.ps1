function Invoke-AsBuiltReport.Microsoft.Azure {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft Azure in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft Azure in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.7
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         @tpcarman
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure
    #>

	# Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential,
        [Switch] $MFA
    )

    Get-RequiredModule -Name 'Az' -Version '12.0.0'

    Write-PScriboMessage -Plugin "Module" -Message "Please refer to the AsBuiltReport.Microsoft.Azure GitHub website for more detailed information about this project."
    Write-PScriboMessage -Plugin "Module" -Message "Do not forget to update your report configuration file after each new version release: https://www.asbuiltreport.com/user-guide/new-asbuiltreportconfig/"
    Write-PScriboMessage -Plugin "Module" -Message "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure"
    Write-PScriboMessage -Plugin "Module" -Message "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Microsoft.Azure/issues"

    # Check the current AsBuiltReport.Microsoft.Azure module
    $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Microsoft.Azure -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

    if ($InstalledVersion) {
        Write-PScriboMessage -Plugin "Module" -Message "AsBuiltReport.Microsoft.Azure $($InstalledVersion.ToString()) is currently installed."
        $LatestVersion = Find-Module -Name AsBuiltReport.Microsoft.Azure -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
        if ([Version]$LatestVersion -gt [Version]$InstalledVersion) {
            Write-PScriboMessage -Plugin "Module" -Message "AsBuiltReport.Microsoft.Azure $($LatestVersion.ToString()) is available."
            Write-PScriboMessage -Plugin "Module" -Message "Run 'Update-Module -Name AsBuiltReport.Microsoft.Azure -Force' to install the latest version."
        }
    }

    # Import Report Configuration
    $Report = $ReportConfig.Report
    $Filter = $ReportConfig.Filter
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($TenantId in $Target) {
        Try {
            Write-PScriboMessage "Connecting to Azure Tenant ID '$TenantId'."
            if ($MFA) {
                $AzAccount = Connect-AzAccount -TenantId $TenantId -ErrorAction Stop
            } else {
                $AzAccount = Connect-AzAccount -Credential $Credential -TenantId $TenantId -ErrorAction Stop
            }
        } Catch {
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
                    Section -Style Heading2 'Subscriptions' {
                        Get-AbrAzSubscription
                        foreach ($AzSubscription in $AzSubscriptions) {
                            Section -Style Heading3 $($AzSubscription.Name) {
                                Write-PScriboMessage "Setting Azure context to Subscription ID '$AzSubscription.Id'."
                                $AzContext = Set-AzContext -Subscription $AzSubscription.Id -Tenant $TenantId
                                Get-AbrAzAvailabilitySet
                                Get-AbrAzBastion
                                Get-AbrAzDnsPrivateResolver
                                Get-AbrAzExpressRouteCircuit
                                Get-AbrAzFirewall
                                Get-AbrAzIpGroup
                                Get-AbrAzKeyVault
                                Get-AbrAzLoadBalancer
                                Get-AbrAzVirtualNetwork
                                Get-AbrAzNetworkSecurityGroup
                                Get-AbrAzPolicy
                                Get-AbrAzRouteTable
                                Get-AbrAzVirtualMachine
                                Get-AbrAzRecoveryServicesVault
                                Get-AbrAsrProtectedItems
                                Get-AbrAzStorageAccount
                            }
                        }
                    }
                }
            } else {
                Write-PScriboMessage "Azure Tenant $TenantId not found."
            }
            Disconnect-AzAccount $AzAccount | Out-null
        }
	}
	#endregion foreach loop
}