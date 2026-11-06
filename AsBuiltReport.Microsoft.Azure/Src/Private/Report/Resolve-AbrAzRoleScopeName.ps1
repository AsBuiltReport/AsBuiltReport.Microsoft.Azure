function Resolve-AbrAzRoleScopeName {
    <#
    .SYNOPSIS
        Resolves an Azure role assignment scope to a readable name.
    .DESCRIPTION
        Given a root, management group, subscription, resource group or resource scope, returns
        the type of scope and its name, such as "Resource Group: rg-app". Labels are read from
        the caller's $LocalizedData.
    .PARAMETER Scope
        The scope to resolve.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:        @tpcarman
        Github:         tpcarman
    .EXAMPLE
        PS C:\> Resolve-AbrAzRoleScopeName -Scope '/subscriptions/{sub}/resourceGroups/rg-app'
        Returns Resource Group: rg-app.
    .LINK

    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Scope
    )

    if ($Scope -match '^/+$') {
        return $LocalizedData.RootScope
    }
    $ScopeType = switch -Regex ($Scope) {
        '^/providers/Microsoft\.Management/managementGroups/[^/]+/?$' { $LocalizedData.ManagementGroup }
        '^/subscriptions/[^/]+/?$' { $LocalizedData.Subscription }
        '^/subscriptions/[^/]+/resourceGroups/[^/]+/?$' { $LocalizedData.ResourceGroup }
        default { $LocalizedData.Resource }
    }
    return '{0}: {1}' -f $ScopeType, (Resolve-AbrAzPolicyScopeName -Scope $Scope)
}
