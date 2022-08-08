function Get-AbrAzTenant {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Azure Tenant information
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
        Write-PscriboMessage "Collecting Azure Tenant information."
    }

    process {
        $AzTenantInfo = [PSCustomObject]@{
            'Tenant Name' = $AzTenant.Name
            'Tenant ID' = $AzTenant.TenantId
            'Domains' = $AzTenant.Domains
        }

        $TableParams = @{
            Name = "Tenant - $($AzTenant.Name)"
            List = $true
            ColumnWidths = 50, 50
        }
        if ($Report.ShowTableCaptions) {
            $TableParams['Caption'] = "- $($TableParams.Name)"
        }
        $AzTenantInfo | Table @TableParams
    }

    end {}
}