function Resolve-AbrAzPolicyScopeName {
    <#
    .SYNOPSIS
        Resolves an Azure Policy scope to a readable name.
    .DESCRIPTION
        Given a management group, subscription, resource group or resource scope, returns the
        subscription name for a subscription scope if it is known, otherwise the last segment
        of the scope, which is the name of the management group, resource group or resource.
    .PARAMETER Scope
        The scope to resolve.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE
        PS C:\> Resolve-AbrAzPolicyScopeName -Scope '/subscriptions/{sub}/resourceGroups/rg-app'
        Returns rg-app.
    .LINK

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Scope
    )

    $ScopeName = $Scope.TrimEnd('/').Split('/')[-1]
    if ($Scope -match '^/subscriptions/[^/]+/?$' -and $AzSubscriptionLookup[$ScopeName]) {
        return $AzSubscriptionLookup[$ScopeName]
    }
    return $ScopeName
}
