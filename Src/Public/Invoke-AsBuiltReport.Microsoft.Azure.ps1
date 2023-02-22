function Invoke-AsBuiltReport.Microsoft.Azure {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Microsoft Azure in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Microsoft Azure in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.2
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
            $AzLocationLookup = @{ }
            foreach ($AzLocation in $AzLocations) {
                $AzLocationLookup.($AzLocation.Location) = $AzLocation.DisplayName
            }
            if ($AzTenant) {
                if ($Filter.Subscription -eq "*") {
                    $AzSubscriptions = Get-AzSubscription -TenantId $TenantId | Sort-Object Name
                } else {
                    $AzSubscriptions = foreach ($AzSubscription in $Filter.Subscription) {
                        Get-AzSubscription -TenantId $TenantId -SubscriptionId $AzSubscription
                    }
                }
                $AzSubscriptionLookup = @{ }
                foreach ($AzSubscription in ($AzSubscriptions | Sort-Object Name)) {
                    $AzSubscriptionLookup.($AzSubscription.SubscriptionId) = $AzSubscription.Name
                }
                Section -Style Heading1 $($AzTenant.Name) {
                    Get-AbrAzTenant
                    Section -Style Heading2 'Subscriptions' {
                        Get-AbrAzSubscription
                        foreach ($AzSubscription in ($AzSubscriptions | Sort-Object Name)) {
                            Section -Style Heading3 $($AzSubscription.Name) {
                                Write-PScriboMessage "Setting Azure context to Subscription ID '$AzSubscription.Id'."
                                $AzContext = Set-AzContext -Subscription $AzSubscription.Id -Tenant $TenantId
                                Get-AbrAzPolicyAssignment
                                Get-AbrAzAvailabilitySet
                                Get-AbrAzBastion
                                Get-AbrAzExpressRouteCircuit
                                Get-AbrAzFirewall
                                Get-AbrAzIpGroup
                                Get-AbrAzKeyVault
                                Get-AbrAzLoadBalancer
                                Get-AbrAzVirtualNetwork
                                Get-AbrAzNetworkSecurityGroup
                                Get-AbrAzVirtualMachine
                                Get-AbrAzRecoveryServicesVault
                                Get-AbrAsrProtectedItems
                            }
                        }
                    }
                }
            } else {
                Write-PScriboMessage "Azure Tenant $TenantId not found."
            }
            Disconnect-AzAccount $AzAccount
        }
	}
	#endregion foreach loop
}