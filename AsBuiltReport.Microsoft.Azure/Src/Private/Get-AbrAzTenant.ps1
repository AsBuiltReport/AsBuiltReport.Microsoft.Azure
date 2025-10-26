function Get-AbrAzTenant {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Azure Tenant information
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
        $LocalizedData = $reportTranslate.GetAbrAzTenant
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Tenant)

    }

    process {
        Try {
            if ($InfoLevel.Tenant -gt 0) {
                Write-PscriboMessage $LocalizedData.Collecting
                $AzTenantInfo = [PSCustomObject]@{
                    $LocalizedData.TenantName = $AzTenant.Name
                    $LocalizedData.TenantID = $AzTenant.TenantId
                    $LocalizedData.TenantType = $AzTenant.TenantType
                    $LocalizedData.Country = (Get-CountryName $AzTenant.CountryCode)
                    $LocalizedData.Domains = $AzTenant.Domains -join ', '
                    $LocalizedData.DefaultDomain = $AzTenant.DefaultDomain
                }

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $($AzTenant.Name)"
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