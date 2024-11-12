function Get-AbrAzTenant {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Tenant information
    .DESCRIPTION

    .NOTES
        Version:        0.1.2
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
        Write-PScriboMessage "Tenant InfoLevel set at $($InfoLevel.Tenant)."

    }

    process {
        Try {
            if ($InfoLevel.Tenant -gt 0) {
                Write-PscriboMessage "Collecting Azure Tenant information."
                $AzTenantInfo = [PSCustomObject]@{
                    'Tenant Name' = $AzTenant.Name
                    'Tenant ID' = $AzTenant.TenantId
                    'Tenant Type' = $AzTenant.TenantType
                    'Country ' = (Get-CountryName $AzTenant.CountryCode)
                    'Domains' = $AzTenant.Domains -join ', '
                    'Default Domain' = $AzTenant.DefaultDomain
                }

                $TableParams = @{
                    Name = "Tenant - $($AzTenant.Name)"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $AzTenantInfo | Table @TableParams
            }
        } Catch {
            Write-PScriboMessage -IsWarning $($_.Exception.Message)
        }
    }

    end {}
}