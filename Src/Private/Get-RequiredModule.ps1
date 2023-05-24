function Get-RequiredModule {
    <#
    .SYNOPSIS
    Function to check if the required version of the Microsoft Azure PowerShell module is installed
    .DESCRIPTION
    Function to check if the required version of the Microsoft Azure PowerShell module is installed
    .PARAMETER Name
    The name of the required PowerShell module
    .PARAMETER Version
    The version of the required PowerShell module
    #>
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Version
    )

    # Check if the required version of the Azure PowerShell module is installed (check only works for PowerShell Core / 7.x)
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $RequiredModule = Get-Module -ListAvailable -Name $Name | Sort-Object -Property Version -Descending | Select-Object -First 1
        $ModuleVersion = "$($RequiredModule.Version.Major)" + "." + "$($RequiredModule.Version.Minor)"
        if ($ModuleVersion -eq ".")  {
            throw "Microsoft Azure PowerShell $Version or higher is required to run the Microsoft Azure As Built Report. Run 'Install-Module -Name $Name -MinimumVersion $Version' to install the required modules."
        }
        if ([Version]$ModuleVersion -lt [Version]$Version) {
            throw "Microsoft Azure PowerShell $ModuleVersion is currently installed. Microsoft Azure PowerShell $Version or higher is required to run the Microsoft Azure As Built Report. Please run 'Update-Module -Name $Name -MinimumVersion $Version -Force' to update to the required version."
        }
    }
}